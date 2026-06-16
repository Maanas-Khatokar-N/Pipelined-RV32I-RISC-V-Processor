module pipelined_top (
    input clk, rst
);

    // Common Wires

    wire [31:0] pc;
    wire [31:0] pc_plus4;
    wire [31:0] pc_target;
    wire [31:0] pc_next;

    wire [31:0] inst;

    wire [6:0] id_opcode;
    wire [4:0] id_rd, id_rs1, id_rs2;
    wire [2:0] id_funct3;
    wire [6:0] id_funct7;

    wire [31:0] imm;
    wire [31:0] id_imm;

    wire id_RegWrite, id_ALUSrc, id_MemRead, id_MemWrite, id_MemToReg;
    wire id_Branch, id_Jump;

    wire [1:0] id_ALUOp;
    wire [3:0] ex_ALUControl;

    wire [31:0] id_read_data1, id_read_data2;
    wire [31:0] ex_alu_src_b;
    wire [31:0] ex_alu_result;
    wire ex_zero;

    wire ex_branch_taken;

    wire [31:0] mem_rd_data;

    wire [31:0] normal_write_data;
    wire [31:0] final_write_data;


    // ============================================================
    // IF Stage: Instruction Fetch
    // ============================================================

    adder pc_adder (
        .a(pc),
        .b(32'd4),
        .sum(pc_plus4)
    );

    mux2_32 pc_next_mux (
        .a(pc_plus4),
        .b(pc_target),
        .sel(Jump || branch_taken),
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

    // IF/ID wires
    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc_plus4;
    wire [31:0] if_id_inst;

    wire stall;
    wire flush;

    assign stall = 1'b0;   // for now
    assign flush = Jump || branch_taken;

    if_id if_id_latch (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),

        .pc_in(pc),
        .pc_plus4_in(pc_plus4),
        .inst_in(inst),

        .pc_out(if_id_pc),
        .pc_plus4_out(if_id_pc_plus4),
        .inst_out(if_id_inst)
    );

    // ============================================================
    // ID Stage: Instruction Decode / Register Fetch
    // ============================================================

    assign id_opcode = if_id_inst[6:0];
    assign id_rd     = if_id_inst[11:7];
    assign id_funct3 = if_id_inst[14:12];
    assign id_rs1    = if_id_inst[19:15];
    assign id_rs2    = if_id_inst[24:20];
    assign id_funct7 = if_id_inst[31:25];

    control_unit cu (
        .opcode(id_opcode),
        .RegWrite(id_RegWrite),
        .ALUSrc(id_ALUSrc),
        .MemRead(id_MemRead),
        .MemWrite(id_MemWrite),
        .MemToReg(id_MemToReg),
        .Branch(id_Branch),
        .Jump(id_Jump),
        .ALUOp(id_ALUOp)
    );


    // These will come from WB stage
    wire wb_RegWrite;
    wire [4:0] wb_rd;
    wire [31:0] wb_write_data;

    register_file rf (
        .clk(clk),
        .rst(rst),

        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(wb_rd),

        .write_data(wb_write_data),
        .write_en(wb_RegWrite),

        .read_data1(id_read_data1),
        .read_data2(id_read_data2)
    );

    imm_gen ig (
        .inst(if_id_inst),
        .imm_out(id_imm)
    );



    // ID/EX wires
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_pc_plus4;
    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;
    wire [31:0] id_ex_imm;

    wire [4:0] id_ex_rs1, id_ex_rs2, id_ex_rd;
    wire [2:0] id_ex_funct3;
    wire [6:0] id_ex_funct7;

    wire id_ex_RegWrite, id_ex_ALUSrc, id_ex_MemRead, id_ex_MemWrite, id_ex_MemToReg;
    wire id_ex_Branch, id_ex_Jump;
    wire [1:0] id_ex_ALUOp;


    id_ex id_ex_latch (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),

        .pc_in(if_id_pc),
        .pc_plus4_in(if_id_pc_plus4),
        .read_data1_in(id_read_data1),
        .read_data2_in(id_read_data2),
        .imm_in(id_imm),

        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),

        .funct3_in(id_funct3),
        .funct7_in(id_funct7),

        .RegWrite_in(id_RegWrite),
        .ALUSrc_in(id_ALUSrc),
        .MemRead_in(id_MemRead),
        .MemWrite_in(id_MemWrite),
        .MemToReg_in(id_MemToReg),
        .Branch_in(id_Branch),
        .Jump_in(id_Jump),
        .ALUOp_in(id_ALUOp),

        .pc_out(id_ex_pc),
        .pc_plus4_out(id_ex_pc_plus4),
        .read_data1_out(id_ex_read_data1),
        .read_data2_out(id_ex_read_data2),
        .imm_out(id_ex_imm),

        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd),

        .funct3_out(id_ex_funct3),
        .funct7_out(id_ex_funct7),

        .RegWrite_out(id_ex_RegWrite),
        .ALUSrc_out(id_ex_ALUSrc),
        .MemRead_out(id_ex_MemRead),
        .MemWrite_out(id_ex_MemWrite),
        .MemToReg_out(id_ex_MemToReg),
        .Branch_out(id_ex_Branch),
        .Jump_out(id_ex_Jump),
        .ALUOp_out(id_ex_ALUOp)
    );


    // ============================================================
    // EX Stage: Execute / Address Calculation
    // ============================================================

    alu_control ac (
        .ALUOp(id_ex_ALUOp),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        .ALUControl(ex_ALUControl)
    );

    mux2_32 alu_src_mux (
        .a(id_ex_read_data2),
        .b(id_ex_imm),
        .sel(id_ex_ALUSrc),
        .y(ex_alu_src_b)
    );

    alu alu_unit (
        .A(id_ex_read_data1),
        .B(ex_alu_src_b),
        .ALUControl(ex_ALUControl),
        .result(ex_alu_result),
        .zero(ex_zero)
    );

    adder branch_adder (
        .a(id_ex_pc),
        .b(id_ex_imm),
        .sum(ex_pc_target)
    );

    assign ex_branch_taken = id_ex_Branch && ((id_ex_funct3 == 3'b000 && ex_zero) || (id_ex_funct3 == 3'b001 && !ex_zero));


    // EX/MEM Pipeline Register
    wire [31:0] ex_mem_pc_target;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_write_data;
    wire [4:0] ex_mem_rd;

    wire ex_mem_zero;
    wire ex_mem_branch_taken;

    wire ex_mem_RegWrite, ex_mem_MemRead, ex_mem_MemWrite, ex_mem_MemToReg;
    wire ex_mem_Branch, ex_mem_Jump;

    ex_mem ex_mem_latch (
        .clk(clk),
        .rst(rst),

        .pc_target_in(ex_pc_target),
        .zero_in(ex_zero),
        .branch_taken_in(ex_branch_taken),
        .alu_result_in(ex_alu_result),
        .write_data_in(id_ex_read_data2),
        .rd_in(id_ex_rd),

        .RegWrite_in(id_ex_RegWrite),
        .MemRead_in(id_ex_MemRead),
        .MemWrite_in(id_ex_MemWrite),
        .MemToReg_in(id_ex_MemToReg),
        .Branch_in(id_ex_Branch),
        .Jump_in(id_ex_Jump),

        .pc_target_out(ex_mem_pc_target),
        .zero_out(ex_mem_zero),
        .branch_taken_out(ex_mem_branch_taken),
        .alu_result_out(ex_mem_alu_result),
        .write_data_out(ex_mem_write_data),
        .rd_out(ex_mem_rd),

        .RegWrite_out(ex_mem_RegWrite),
        .MemRead_out(ex_mem_MemRead),
        .MemWrite_out(ex_mem_MemWrite),
        .MemToReg_out(ex_mem_MemToReg),
        .Branch_out(ex_mem_Branch),
        .Jump_out(ex_mem_Jump)
    );


    // ============================================================
    // MEM Stage: Data Memory Access
    // ============================================================

    data_memory dm (
        .clk(clk),
        .MemRead(ex_mem_MemRead),
        .MemWrite(ex_mem_MemWrite),
        .addr(ex_mem_alu_result),
        .write_data(ex_mem_write_data),
        .read_data(mem_rd_data)
    );

    // MEM/WB Pipeline Register
    wire [31:0] mem_wb_read_data;
    wire [31:0] mem_wb_alu_result;
    wire [4:0] mem_wb_rd;

    wire mem_wb_RegWrite;
    wire mem_wb_MemToReg;

    mem_wb mem_wb_latch (
        .clk(clk),
        .rst(rst),

        .read_data_in(mem_rd_data),
        .alu_result_in(ex_mem_alu_result),
        .rd_in(ex_mem_rd),

        .RegWrite_in(ex_mem_RegWrite),
        .MemToReg_in(ex_mem_MemToReg),

        .read_data_out(mem_wb_read_data),
        .alu_result_out(mem_wb_alu_result),
        .rd_out(mem_wb_rd),

        .RegWrite_out(mem_wb_RegWrite),
        .MemToReg_out(mem_wb_MemToReg)
    );


    // ============================================================
    // WB Stage: Write Back
    // ============================================================

    mux2_32 mem_to_reg_mux (
        .a(mem_wb_alu_result),
        .b(mem_wb_read_data),
        .sel(mem_wb_MemToReg),
        .y(normal_write_data)
    );

    mux2_32 jal_write_mux (
        .a(normal_write_data),
        .b(pc_plus4),
        .sel(Jump),
        .y(final_write_data)
    );

endmodule