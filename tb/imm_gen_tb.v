`timescale 1ns/1ps

module imm_gen_tb;

    reg  [31:0] inst;
    wire [31:0] imm_out;

    imm_gen dut (inst, imm_out);

    initial begin

        $display("========== IMM GEN TEST ==========");

        // ---------------------------------
        // I-Type : addi x1, x0, 5
        // Expected = 5
        // ---------------------------------
        inst = 32'h00500093;
        #10;
        $display("I-Type +5     | inst = %h | imm = %h", inst, imm_out);

        // ---------------------------------
        // I-Type : addi x1, x0, -1
        // Expected = FFFFFFFF
        // ---------------------------------
        inst = 32'hFFF00093;
        #10;
        $display("I-Type -1     | inst = %h | imm = %h", inst, imm_out);

        // ---------------------------------
        // S-Type : sw x2, 8(x1)
        // Expected = 8
        // ---------------------------------
        inst = 32'h0020A423;
        #10;
        $display("S-Type +8     | inst = %h | imm = %h", inst, imm_out);

        // ---------------------------------
        // S-Type : sw x2, -8(x1)
        // Expected = FFFFFFF8
        // ---------------------------------
        inst = 32'hFE20AC23;
        #10;
        $display("S-Type -8     | inst = %h | imm = %h", inst, imm_out);

        // ---------------------------------
        // B-Type : beq x1, x2, 8
        // Expected = 8
        // ---------------------------------
        inst = 32'h00208463;
        #10;
        $display("B-Type +8     | inst = %h | imm = %h", inst, imm_out);

        // ---------------------------------
        // B-Type : beq x1, x2, -8
        // Expected = FFFFFFF8
        // ---------------------------------
        inst = 32'hFE208CE3;
        #10;
        $display("B-Type -8     | inst = %h | imm = %h", inst, imm_out);

        // ---------------------------------
        // J-Type : jal x1, 8
        // Expected = 8
        // ---------------------------------
        inst = 32'h008000EF;
        #10;
        $display("J-Type +8     | inst = %h | imm = %h", inst, imm_out);

        // ---------------------------------
        // J-Type : jal x1, -8
        // Expected = FFFFFFF8
        // ---------------------------------
        inst = 32'hFF9FF0EF;
        #10;
        $display("J-Type -8     | inst = %h | imm = %h", inst, imm_out);

        $display("========== TEST COMPLETE ==========");

        $finish;
    end

    initial begin
        $dumpfile("sim/waveforms/imm_gen.vcd");
        $dumpvars(0, imm_gen_tb);
    end

endmodule