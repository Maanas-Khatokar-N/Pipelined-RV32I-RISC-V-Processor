`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] A, B;
    reg  [1:0]  ALUop;
    reg  [2:0]  funct3;
    reg  [6:0]  funct7;

    wire [3:0]  ALUControl;
    wire [31:0] result;
    wire        zero;

    // ALU Control
    alu_control u0 (
        .ALUop(ALUop),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl)
    );

    // ALU
    alu u1 (
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .result(result),
        .zero(zero)
    );

    // Task for applying test vectors
    task run_test;

        input [1:0]  t_ALUop;
        input [2:0]  t_funct3;
        input [6:0]  t_funct7;
        input [31:0] t_A;
        input [31:0] t_B;

        begin

            ALUop  = t_ALUop;
            funct3 = t_funct3;
            funct7 = t_funct7;

            A = t_A;
            B = t_B;

            #10;

            $display("-------------------------------------------");
            $display("TIME = %0t", $time);
            $display("ALUop      = %b", ALUop);
            $display("funct3     = %b", funct3);
            $display("funct7     = %b", funct7);
            $display("A           = %0d", $signed(A));
            $display("B           = %0d", $signed(B));
            $display("ALUControl  = %b", ALUControl);
            $display("RESULT      = %0d", $signed(result));
            $display("ZERO        = %b", zero);

        end

    endtask


    initial begin

        // =========================
        // ADD
        // =========================
        run_test(
            2'b10,
            3'b000,
            7'b0000000,
            32'd10,
            32'd7
        );

        // =========================
        // SUB
        // =========================
        run_test(
            2'b10,
            3'b000,
            7'b0100000,
            32'd15,
            32'd9
        );

        // =========================
        // AND
        // =========================
        run_test(
            2'b10,
            3'b111,
            7'b0000000,
            32'b1100,
            32'b1010
        );

        // =========================
        // OR
        // =========================
        run_test(
            2'b10,
            3'b110,
            7'b0000000,
            32'b1100,
            32'b1010
        );

        // =========================
        // XOR
        // =========================
        run_test(
            2'b10,
            3'b100,
            7'b0000000,
            32'b1100,
            32'b1010
        );

        // =========================
        // SLT : 3 < 7
        // =========================
        run_test(
            2'b10,
            3'b010,
            7'b0000000,
            32'd3,
            32'd7
        );

        // =========================
        // SLT : 9 < 2
        // =========================
        run_test(
            2'b10,
            3'b010,
            7'b0000000,
            32'd9,
            32'd2
        );

        // =========================
        // SLT : -4 < 2
        // =========================
        run_test(
            2'b10,
            3'b010,
            7'b0000000,
            -32'd4,
            32'd2
        );

        // =========================
        // SLT : 2 < -4
        // =========================
        run_test(
            2'b10,
            3'b010,
            7'b0000000,
            32'd2,
            -32'd4
        );

        // =========================
        // ADDI path
        // ALUop = 00
        // =========================
        run_test(
            2'b00,
            3'b000,
            7'b0000000,
            32'd20,
            32'd5
        );

        // =========================
        // Branch path : equal
        // ALUop = 01
        // =========================
        run_test(
            2'b01,
            3'b000,
            7'b0000000,
            32'd8,
            32'd8
        );

        // =========================
        // Branch path : not equal
        // =========================
        run_test(
            2'b01,
            3'b000,
            7'b0000000,
            32'd8,
            32'd3
        );

        #20;
        $finish;

    end


    initial begin
        $dumpfile("sim/waveforms/alu.vcd");
        $dumpvars(0, alu_tb);
    end

endmodule