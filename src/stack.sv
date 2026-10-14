import tictactoe_pkg::*;

module stack #(
    parameter int MAX_DEPTH = 10 // 9 squares total, therefore 9 layers to search
)(
    input  logic clk,
    input  logic rst,

    // Controls
    input  logic push,
    input  logic pop,
    input  logic update,    
    
    // Data
    input  node_frame_t  push_data,
    input  node_frame_t  update_data, 

    output node_frame_t  top_data,
    output logic [3:0] stack_pointer, 
    output logic full,
    output logic empty
);

    node_frame_t stack_mem [0:MAX_DEPTH-1];

    assign empty = (stack_pointer == 4'd0);
    assign full  = (stack_pointer == MAX_DEPTH);
    assign top_data = (empty) ? '0 : stack_mem[stack_pointer - 1];

    always_ff @(posedge clk) begin
        if (rst) begin
            stack_pointer <= '0;

        end else begin
            if (push && !pop && !update && !full) begin
                stack_mem[stack_pointer] <= push_data;
                stack_pointer <= stack_pointer + 1;
            end 
            else if (pop && !push && !update && !empty) begin
                stack_pointer <= stack_pointer - 1;
            end 
            else if (update && !push && !pop && !empty) begin
                stack_mem[stack_pointer - 1] <= update_data;
            end
        end
    end
endmodule