`timescale 1ns/1ps

module gcd_subtraction_tb;

    reg clk;
    reg rst;
    integer i;

    pipelined_top dut (
        .clk(clk),
        .rst(rst)
    );

    `define IMEM dut.IF.inst_mem.memory
    `define DMEM dut.MEM.dm.memory
    `define REGS dut.ID.rf.registers

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        $dumpfile("sim/waveforms/gcd_subtraction_tb.vcd");
        $dumpvars(0, gcd_subtraction_tb);

        // Clear instruction memory
        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013;     // NOP
        end

        // Clear data memory
        for (i = 0; i < 256; i = i + 1) begin
            `DMEM[i] = 32'd0;
        end

        // Load program
        $readmemh("programs/gcd_subtraction.mem", `IMEM);

        // Inputs
        `DMEM[25] = 48;      // A
        `DMEM[26] = 18;      // B

        #20;
        rst = 0;

        // Run enough cycles
        repeat (300) @(posedge clk);

        $display("");
        $display("================ GCD SUBTRACTION TEST ================");
        $display("Input A      DMEM[25] : %0d", `DMEM[25]);
        $display("Input B      DMEM[26] : %0d", `DMEM[26]);
        $display("Output GCD   DMEM[27] : %0d", `DMEM[27]);
        $display("Expected              : 6");

        if (`DMEM[27] == 6)
            $display("PASS: GCD program working");
        else
            $display("FAIL: GCD program wrong");

        $display("=======================================================");
        $display("");

        $finish;
    end

endmodule