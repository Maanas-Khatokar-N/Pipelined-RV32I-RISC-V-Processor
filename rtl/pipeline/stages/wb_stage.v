module wb_stage (
    input [31:0] alu_result,
    input [31:0] mem_read_data,
    input [31:0] pc_plus4,

    input MemToReg,
    input Jump,

    output [31:0] wb_write_data
);

    wire [31:0] write_data;

    mux2_32 mem_to_reg_mux (
        .a(alu_result),
        .b(mem_read_data),
        .sel(MemToReg),
        .y(write_data)
    );

    mux2_32 jal_write_mux (
        .a(write_data),
        .b(pc_plus4),
        .sel(Jump),
        .y(wb_write_data)
    );

endmodule