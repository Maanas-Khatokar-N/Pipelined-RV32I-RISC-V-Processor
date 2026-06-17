module ex_mem (
    input clk,
    input rst,

    input stall,

    input [31:0] alu_result_in,
    input [31:0] write_data_in,
    input [31:0] branch_target_in,
    input branch_taken_in,

    input [31:0] pc_plus4_in,
    input [4:0] rd_in,

    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,
    input MemToReg_in,
    input Branch_in,
    input Jump_in,


    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [31:0] branch_target_out,
    output reg branch_taken_out,

    output reg [31:0] pc_plus4_out,
    output reg [4:0] rd_out,

    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg MemToReg_out,
    output reg Branch_out,
    output reg Jump_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_out    <= 32'b0;
            write_data_out    <= 32'b0;
            branch_target_out <= 32'b0;
            branch_taken_out  <= 1'b0;
            pc_plus4_out      <= 32'b0;
            rd_out            <= 5'b0;

            RegWrite_out <= 1'b0;
            MemRead_out  <= 1'b0;
            MemWrite_out <= 1'b0;
            MemToReg_out <= 1'b0;
            Branch_out   <= 1'b0;
            Jump_out     <= 1'b0;
        end

        else if (!stall) begin
            alu_result_out    <= alu_result_in;
            write_data_out    <= write_data_in;
            branch_target_out <= branch_target_in;
            branch_taken_out  <= branch_taken_in;
            pc_plus4_out      <= pc_plus4_in;
            rd_out            <= rd_in;

            RegWrite_out <= RegWrite_in;
            MemRead_out  <= MemRead_in;
            MemWrite_out <= MemWrite_in;
            MemToReg_out <= MemToReg_in;
            Branch_out   <= Branch_in;
            Jump_out     <= Jump_in;
        end
    end

endmodule