module mem_wb (
    input clk,
    input rst,

    input stall,
    input flush,

    input [31:0] read_data_in,
    input [31:0] alu_result_in,
    input [31:0] pc_plus4_in,
    input [4:0] rd_in,

    input RegWrite_in,
    input MemToReg_in,
    input Jump_in,


    output reg [31:0] read_data_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] pc_plus4_out,
    output reg [4:0] rd_out,

    output reg RegWrite_out,
    output reg MemToReg_out,
    output reg Jump_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data_out   <= 32'b0;
            alu_result_out  <= 32'b0;
            pc_plus4_out    <= 32'b0;
            rd_out          <= 5'b0;

            RegWrite_out    <= 1'b0;
            MemToReg_out    <= 1'b0;
            Jump_out        <= 1'b0;
        end

        else if (flush) begin
            read_data_out   <= 32'b0;
            alu_result_out  <= 32'b0;
            pc_plus4_out    <= 32'b0;
            rd_out          <= 5'b0;

            RegWrite_out    <= 1'b0;
            MemToReg_out    <= 1'b0;
            Jump_out        <= 1'b0;
        end

        else if (!stall) begin
            read_data_out   <= read_data_in;
            alu_result_out  <= alu_result_in;
            pc_plus4_out    <= pc_plus4_in;
            rd_out          <= rd_in;

            RegWrite_out    <= RegWrite_in;
            MemToReg_out    <= MemToReg_in;
            Jump_out        <= Jump_in;
        end
    end

endmodule