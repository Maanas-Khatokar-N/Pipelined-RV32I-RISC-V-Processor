module if_id (
    input clk,
    input rst,

    input stall,
    input flush,

    input [31:0] pc_in,
    input [31:0] pc_plus4_in,
    input [31:0] inst_in,

    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] inst_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out       <= 32'b0;
            pc_plus4_out <= 32'b0;
            inst_out     <= 32'h00000013;   // NOP: addi x0, x0, 0
        end

        else if (flush) begin
            pc_out       <= 32'b0;
            pc_plus4_out <= 32'b0;
            inst_out     <= 32'h00000013;   // remove wrong instruction
        end

        else if (!stall) begin
            pc_out       <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            inst_out     <= inst_in;
        end
    end

endmodule