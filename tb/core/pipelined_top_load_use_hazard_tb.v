`timescale 1ns/1ps

module pipelined_top_load_use_hazard_tb;

    reg clk;
    reg rst;
    integer i;

    `define IMEM dut.IF.inst_mem.memory
    `define REGS dut.ID.rf.registers
    `define DMEM dut.MEM.dm.memory

    pipelined_top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    // -----------------------------
    // Instruction encoding functions
    // -----------------------------

    function [31:0] R_TYPE;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            R_TYPE = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] I_TYPE;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            I_TYPE = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] S_TYPE;
        input [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            S_TYPE = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
        end
    endfunction

    // -----------------------------
    // Opcodes / funct values
    // -----------------------------

    localparam [6:0] OPCODE_R     = 7'b0110011;
    localparam [6:0] OPCODE_I     = 7'b0010011;
    localparam [6:0] OPCODE_LOAD  = 7'b0000011;
    localparam [6:0] OPCODE_STORE = 7'b0100011;

    localparam [2:0] F3_ADD_SUB = 3'b000;
    localparam [2:0] F3_LW_SW   = 3'b010;

    localparam [6:0] F7_ADD = 7'b0000000;

    // -----------------------------
    // Short instruction helpers
    // -----------------------------

    function [31:0] ADD;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            ADD = R_TYPE(F7_ADD, rs2, rs1, F3_ADD_SUB, rd, OPCODE_R);
        end
    endfunction

    function [31:0] ADDI;
        input [4:0] rd;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            ADDI = I_TYPE(imm, rs1, F3_ADD_SUB, rd, OPCODE_I);
        end
    endfunction

    function [31:0] LW;
        input [4:0] rd;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            LW = I_TYPE(imm, rs1, F3_LW_SW, rd, OPCODE_LOAD);
        end
    endfunction

    function [31:0] SW;
        input [4:0] rs2;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            SW = S_TYPE(imm, rs2, rs1, F3_LW_SW, OPCODE_STORE);
        end
    endfunction

    initial begin
        clk = 0;
        rst = 1;

        // Clear instruction memory
        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013; // nop = addi x0, x0, 0
        end

        // Clear data memory
        for (i = 0; i < 256; i = i + 1) begin
            `DMEM[i] = 32'd0;
        end

        // ------------------------------------------------
        // Program:
        //
        // x1 = 100
        // x2 = 7
        // Mem[100] = 7
        //
        // lw  x5, 0(x1)
        // add x6, x5, x2     // load-use hazard
        //
        // lw   x8, 0(x1)
        // sw   x8, 4(x1)     // load-use hazard for store data
        //
        // lw  x9, 4(x1)
        // add x10, x9, x8    // load-use hazard again
        // ------------------------------------------------

        `IMEM[0]  = ADDI(5'd1, 5'd0, 12'd100);  // x1 = 100
        `IMEM[1]  = ADDI(5'd2, 5'd0, 12'd7);    // x2 = 7
        `IMEM[2]  = SW  (5'd2, 5'd1, 12'd0);    // Mem[100] = x2 = 7

        `IMEM[3]  = LW  (5'd5, 5'd1, 12'd0);    // x5 = Mem[100] = 7
        `IMEM[4]  = ADD (5'd6, 5'd5, 5'd2);     // x6 = x5 + x2 = 14

        `IMEM[5]  = LW  (5'd8, 5'd1, 12'd0);    // x8 = Mem[100] = 7
        `IMEM[6]  = SW  (5'd8, 5'd1, 12'd4);    // Mem[104] = x8 = 7

        `IMEM[7]  = LW  (5'd9, 5'd1, 12'd4);    // x9 = Mem[104] = 7
        `IMEM[8]  = ADD (5'd10, 5'd9, 5'd8);    // x10 = x9 + x8 = 14

        `IMEM[9]  = ADDI(5'd11, 5'd10, 12'd1);  // x11 = 15, checks later forwarding

        #12;
        rst = 0;

        // Run enough cycles
        #300;

        $display("============ LOAD-USE HAZARD TEST ============");
        $display("x1  = %0d   Expected = 100", `REGS[1]);
        $display("x2  = %0d   Expected = 7",   `REGS[2]);
        $display("x5  = %0d   Expected = 7",   `REGS[5]);
        $display("x6  = %0d   Expected = 14",  `REGS[6]);
        $display("x8  = %0d   Expected = 7",   `REGS[8]);
        $display("x9  = %0d   Expected = 7",   `REGS[9]);
        $display("x10 = %0d   Expected = 14",  `REGS[10]);
        $display("x11 = %0d   Expected = 15",  `REGS[11]);

        // If your data memory uses addr[31:2], address 100 is memory[25], 104 is memory[26].
        $display("Mem[25]  = %0d   Expected = 7   // address 100 if word-indexed", `DMEM[25]);
        $display("Mem[26]  = %0d   Expected = 7   // address 104 if word-indexed", `DMEM[26]);

        // If your data memory directly uses addr, uncomment these instead:
        // $display("Mem[100] = %0d   Expected = 7", `DMEM[100]);
        // $display("Mem[104] = %0d   Expected = 7", `DMEM[104]);

        if (`REGS[5]  == 32'd7  &&
            `REGS[6]  == 32'd14 &&
            `REGS[8]  == 32'd7  &&
            `REGS[9]  == 32'd7  &&
            `REGS[10] == 32'd14 &&
            `REGS[11] == 32'd15 &&
            `DMEM[25] == 32'd7  &&
            `DMEM[26] == 32'd7) begin

            $display("PASS: Load-use hazard handling is working.");
        end
        else begin
            $display("FAIL: Load-use hazard handling is NOT working.");
        end

        $display("==============================================");
        $finish;
    end

    initial begin
        $dumpfile("sim/waveforms/load_use_hazard_tb.vcd");
        $dumpvars(0, pipelined_top_load_use_hazard_tb);
    end

endmodule