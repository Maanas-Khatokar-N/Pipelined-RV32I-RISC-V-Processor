module ex_stage (
    input [31:0] pc,
    input [31:0] read_data1, read_data2,
    input [31:0] imm,

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

    wire [31:0] alu_src_b;
    wire [3:0] ALUControl;
    wire zero;

    alu_control ac (
        .ALUop(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl)
    );

    mux2_32 alu_src_mux (
        .a(read_data2),
        .b(imm),
        .sel(ALUSrc),
        .y(alu_src_b)
    );

    alu a1 (
        .A(read_data1),
        .B(alu_src_b),
        .ALUControl(ALUControl),
        .result(alu_result),
        .zero(zero)
    );

    adder branch_jump_adder (
        .a(pc),
        .b(imm),
        .sum(pc_target)
    );

    assign write_data = read_data2;

    assign branch_taken =
        Branch && (
            (funct3 == 3'b000 && zero)  ||   // BEQ
            (funct3 == 3'b001 && !zero)      // BNE
        );

    assign pc_src = Jump || branch_taken;
    
endmodule