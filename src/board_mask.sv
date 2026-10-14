module board_mask (
    input logic [8:0] x_bitboard,
    input logic [8:0] o_bitboard,
    output logic [8:0] occupied,
    output logic [8:0] legal_moves,
    output logic invalid
);
    assign occupied = x_bitboard | o_bitboard; // All occupied locations
    assign legal_moves = ~occupied; // All possible move locations
    assign invalid = |(x_bitboard & o_bitboard); // Catches invalid board conditions
endmodule