module game_terminal_check (
    input  logic [8:0] x_bitboard,
    input  logic [8:0] o_bitboard,
    output logic x_wins,
    output logic o_wins,
    output logic is_draw,
    output logic is_terminal // 1 = if game is terminal
);
    logic [8:0] occupied;

    win_check x_win_inst (.board(x_bitboard), .win(x_wins));
    win_check o_win_inst (.board(o_bitboard), .win(o_wins));
    mask mask_inst (.x_bitboard(x_bitboard), .o_bitboard(o_bitboard), .occupied(occupied), .legal_moves(), .invalid());

    assign is_draw = (~(x_wins | o_wins) && (occupied == 9'b111111111)); // Checks for remaining moves
    assign is_terminal = x_wins | o_wins | is_draw;

endmodule