package tictactoe_pkg;
    typedef struct packed {
        logic [8:0] x_bitboard; // X bitboard boardstate
        logic [8:0] o_bitboard; // O bitboard boardstate
        logic player_to_move; // Moving player
        logic [8:0] remaining_moves; // Remaining possible player moves
        logic signed [1:0] best_score; // Best move score
        logic [3:0] best_move_index; // Index of best move
        logic [3:0] parent_move_index; //Index of parent move
    } node_frame_t;
endpackage