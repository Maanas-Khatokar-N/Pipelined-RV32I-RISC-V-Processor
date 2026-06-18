module ex_stage (
    input [31:0] pc,
    input [31:0] read_data1,
    input [31:0] read_data2,
    input [31:0] imm,

    input [31:0] ex_mem_forward_data,
    input [31:0] mem_wb_forward_data,

    input [1:0] ForwardA,
    input [1:0] ForwardB,

    input [2:0] funct3,
    input [6:0] funct7,

    input ALUSrc,
    input Branch,
    input Jump,
    input [1:0] ALUOp,

    output [31:0] alu_result,
    output [31:0] write_data,
    output [31:0] pc_target,
    output branch_taken,
    output pc_src
);

    wire [31:0] alu_operand_a;
    wire [31:0] forwarded_b;
    wire [31:0] alu_operand_b;

    wire [3:0] ALUControl;
    wire zero;

    alu_control ac (
        .ALUop(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl)
    );

    // Forwarding for ALU input A
    mux3_32 forward_a_mux (
        .a(read_data1),
        .b(ex_mem_forward_data),
        .c(mem_wb_forward_data),
        .sel(ForwardA),
        .y(alu_operand_a)
    );

    // Forwarding for rs2 value
    mux3_32 forward_b_mux (
        .a(read_data2),
        .b(ex_mem_forward_data),
        .c(mem_wb_forward_data),
        .sel(ForwardB),
        .y(forwarded_b)
    );

    // ALU B input selection
    mux2_32 alu_src_mux (
        .a(forwarded_b),
        .b(imm),
        .sel(ALUSrc),
        .y(alu_operand_b)
    );

    alu a1 (
        .A(alu_operand_a),
        .B(alu_operand_b),
        .ALUControl(ALUControl),
        .result(alu_result),
        .zero(zero)
    );

    adder branch_adder (
        .a(pc),
        .b(imm),
        .sum(pc_target)
    );

    assign write_data = forwarded_b;

    assign branch_taken = Branch && (
        ((funct3 == 3'b000) && zero) ||      // beq
        ((funct3 == 3'b001) && !zero)        // bne
    );

    assign pc_src = branch_taken || Jump;

endmodule