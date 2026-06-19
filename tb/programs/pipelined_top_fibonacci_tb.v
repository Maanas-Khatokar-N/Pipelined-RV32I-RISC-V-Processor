`timescale 1ns/1ps

module pipelined_top_fibonacci_tb;

    reg clk;
    reg rst;
    integer i;

    `define IMEM dut.IF.inst_mem.memory
    `define REGS dut.ID.rf.registers
    `define DMEM dut.MEM.dm.memory

    localparam PROGRAM_FILE = "programs/fibonacci.mem";

    pipelined_top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        // Clear instruction memory first
        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013;   // nop = addi x0, x0, 0
        end

        // Clear data memory
        for (i = 0; i < 256; i = i + 1) begin
            `DMEM[i] = 32'd0;
        end

        // Load your existing Fibonacci program
        $readmemh(PROGRAM_FILE, `IMEM);

        `DMEM[10] = 32'd7;     // N = 7

        #12;
        rst = 0;

        // Run enough cycles for loop program
        #1500;

        $display("\n============== FIBONACCI FILE PROGRAM TEST ==============");
        $display("Program file loaded : %s", PROGRAM_FILE);
        $display("Input N : %0d", `DMEM[10]);

        $display("Result : %0d", `DMEM[11]);
        $display("Expected Result: 13");
        $display("==========================================================\n");

        $finish;
    end

    initial begin
        $dumpfile("sim/waveforms/fibonacci_pipelined.vcd");
        $dumpvars(0, pipelined_top_fibonacci_tb);
    end

endmodule