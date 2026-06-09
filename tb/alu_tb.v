`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] A, B;
    reg  [1:0]  ALUop;
    reg  [2:0]  funct3;
    reg  [6:0]  funct7;

    wire [3:0]  ALUControl;
    wire [31:0] result;
    wire        zero;

    // =========================
    // ALU CONTROL
    // =========================
    alu_control u0 (
        .ALUop(ALUop),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl)
    );

    // =========================
    // ALU
    // =========================
    alu u1 (
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .result(result),
        .zero(zero)
    );

    // =========================
    // TASK
    // =========================
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

            $display("-----------------------------------");
            $display("TIME       = %0t", $time);
            $display("ALUop      = %b", ALUop);
            $display("funct3     = %b", funct3);
            $display("funct7     = %b", funct7);
            $display("A          = %0d", $signed(A));
            $display("B          = %0d", $signed(B));
            $display("ALUControl = %0d", ALUControl);
            $display("RESULT     = %0d", $signed(result));
            $display("ZERO       = %b", zero);

        end

    endtask


    initial begin

        // =====================================
        // R-TYPE
        // =====================================

        // ADD
        run_test(2'b10, 3'b000, 7'b0000000, -4, -5);

        // SUB
        run_test(2'b10, 3'b000, 7'b0100000, 10, 5);

        // AND
        run_test(2'b10, 3'b111, 7'b0000000, 12, 10);

        // OR
        run_test(2'b10, 3'b110, 7'b0000000, 12, 10);

        // XOR
        run_test(2'b10, 3'b100, 7'b0000000, 12, 10);

        // SLT : 3 < 7
        run_test(2'b10, 3'b010, 7'b0000000, 3, 7);

        // SLT : 9 < 2
        run_test(2'b10, 3'b010, 7'b0000000, 9, 2);

        // SLT : -4 < 2
        run_test(2'b10, 3'b010, 7'b0000000, -4, 2);

        // =====================================
        // I-TYPE
        // =====================================

        // ADDI
        run_test(2'b11, 3'b000, 7'b0000000, 20, 5);

        // ANDI
        run_test(2'b11, 3'b111, 7'b0000000, 12, 10);

        // ORI
        run_test(2'b11, 3'b110, 7'b0000000, 12, 10);

        // =====================================
        // LOAD / STORE
        // =====================================

        // LW / SW address calculation
        run_test(2'b00, 3'b000, 7'b0000000, 100, 20);

        // =====================================
        // BRANCH
        // =====================================

        // BEQ : equal
        run_test(2'b01, 3'b000, 7'b0000000, 8, 8);

        // BEQ : not equal
        run_test(2'b01, 3'b000, 7'b0000000, 8, 3);

        #20;
        $finish;

    end


    initial begin
        $dumpfile("sim/waveforms/alu.vcd");
        $dumpvars(0, alu_tb);
    end

endmodule