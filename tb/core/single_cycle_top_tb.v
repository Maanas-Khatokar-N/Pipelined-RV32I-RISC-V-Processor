`timescale 1ns/1ps

module single_cycle_top_tb;

    reg clk;
    reg rst;
    integer i;

    // Change these hierarchy names only if your module instance names are different
    `define IMEM dut.inst_mem.memory
    `define DMEM dut.dm.memory
    `define REGS dut.rf.registers

    single_cycled_top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    // ----------------------------
    // RISC-V instruction encoders
    // ----------------------------

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

    function [31:0] B_TYPE;
        input [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            B_TYPE = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
        end
    endfunction

    function [31:0] J_TYPE;
        input [20:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            J_TYPE = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
        end
    endfunction

    // ----------------------------
    // Check task
    // ----------------------------

    task check_reg;
        input [4:0] reg_no;
        input [31:0] expected;
        begin
            if (`REGS[reg_no] === expected)
                $display("PASS: x%0d = %0d", reg_no, `REGS[reg_no]);
            else
                $display("FAIL: x%0d = %0d, Expected = %0d", reg_no, `REGS[reg_no], expected);
        end
    endtask

    task check_mem;
        input [31:0] word_addr;
        input [31:0] expected;
        begin
            if (`DMEM[word_addr] === expected)
                $display("PASS: DMEM[%0d] = %0d", word_addr, `DMEM[word_addr]);
            else
                $display("FAIL: DMEM[%0d] = %0d, Expected = %0d", word_addr, `DMEM[word_addr], expected);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;

        $dumpfile("sim/waveforms/single_cycle_top.vcd");
        $dumpvars(0, single_cycle_top_tb);

        // Clear instruction memory and data memory
        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013;   // NOP = addi x0, x0, 0
            `DMEM[i] = 32'd0;
        end

        // Optional: clear registers if your register file reset already does this, still okay
        for (i = 0; i < 32; i = i + 1) begin
            `REGS[i] = 32'd0;
        end

        // -----------------------------------------
        // Program loaded at instruction memory
        // -----------------------------------------

        // x1 = 10
        `IMEM[0]  = I_TYPE(12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011);     

        // x2 = 20
        `IMEM[1]  = I_TYPE(12'd20, 5'd0, 3'b000, 5'd2, 7'b0010011);     

        // x3 = x1 + x2 = 30
        `IMEM[2]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011);

        // x4 = x2 - x1 = 10
        `IMEM[3]  = R_TYPE(7'b0100000, 5'd1, 5'd2, 3'b000, 5'd4, 7'b0110011);

        // x5 = x1 & x2 = 0
        `IMEM[4]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd5, 7'b0110011);

        // x6 = x1 | x2 = 30
        `IMEM[5]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd6, 7'b0110011);

        // x7 = x1 ^ x2 = 30
        `IMEM[6]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd7, 7'b0110011);

        // x8 = (x1 < x2) = 1
        `IMEM[7]  = R_TYPE(7'b0000000, 5'd2, 5'd1, 3'b010, 5'd8, 7'b0110011);

        // DMEM[25] = x3 = 30
        // address = 100 bytes, word index = 100/4 = 25
        `IMEM[8]  = S_TYPE(12'd100, 5'd3, 5'd0, 3'b010, 7'b0100011);

        // x9 = DMEM[25] = 30
        `IMEM[9]  = I_TYPE(12'd100, 5'd0, 3'b010, 5'd9, 7'b0000011);

        // beq x9, x3, +8
        // Since x9 == x3, next instruction should be skipped
        `IMEM[10] = B_TYPE(13'd8, 5'd3, 5'd9, 3'b000, 7'b1100011);

        // Should be skipped
        `IMEM[11] = I_TYPE(12'd111, 5'd0, 3'b000, 5'd10, 7'b0010011);

        // x11 = 55
        `IMEM[12] = I_TYPE(12'd55, 5'd0, 3'b000, 5'd11, 7'b0010011);

        // bne x1, x2, +8
        // Since 10 != 20, next instruction should be skipped
        `IMEM[13] = B_TYPE(13'd8, 5'd2, 5'd1, 3'b001, 7'b1100011);

        // Should be skipped
        `IMEM[14] = I_TYPE(12'd222, 5'd0, 3'b000, 5'd12, 7'b0010011);

        // x13 = 77
        `IMEM[15] = I_TYPE(12'd77, 5'd0, 3'b000, 5'd13, 7'b0010011);

        // jal x14, +8
        // x14 should get PC+4 = address of next instruction = 17*4 = 68
        // next instruction should be skipped
        `IMEM[16] = J_TYPE(21'd8, 5'd14, 7'b1101111);

        // Should be skipped
        `IMEM[17] = I_TYPE(12'd333, 5'd0, 3'b000, 5'd15, 7'b0010011);

        // x16 = 99
        `IMEM[18] = I_TYPE(12'd99, 5'd0, 3'b000, 5'd16, 7'b0010011);

        // keep NOPs after program
        `IMEM[19] = 32'h00000013;
        `IMEM[20] = 32'h00000013;

        // Reset
        #10;
        rst = 0;

        // Since this is single-cycle, one instruction completes per clock
        repeat (25) @(posedge clk);

        $display("");
        $display("================ SINGLE CYCLE TOP TEST RESULTS ================");

        check_reg(5'd1,  32'd10);
        check_reg(5'd2,  32'd20);
        check_reg(5'd3,  32'd30);
        check_reg(5'd4,  32'd10);
        check_reg(5'd5,  32'd0);
        check_reg(5'd6,  32'd30);
        check_reg(5'd7,  32'd30);
        check_reg(5'd8,  32'd1);
        check_reg(5'd9,  32'd30);

        // branch skip checks
        check_reg(5'd10, 32'd0);
        check_reg(5'd11, 32'd55);
        check_reg(5'd12, 32'd0);
        check_reg(5'd13, 32'd77);

        // jal writeback check
        check_reg(5'd14, 32'd68);
        check_reg(5'd15, 32'd0);
        check_reg(5'd16, 32'd99);

        check_mem(32'd25, 32'd30);

        if (`REGS[0] === 32'd0)
            $display("PASS: x0 = 0");
        else
            $display("FAIL: x0 = %0d, Expected = 0", `REGS[0]);

        $display("===============================================================");
        $finish;
    end

endmodule