import tictactoe_pkg::*;

module tictactoe_control (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [8:0] x_bitboard,  
    input  logic [8:0] o_bitboard,  
    input  logic       max,

    output logic       done,
    output logic       busy,
    output logic [3:0] best_move_index,
    output logic signed [1:0] best_score
);

    typedef enum logic [3:0] {
      IDLE, WAIT_ROOT, EXPAND, CHECK_TERM, WAIT_TERM,
      PUSH_CHILD, WAIT_PUSH, SCORE_LEAF, 
      BACKPROP, WAIT_POP, UPDATE_PARENT, DONE
    } state_t;

    state_t state;

    logic [8:0] live_move_bit;
    logic [3:0] live_move_index;
    logic       live_move_valid;

    logic [8:0] first_root_move_bit;
    logic [3:0] first_root_move_index;
    
    logic [8:0] first_child_move_bit;
    logic [3:0] first_child_move_index;

    // Latched registers
    logic [8:0] latched_move_bit;
    logic [3:0] latched_move_index;

    logic x_wins, o_wins, is_draw, is_terminal;

    logic       stack_push;
    logic       stack_pop;
    logic       stack_update;
    node_frame_t stack_push_data;
    node_frame_t stack_update_data;
    node_frame_t topData;
    logic [3:0] stack_pointer;
    logic       stack_full;
    logic       stack_empty;

    node_frame_t popped_frame; 
    logic signed [1:0] leaf_score;

    logic [8:0] root_legal_moves;
    logic [8:0] child_legal_moves;
    logic [8:0] next_x_bitboard;
    logic [8:0] next_o_bitboard;

    assign busy = (state != IDLE) && (state != DONE);
    assign done = (state == DONE);
    assign best_move_index = popped_frame.bestmove_index;
    assign best_score      = popped_frame.best_score;
  
    localparam logic signed [1:0] SCORE_POS1 = 2'sb01; //  +1
    localparam logic signed [1:0] SCORE_ZERO = 2'sb00; //   0
    localparam logic signed [1:0] SCORE_NEG1 = 2'sb11; //  -1

    logic [8:0] latched_next_x_bitboard;
    logic [8:0] latched_next_o_bitboard;

    always_comb begin
        if (topData.player_to_move) begin
            next_x_bitboard = topData.x_bitboard | latched_move_bit;
            next_o_bitboard = topData.o_bitboard;
        end else begin
            next_x_bitboard = topData.x_bitboard;
            next_o_bitboard = topData.o_bitboard | latched_move_bit;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state             <= IDLE;
            stack_push        <= '0;
            stack_pop         <= '0;
            stack_update      <= '0;
            popped_frame      <= '0;
            leaf_score        <= '0;
            latched_move_bit   <= '0;
            latched_move_index <= '0;
            stack_push_data    <= '0;
            stack_update_data  <= '0;
        end else begin
            stack_push   <= '0;
            stack_pop    <= '0;
            stack_update <= '0;

            case (state)
                IDLE: begin
                    if (start) begin
                        stack_push_data.x_bitboard       <= x_bitboard;
                        stack_push_data.o_bitboard       <= o_bitboard;
                        stack_push_data.player_to_move    <= max; 
                        stack_push_data.remaining_moves  <= root_legal_moves;
                        // Max starts with worst score -1; Min starts with worst score +1
                        stack_push_data.best_score       <= max ? SCORE_NEG1 : SCORE_POS1; 
                        stack_push_data.bestmove_index   <= first_root_move_index;  
                        stack_push_data.parent_move_index <= 4'd15;                 
                        
                        stack_push                     <= '1;
                        state                          <= WAIT_ROOT;
                    end
                end

                WAIT_ROOT: begin
                    state <= EXPAND; 
                end

                EXPAND: begin
                    if (topData.remaining_moves != 0) begin
                        latched_move_bit   <= live_move_bit;
                        latched_move_index <= live_move_index;
                        state             <= CHECK_TERM;
                    end else begin
                        state <= BACKPROP; 
                    end
                end

                CHECK_TERM: begin
                    latched_next_x_bitboard <= next_x_bitboard;
                    latched_next_o_bitboard <= next_o_bitboard;
                    state                  <= WAIT_TERM;
                end

                WAIT_TERM: begin
                    if (is_terminal) begin
                        if (x_wins)       leaf_score <= SCORE_POS1;  // +1
                        else if (o_wins)  leaf_score <= SCORE_NEG1;  // -1
                        else             leaf_score <= SCORE_ZERO;  //  0
                        state <= SCORE_LEAF;
                    end else begin
                        stack_update_data                <= topData;
                        stack_update_data.remaining_moves <= topData.remaining_moves & ~latched_move_bit;
                        stack_update                    <= '1;
                        state                            <= PUSH_CHILD;
                    end
                end

                PUSH_CHILD: begin
                    stack_push_data.x_bitboard       <= latched_next_x_bitboard;
                    stack_push_data.o_bitboard       <= latched_next_o_bitboard;
                    stack_push_data.player_to_move    <= ~topData.player_to_move; 
                    stack_push_data.remaining_moves  <= child_legal_moves;
                    // Child player initialization
                    stack_push_data.best_score       <= (~topData.player_to_move) ? SCORE_NEG1 : SCORE_POS1; 
                    stack_push_data.bestmove_index   <= first_child_move_index; 
                    stack_push_data.parent_move_index <= latched_move_index;     
                    
                    stack_push                     <= '1;
                    state                          <= WAIT_PUSH; 
                end

                WAIT_PUSH: begin
                    state <= EXPAND; 
                end

                SCORE_LEAF: begin
                    stack_update_data                <= topData;
                    stack_update_data.remaining_moves <= topData.remaining_moves & ~latched_move_bit;

                    if (topData.player_to_move) begin // max maximizing
                        if ($signed(leaf_score) > $signed(topData.best_score)) begin
                            stack_update_data.best_score     <= leaf_score;
                            stack_update_data.bestmove_index <= latched_move_index;
                        end
                    end else begin                  // max minimizing
                        if ($signed(leaf_score) < $signed(topData.best_score)) begin
                            stack_update_data.best_score     <= leaf_score;
                            stack_update_data.bestmove_index <= latched_move_index;
                        end
                    end
                    stack_update <= '1;
                    state        <= EXPAND; 
                end

                BACKPROP: begin
                    popped_frame <= topData; 
                    stack_pop    <= '1;
                    
                    if (stack_pointer == 4'd1) begin
                        state <= DONE; 
                    end else begin
                        state <= WAIT_POP;
                    end
                end

                WAIT_POP: begin
                    state <= UPDATE_PARENT; 
                end

                UPDATE_PARENT: begin
                    stack_update_data <= topData;
                    stack_update     <= '1;

                    if (topData.player_to_move) begin // Parent is max maximizing
                        if ($signed(popped_frame.best_score) > $signed(topData.best_score)) begin
                            stack_update_data.best_score     <= popped_frame.best_score;
                            stack_update_data.bestmove_index <= popped_frame.parent_move_index; 
                        end
                    end else begin                  // Parent is min minimizing
                        if ($signed(popped_frame.best_score) < $signed(topData.best_score)) begin
                            stack_update_data.best_score     <= popped_frame.best_score;
                            stack_update_data.bestmove_index <= popped_frame.parent_move_index;
                        end
                    end
                    
                    state <= EXPAND; 
                end

                DONE: begin
                    // Done
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    board_mask root_mask_inst ( 
        .x_bitboard(x_bitboard), .o_bitboard(o_bitboard),
        .occupied(), .legal_moves(root_legal_moves), .invalid()
    );  

    board_mask child_mask_inst ( 
        .x_bitboard(latched_next_x_bitboard), .o_bitboard(latched_next_o_bitboard),
        .occupied(), .legal_moves(child_legal_moves), .invalid()
    );  

    move_extractor main_move_extractor (
        .remaining_moves(topData.remaining_moves),
        .move_bit(live_move_bit), .move_index(live_move_index), .valid(live_move_valid)
    );

    move_extractor root_seeder (
        .remaining_moves(root_legal_moves),
        .move_bit(first_root_move_bit), .move_index(first_root_move_index), .valid()
    );

    move_extractor child_seeder (
        .remaining_moves(child_legal_moves),
        .move_bit(first_child_move_bit), .move_index(first_child_move_index), .valid()
    );

    game_terminal_check terminal_state_inst (
        .x_bitboard(latched_next_x_bitboard), .o_bitboard(latched_next_o_bitboard),
        .x_wins(x_wins), .o_wins(o_wins), .is_draw(is_draw), .is_terminal(is_terminal)
    );

    stack search_stack_inst (
        .clk(clk), .rst(rst),
        .push(stack_push), .pop(stack_pop), .update(stack_update),
        .push_data(stack_push_data), .update_data(stack_update_data),
        .top_data(topData), .stack_pointer(stack_pointer),
        .full(stack_full), .empty(stack_empty)
    );

endmodule
