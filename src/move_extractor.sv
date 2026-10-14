module move_extractor (
    input  logic [8:0] remaining_moves,
    output logic [8:0] move_bit, // One-hot move
    output logic [3:0] move_index,
    output logic valid 
);
    logic [8:0] lsb_bit;
    assign lsb_bit = remaining_moves & (~remaining_moves + 1'b1);


    always_comb begin
        move_bit = lsb_bit;
        valid = |remaining_moves;

        case (lsb_bit)
                9'b000000001: move_index = 4'd0;
                9'b000000010: move_index = 4'd1;
                9'b000000100: move_index = 4'd2;
                9'b000001000: move_index = 4'd3;
                9'b000010000: move_index = 4'd4;
                9'b000100000: move_index = 4'd5;
                9'b001000000: move_index = 4'd6;
                9'b010000000: move_index = 4'd7;
                9'b100000000: move_index = 4'd8;
                default:      move_index = 4'd0;
        endcase
    end
endmodule