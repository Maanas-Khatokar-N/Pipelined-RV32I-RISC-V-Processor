module top (
    input clk, rst
);

    //Instruction Fetch (IF)

    wire [31:0] pc;
    wire [31:0] pc_next;

    wire [31:0] inst;

    
    adder pc_adder (.a(pc), .b(32'd4), .sum(pc_next));
    program_counter pc_reg (.clk(clk), .rst(rst), .pc_next(pc_next), .pc(pc));

    instruction_memory inst_mem (.pc(pc), .inst(inst));



    //Instruction Decode (ID)

    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] imm;

    assign opcode = inst[6:0];
    assign rd     = inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1    = inst[19:15];
    assign rs2    = inst[24:20];
    assign funct7 = inst[31:25];

    imm_gen get_imm (.inst(inst), .imm_out(imm));

    
    wire RegWrite, ALUSrc, MemRead, MemWrite, MemToReg, Branch, Jump;
    wire [1:0] ALUOp;

    control_unit cu (.opcode(opcode), .RegWrite(RegWrite), .ALUSrc(ALUSrc), .MemRead(MemRead), .MemWrite(MemWrite), .MemToReg(MemToReg), .Branch(Branch), .Jump(Jump), .ALUOp(ALUOp));


    wire [31:0] write_data;
    wire [31:0] read_data1, read_data2;

    register_file rf (.clk(clk), .rst(rst), .rs1(rs1), .rs2(rs2), .rd(rd), .write_data(write_data), .write_en(RegWrite), .read_data1(read_data1), .read_data2(read_data2));


    wire [3:0] ALUControl;

    alu_control ac (.ALUOp(ALUOp), .funct3(funct3), .funct7(funct7), .ALUControl(ALUControl));



    //Execution (EX)

    wire [31:0] out_data;
    mux2_32 alu_sel (.a(read_data2), .b(imm), .sel(ALUSrc), .y(out_data));

    wire [31:0] alu_result;
    wire zero;
    alu a1 (.A(read_data1), .B(out_data), .ALUControl(ALUControl), .result(alu_result), .zero(zero));


endmodule