module win_check (
    input logic [8:0] board,
    output logic win // 1 = Winning board state
);

    // Winning board masks
    localparam logic [8:0] R1 = 9'b111000000;
    localparam logic [8:0] R2 = 9'b000111000;
    localparam logic [8:0] R3 = 9'b000000111;

    localparam logic [8:0] C1 = 9'b100100100;
    localparam logic [8:0] C2 = 9'b010010010;
    localparam logic [8:0] C3 = 9'b001001001;

    localparam logic [8:0] D1 = 9'b100010001;
    localparam logic [8:0] D2 = 9'b001010100;

    assign win = 
        ((board & R1) == R1) ||
        ((board & R2) == R2) ||
        ((board & R3) == R3) ||
        ((board & C1) == C1) ||
        ((board & C2) == C2) ||
        ((board & C3) == C3) ||
        ((board & D1) == D1) ||
        ((board & D2) == D2);
endmodule