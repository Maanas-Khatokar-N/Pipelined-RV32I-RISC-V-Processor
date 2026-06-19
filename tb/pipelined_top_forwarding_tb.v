`timescale 1ns/1ps

module pipelined_top_forwarding_tb;

    reg clk;
    reg rst;

    integer i;

    `define IMEM dut.IF.inst_mem.memory
    `define DMEM dut.MEM.dm.memory
    `define REGS dut.ID.rf.registers

    pipelined_top dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // RISC-V instruction encoding helper functions
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // Opcodes
    // ------------------------------------------------------------

    localparam OPCODE_RTYPE  = 7'b0110011;
    localparam OPCODE_ITYPE  = 7'b0010011;
    localparam OPCODE_STORE  = 7'b0100011;

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        rst = 1'b1;

        // Clear instruction memory and data memory
        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013;   // NOP = addi x0, x0, 0
            `DMEM[i] = 32'd0;
        end

        // --------------------------------------------------------
        // Program to test forwarding
        // --------------------------------------------------------

        /*
            x1 = 10
            x2 = 20
        */
        `IMEM[0]  = I_TYPE(12'd10, 5'd0, 3'b000, 5'd1, OPCODE_ITYPE);   // addi x1, x0, 10
        `IMEM[1]  = I_TYPE(12'd20, 5'd0, 3'b000, 5'd2, OPCODE_ITYPE);   // addi x2, x0, 20

        /*
            Test 1: ALU-to-ALU forwarding

            add x3, x1, x2      x3 = 30
            sub x4, x3, x1      x4 = 20

            sub needs x3 immediately.
            This tests EX/MEM -> EX forwarding for rs1.
        */
        `IMEM[2]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, OPCODE_RTYPE); // add x3, x1, x2
        `IMEM[3]  = R_TYPE(7'b0100000, 5'd1, 5'd3, 3'b000, 5'd4, OPCODE_RTYPE); // sub x4, x3, x1

        /*
            Test 2: Forwarding through another dependent chain

            and x5, x4, x2      x5 = 20
            or  x6, x5, x1      x6 = 30

            and needs x4 immediately.
            or needs x5 immediately.
        */
        `IMEM[4]  = R_TYPE(7'b0000000, 5'd2, 5'd4, 3'b111, 5'd5, OPCODE_RTYPE); // and x5, x4, x2
        `IMEM[5]  = R_TYPE(7'b0000000, 5'd1, 5'd5, 3'b110, 5'd6, OPCODE_RTYPE); // or x6, x5, x1

        /*
            Test 3: EX/MEM -> EX forwarding for rs2

            add x7, x1, x2      x7 = 30
            sub x8, x2, x7      x8 = 20 - 30 = -10

            Here x7 is used as rs2.
        */
        `IMEM[6]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd7, OPCODE_RTYPE); // add x7, x1, x2
        `IMEM[7]  = R_TYPE(7'b0100000, 5'd7, 5'd2, 3'b000, 5'd8, OPCODE_RTYPE); // sub x8, x2, x7

        /*
            Test 4: MEM/WB -> EX forwarding

            add  x9,  x1, x2     x9  = 30
            addi x31, x0, 123    independent instruction
            sub  x10, x9, x1     x10 = 20

            Because one independent instruction is between add and sub,
            x9 should be forwarded from MEM/WB.
        */
        `IMEM[8]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd9, OPCODE_RTYPE);  // add x9, x1, x2
        `IMEM[9]  = I_TYPE(12'd123, 5'd0, 3'b000, 5'd31, OPCODE_ITYPE);          // addi x31, x0, 123
        `IMEM[10] = R_TYPE(7'b0100000, 5'd1, 5'd9, 3'b000, 5'd10, OPCODE_RTYPE); // sub x10, x9, x1

        /*
            Test 5: Priority test

            addi x11, x0, 1      x11 = 1
            addi x11, x11, 2     x11 = 3
            addi x11, x11, 4     x11 = 7

            When the third instruction is in EX,
            both EX/MEM and MEM/WB may refer to x11.
            Forwarding must choose EX/MEM because it is newer.
        */
        `IMEM[11] = I_TYPE(12'd1, 5'd0, 3'b000, 5'd11, OPCODE_ITYPE);  // addi x11, x0, 1
        `IMEM[12] = I_TYPE(12'd2, 5'd11, 3'b000, 5'd11, OPCODE_ITYPE); // addi x11, x11, 2
        `IMEM[13] = I_TYPE(12'd4, 5'd11, 3'b000, 5'd11, OPCODE_ITYPE); // addi x11, x11, 4

        /*
            Test 6: Store-data forwarding

            addi x12, x0, 77     x12 = 77
            addi x13, x0, 100    x13 = 100
            add  x14, x12, x0    x14 = 77
            sw   x14, 0(x13)     Mem[100] = 77

            sw needs x14 as store data.
            Store data comes through rs2, so ForwardB should fix it.
        */
        `IMEM[14] = I_TYPE(12'd77, 5'd0, 3'b000, 5'd12, OPCODE_ITYPE);             // addi x12, x0, 77
        `IMEM[15] = I_TYPE(12'd100, 5'd0, 3'b000, 5'd13, OPCODE_ITYPE);            // addi x13, x0, 100
        `IMEM[16] = R_TYPE(7'b0000000, 5'd0, 5'd12, 3'b000, 5'd14, OPCODE_RTYPE); // add x14, x12, x0
        `IMEM[17] = S_TYPE(12'd0, 5'd14, 5'd13, 3'b010, OPCODE_STORE);             // sw x14, 0(x13)

        // NOPs to allow pipeline to drain
        `IMEM[18] = 32'h00000013;
        `IMEM[19] = 32'h00000013;
        `IMEM[20] = 32'h00000013;
        `IMEM[21] = 32'h00000013;
        `IMEM[22] = 32'h00000013;

        // Release reset
        #12;
        rst = 1'b0;

        // Run enough cycles
        #350;

        // --------------------------------------------------------
        // Display results
        // --------------------------------------------------------

        $display("\n================ FORWARDING TEST RESULTS ================");

        $display("x1  = %0d   Expected = 10",  `REGS[1]);
        $display("x2  = %0d   Expected = 20",  `REGS[2]);
        $display("x3  = %0d   Expected = 30",  `REGS[3]);
        $display("x4  = %0d   Expected = 20",  `REGS[4]);
        $display("x5  = %0d   Expected = 20",  `REGS[5]);
        $display("x6  = %0d   Expected = 30",  `REGS[6]);

        $display("x7  = %0d   Expected = 30",  `REGS[7]);
        $display("x8  = %0d   Expected = -10 / 4294967286 unsigned", `REGS[8]);

        $display("x9  = %0d   Expected = 30",  `REGS[9]);
        $display("x10 = %0d   Expected = 20",  `REGS[10]);

        $display("x11 = %0d   Expected = 7",   `REGS[11]);

        $display("x12 = %0d   Expected = 77",  `REGS[12]);
        $display("x13 = %0d   Expected = 100", `REGS[13]);
        $display("x14 = %0d   Expected = 77",  `REGS[14]);

        $display("Mem[100] = %0d Expected = 77", `DMEM[100 >> 2]);

        $display("==========================================================\n");

        // --------------------------------------------------------
        // Self-checks
        // --------------------------------------------------------

        if (`REGS[1]  !== 32'd10)       $display("FAIL: x1 wrong");
        else if (`REGS[2]  !== 32'd20)  $display("FAIL: x2 wrong");
        else if (`REGS[3]  !== 32'd30)  $display("FAIL: x3 wrong");
        else if (`REGS[4]  !== 32'd20)  $display("FAIL: x4 wrong");
        else if (`REGS[5]  !== 32'd20)  $display("FAIL: x5 wrong");
        else if (`REGS[6]  !== 32'd30)  $display("FAIL: x6 wrong");
        else if (`REGS[7]  !== 32'd30)  $display("FAIL: x7 wrong");
        else if (`REGS[8]  !== -32'sd10) $display("FAIL: x8 wrong");
        else if (`REGS[9]  !== 32'd30)  $display("FAIL: x9 wrong");
        else if (`REGS[10] !== 32'd20)  $display("FAIL: x10 wrong");
        else if (`REGS[11] !== 32'd7)   $display("FAIL: x11 wrong");
        else if (`REGS[14] !== 32'd77)  $display("FAIL: x14 wrong");
        else if (`DMEM[100 >> 2] !== 32'd77) $display("FAIL: store-data forwarding wrong");
        else $display("PASS: All forwarding tests passed!");

        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("sim/waveforms/pipelined_top_forwarding_tb.vcd");
        $dumpvars(0, pipelined_top_forwarding_tb);
    end

endmodule