module mem_stage (
    input clk,
    input MemRead,
    input MemWrite,
    input [31:0] alu_result,
    input [31:0] write_data,

    output [31:0] mem_read_data
);

    data_memory dm (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(alu_result),
        .write_data(write_data),
        .read_data(mem_read_data)
    );

endmodule