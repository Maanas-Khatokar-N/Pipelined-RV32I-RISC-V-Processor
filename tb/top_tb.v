`timescale 1ns/1ps

module top_tb;

    reg clk, rst;

    top dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;

        // Load instruction memory
        $readmemh("programs/fibonacci.mem", dut.inst_mem.memory);

        // Choose Fibonacci input here
        // data_memory[10] = n
        dut.dm.memory[10] = 7;

        #12;
        rst = 1'b0;

        #500;

        $display("Input n        = %0d", dut.dm.memory[10]);
        $display("Fibonacci(n)   = %0d", dut.dm.memory[11]);
        $display("Expected for 7 = 13");

        $finish;
    end

    initial begin
        $dumpfile("sim/waveforms/top.vcd");
        $dumpvars(0, top_tb);
    end

endmodule