module pipelined_top (
    input clk, rst
);

    wire stall;
    wire if_id_flush;
    wire id_ex_flush;

    // IF stage wires
    wire pc_src;
    wire [31:0] pc_target;

    wire [31:0] pc;
    wire [31:0] pc_plus4;
    wire [31:0] inst;

    // IF/ID pipeline register output wires
    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc_plus4;
    wire [31:0] if_id_inst;

    // ID stage wires
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] imm;

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;

    wire [2:0] funct3;
    wire [6:0] funct7;

    wire RegWrite;
    wire ALUSrc;
    wire MemRead;
    wire MemWrite;
    wire MemToReg;
    wire Branch;
    wire Jump;
    wire [1:0] ALUOp;


    // ID/EX pipeline register output wires
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_pc_plus4;
    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;
    wire [31:0] id_ex_imm;

    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;
    wire [4:0] id_ex_rd;

    wire [2:0] id_ex_funct3;
    wire [6:0] id_ex_funct7;

    wire id_ex_RegWrite;
    wire id_ex_ALUSrc;
    wire id_ex_MemRead;
    wire id_ex_MemWrite;
    wire id_ex_MemToReg;
    wire id_ex_Branch;
    wire id_ex_Jump;
    wire [1:0] id_ex_ALUOp;


    // EX stage output wires
    wire [31:0] alu_result;
    wire [31:0] write_data;
    wire branch_taken;


    // EX/MEM pipeline register output wires
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_write_data;
    wire [31:0] ex_mem_pc_target;
    wire ex_mem_branch_taken;

    wire [31:0] ex_mem_pc_plus4;
    wire [4:0] ex_mem_rd;

    wire ex_mem_RegWrite;
    wire ex_mem_MemRead;
    wire ex_mem_MemWrite;
    wire ex_mem_MemToReg;
    wire ex_mem_Branch;
    wire ex_mem_Jump;


    // MEM stage output wire
    wire [31:0] mem_rd_data;


    // MEM/WB pipeline register output wires
    wire [31:0] mem_wb_mem_rd_data;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_pc_plus4;
    wire [4:0] mem_wb_rd;

    wire mem_wb_RegWrite;
    wire mem_wb_MemToReg;
    wire mem_wb_Jump;


    // WB stage output wire
    wire [31:0] wb_write_data;


    //Forwarding wires
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;

    //Load-use hazard unit wires
    wire load_use_stall;
    wire load_use_flush;


    assign stall = load_use_stall & ~pc_src;
    assign if_id_flush = pc_src;
    assign id_ex_flush = pc_src | load_use_flush;
    
    if_stage IF (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_src(pc_src),
        .pc_target(pc_target),

        .pc(pc),
        .pc_plus4(pc_plus4),
        .inst(inst)
    );

    if_id IF_ID (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(if_id_flush),

        .pc_in(pc),
        .pc_plus4_in(pc_plus4),
        .inst_in(inst),


        .pc_out(if_id_pc),
        .pc_plus4_out(if_id_pc_plus4),
        .inst_out(if_id_inst)
    );

    id_stage ID (
        .clk(clk),
        .rst(rst),
        
        .inst(if_id_inst),

        .wb_RegWrite(mem_wb_RegWrite),
        .wb_rd(mem_wb_rd),
        .wb_write_data(wb_write_data),

        .read_data1(read_data1),
        .read_data2(read_data2),
        .imm(imm),


        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .funct7(funct7),

        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemToReg(MemToReg),
        .Branch(Branch),
        .Jump(Jump),
        .ALUOp(ALUOp)
    );

    id_ex ID_EX (
        .clk(clk),
        .rst(rst),
        .stall(1'b0),
        .flush(id_ex_flush),

        .pc_in(if_id_pc),
        .pc_plus4_in(if_id_pc_plus4),
        .read_data1_in(read_data1),
        .read_data2_in(read_data2),
        .imm_in(imm),

        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),

        .funct3_in(funct3),
        .funct7_in(funct7),

        .RegWrite_in(RegWrite),
        .ALUSrc_in(ALUSrc),
        .MemRead_in(MemRead),
        .MemWrite_in(MemWrite),
        .MemToReg_in(MemToReg),
        .Branch_in(Branch),
        .Jump_in(Jump),
        .ALUOp_in(ALUOp),


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

    ex_stage EX (
        .pc(id_ex_pc),
        .read_data1(id_ex_read_data1),
        .read_data2(id_ex_read_data2),
        .imm(id_ex_imm),

        .ex_mem_forward_data(ex_mem_alu_result),
        .mem_wb_forward_data(wb_write_data),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),

        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),

        .ALUSrc(id_ex_ALUSrc),
        .Branch(id_ex_Branch),
        .Jump(id_ex_Jump),
        .ALUOp(id_ex_ALUOp),

        .alu_result(alu_result),
        .write_data(write_data),
        .pc_target(pc_target),
        .branch_taken(branch_taken),
        .pc_src(pc_src)
    );

    ex_mem EX_MEM (
        .clk(clk),
        .rst(rst),
        .stall(1'b0),

        .alu_result_in(alu_result),
        .write_data_in(write_data),
        .branch_target_in(pc_target),
        .branch_taken_in(branch_taken),

        .pc_plus4_in(id_ex_pc_plus4),
        .rd_in(id_ex_rd),

        .RegWrite_in(id_ex_RegWrite),
        .MemRead_in(id_ex_MemRead),
        .MemWrite_in(id_ex_MemWrite),
        .MemToReg_in(id_ex_MemToReg),
        .Branch_in(id_ex_Branch),
        .Jump_in(id_ex_Jump),


        .alu_result_out(ex_mem_alu_result),
        .write_data_out(ex_mem_write_data),
        .branch_target_out(ex_mem_pc_target),
        .branch_taken_out(ex_mem_branch_taken),

        .pc_plus4_out(ex_mem_pc_plus4),
        .rd_out(ex_mem_rd),

        .RegWrite_out(ex_mem_RegWrite),
        .MemRead_out(ex_mem_MemRead),
        .MemWrite_out(ex_mem_MemWrite),
        .MemToReg_out(ex_mem_MemToReg),
        .Branch_out(ex_mem_Branch),
        .Jump_out(ex_mem_Jump)
    );

    mem_stage MEM (
        .clk(clk),
        .MemRead(ex_mem_MemRead),
        .MemWrite(ex_mem_MemWrite),
        .alu_result(ex_mem_alu_result),
        .write_data(ex_mem_write_data),

        .mem_read_data(mem_rd_data)
    );

    mem_wb MEM_WB (
        .clk(clk),
        .rst(rst),
        .stall(1'b0),

        .read_data_in(mem_rd_data),
        .alu_result_in(ex_mem_alu_result),
        .pc_plus4_in(ex_mem_pc_plus4),
        .rd_in(ex_mem_rd),

        .RegWrite_in(ex_mem_RegWrite),
        .MemToReg_in(ex_mem_MemToReg),
        .Jump_in(ex_mem_Jump),


        .read_data_out(mem_wb_mem_rd_data),
        .alu_result_out(mem_wb_alu_result),
        .pc_plus4_out(mem_wb_pc_plus4),
        .rd_out(mem_wb_rd),

        .RegWrite_out(mem_wb_RegWrite),
        .MemToReg_out(mem_wb_MemToReg),
        .Jump_out(mem_wb_Jump)
    );

    wb_stage WB (
        .alu_result(mem_wb_alu_result),
        .mem_read_data(mem_wb_mem_rd_data),
        .pc_plus4(mem_wb_pc_plus4),

        .MemToReg(mem_wb_MemToReg),
        .Jump(mem_wb_Jump),

        .wb_write_data(wb_write_data)
    );


    //Forwarding Unit
    forwarding_unit fu (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),

        .ex_mem_rd(ex_mem_rd),
        .ex_mem_RegWrite(ex_mem_RegWrite),

        .mem_wb_rd(mem_wb_rd),
        .mem_wb_RegWrite(mem_wb_RegWrite),

        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );

    //Load-use Hazard Unit
    load_use_hazard_unit lhu (
        .id_ex_MemRead(id_ex_MemRead),
        .id_ex_rd(id_ex_rd),

        .if_id_rs1(rs1),
        .if_id_rs2(rs2),

        .stall(load_use_stall),
        .id_ex_flush(load_use_flush)
    ); 

endmodule