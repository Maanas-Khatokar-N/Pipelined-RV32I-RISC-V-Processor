`timescale 1ns/1ps

module control_unit_tb;

    reg [6:0] opcode;

    wire RegWrite;
    wire ALUSrc;
    wire MemRead;
    wire MemWrite;
    wire MemToReg;
    wire Branch;
    wire Jump;
    wire [1:0] ALUOp;

    // =========================
    // DUT
    // =========================
    control_unit dut (
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

    // =========================
    // TASK
    // =========================
    task run_test;

        input [6:0] t_opcode;

        begin

            opcode = t_opcode;

            #10;

            $display("--------------------------------------");
            $display("TIME      = %0t", $time);
            $display("opcode    = %b", opcode);

            $display("RegWrite  = %b", RegWrite);
            $display("ALUSrc    = %b", ALUSrc);
            $display("MemRead   = %b", MemRead);
            $display("MemWrite  = %b", MemWrite);
            $display("MemToReg  = %b", MemToReg);
            $display("Branch    = %b", Branch);
            $display("Jump      = %b", Jump);
            $display("ALUOp     = %b", ALUOp);

        end

    endtask

    // =========================
    // TESTS
    // =========================
    initial begin

        // R-Type
        run_test(7'b0110011);

        // I-Type
        run_test(7'b0010011);

        // Load
        run_test(7'b0000011);

        // Store
        run_test(7'b0100011);

        // Branch
        run_test(7'b1100011);

        // JAL
        run_test(7'b1101111);

        // Invalid Opcode
        run_test(7'b1111111);

        #20;
        $finish;

    end

    // =========================
    // WAVEFORM
    // =========================
    initial begin
        $dumpfile("sim/waveforms/control_unit.vcd");
        $dumpvars(0, control_unit_tb);
    end

endmodule