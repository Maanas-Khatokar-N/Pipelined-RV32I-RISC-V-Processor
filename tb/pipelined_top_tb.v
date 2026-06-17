`timescale 1ns/1ps

module pipelined_fibonacci_tb;

    reg clk;
    reg rst;

    integer i;

    pipelined_top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    localparam NOP = 32'h00000013;

    initial begin
        $dumpfile("sim/waveforms/pipelined_fibonacci_tb.vcd");
        $dumpvars(0, pipelined_fibonacci_tb);

        clk = 1'b0;
        rst = 1'b1;

        // Fill instruction memory with NOPs first
        for (i = 0; i < 256; i = i + 1) begin
            dut.IF.inst_mem.memory[i] = NOP;
        end

        // Clear data memory
        for (i = 0; i < 256; i = i + 1) begin
            dut.MEM.dm.memory[i] = 32'd0;
        end

        // Load Fibonacci program
        $readmemh("programs/fibonacci_pipelined.mem", dut.IF.inst_mem.memory);

        /*
            Program uses:
            x10 = 40

            Because data_memory uses addr[31:2]:

            address 40 -> memory[10]
            address 44 -> memory[11]

            So input N is stored in memory[10]
            Result is stored in memory[11]
        */

        dut.MEM.dm.memory[10] = 32'd7;   // N = 7

        #20;
        rst = 1'b0;

        // Run enough cycles
        repeat (250) @(posedge clk);

        $display("----------------------------------------");
        $display("Fibonacci Pipeline Test");
        $display("Input N       = %0d", dut.MEM.dm.memory[10]);
        $display("Fib(N) result = %0d", dut.MEM.dm.memory[11]);
        $display("----------------------------------------");

        if (dut.MEM.dm.memory[11] == 32'd13) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

endmodule