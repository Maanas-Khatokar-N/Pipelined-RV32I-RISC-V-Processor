`timescale 1ns/1ps

module instruction_memory_tb;

    reg  [31:0] pc;
    wire [31:0] inst;

    instruction_memory dut (
        .pc(pc),
        .inst(inst)
    );

    initial begin

        // Load instructions manually
        dut.memory[0] = 32'h00500093; // addi x1, x0, 5
        dut.memory[1] = 32'h00A00113; // addi x2, x0, 10
        dut.memory[2] = 32'h002081B3; // add x3, x1, x2

        // Fetch instruction 0
        pc = 32'd0;
        #10;

        // Fetch instruction 1
        pc = 32'd4;
        #10;

        // Fetch instruction 2
        pc = 32'd8;
        #10;

        $finish;
    end

    initial begin
        $monitor("Time = %0t | PC = %d | Instruction = %h",
                  $time, pc, inst);
    end

    initial begin
        $dumpfile("sim/waveforms/instruction_memory.vcd");
        $dumpvars(0, instruction_memory_tb);
    end

endmodule