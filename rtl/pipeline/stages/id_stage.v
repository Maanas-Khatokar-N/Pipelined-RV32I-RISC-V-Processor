module id_stage (
    input clk, rst,

    input [31:0] inst,

    input wb_RegWrite,
    input [4:0] wb_rd,
    input [31:0] wb_write_data,

    output [31:0] read_data1, read_data2,
    output [31:0] imm,

    output [4:0] rs1, rs2, rd,
    output [2:0] funct3,
    output [6:0] funct7,

    output RegWrite, ALUSrc, MemRead, MemWrite, MemToReg,
    output Branch, Jump,
    output [1:0] ALUOp
);

    wire [6:0] opcode;

    //For Bypass
    wire [31:0] rf_read_data1;
    wire [31:0] rf_read_data2;

    assign opcode = inst[6:0];
    assign rd     = inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1    = inst[19:15];
    assign rs2    = inst[24:20];
    assign funct7 = inst[31:25];

    control_unit cu (
        .opcode(opcode),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemToReg(MemToReg),
        .Branch(Branch),
        .Jump(Jump),
        .ALUOp(ALUOp)
    );

    register_file rf (
        .clk(clk),
        .rst(rst),

        .rs1(rs1),
        .rs2(rs2),
        .rd(wb_rd),
        .write_data(wb_write_data),

        .write_en(wb_RegWrite),

        .read_data1(rf_read_data1),
        .read_data2(rf_read_data2)
    );


    // WB-to-ID bypass
    assign read_data1 =
        (rs1 == 5'd0) ? 32'b0 :
        (wb_RegWrite && (wb_rd != 5'd0) && (wb_rd == rs1)) ? wb_write_data :
        rf_read_data1;

    assign read_data2 =
        (rs2 == 5'd0) ? 32'b0 :
        (wb_RegWrite && (wb_rd != 5'd0) && (wb_rd == rs2)) ? wb_write_data :
        rf_read_data2;

    imm_gen get_imm (
        .inst(inst),
        .imm_out(imm)
    );

endmodule