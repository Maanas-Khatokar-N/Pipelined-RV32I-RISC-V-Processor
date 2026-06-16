module if_stage (
    input clk, rst,
    input stall,
    input pc_src,
    input [31:0] pc_target,

    output [31:0] pc,
    output [31:0] pc_plus4,
    output [31:0] inst
);

    wire [31:0] pc_next;
    wire [31:0] pc_normal_next;

    adder pc_adder (
        .a(pc),
        .b(32'd4),
        .sum(pc_plus4)
    );

    mux2_32 pc_next_mux (
        .a(pc_plus4),
        .b(pc_target),
        .sel(pc_src),
        .y(pc_normal_next)
    );

    mux2_32 pc_next_stall (
        .a(pc_normal_next),
        .b(pc),
        .sel(stall),
        .y(pc_next)
    );

    program_counter pc_reg (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc(pc)
    );

    instruction_memory inst_mem (
        .pc(pc),
        .inst(inst)
    );

endmodule