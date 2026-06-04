`timescale 1ns/1ps

module top_tb;

    reg clk, rst;

    top dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Reset
        rst = 1'b1;

        // Load program into instruction memory
        // Program:
        // addi x1, x0, 10
        // addi x2, x0, 20
        // add  x3, x1, x2
        // sw   x3, 0(x0)
        // lw   x4, 0(x0)

        dut.inst_mem.memory[0] = 32'h00A00093; // addi x1, x0, 10
        dut.inst_mem.memory[1] = 32'h01400113; // addi x2, x0, 20
        dut.inst_mem.memory[2] = 32'h002081B3; // add x3, x1, x2
        dut.inst_mem.memory[3] = 32'h00302023; // sw x3, 0(x0)
        dut.inst_mem.memory[4] = 32'h00002203; // lw x4, 0(x0)

        #12;
        rst = 1'b0;

        // Run enough cycles
        #100;

        $display("x1 = %0d", dut.rf.registers[1]);
        $display("x2 = %0d", dut.rf.registers[2]);
        $display("x3 = %0d", dut.rf.registers[3]);
        $display("x4 = %0d", dut.rf.registers[4]);
        $display("Mem[0] = %0d", dut.dm.memory[0]);

        $finish;
    end

    initial begin
        $dumpfile("sim/waveforms/top.vcd");
        $dumpvars(0, top_tb);
    end

endmodule