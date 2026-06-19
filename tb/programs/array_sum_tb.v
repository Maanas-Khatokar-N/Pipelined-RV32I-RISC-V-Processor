`timescale 1ns/1ps

module array_sum_tb;

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

        $dumpfile("sim/waveforms/array_sum_tb.vcd");
        $dumpvars(0, array_sum_tb);

        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013;
            `DMEM[i] = 32'd0;
        end

        $readmemh("programs/array_sum.mem", `IMEM);

        // Array at DMEM[40] to DMEM[44]
        `DMEM[40] = 10;
        `DMEM[41] = 20;
        `DMEM[42] = 30;
        `DMEM[43] = 40;
        `DMEM[44] = 50;

        #20;
        rst = 0;

        repeat (250) @(posedge clk);

        $display("");
        $display("================ ARRAY SUM TEST ================");
        $display("DMEM[40] = %0d", `DMEM[40]);
        $display("DMEM[41] = %0d", `DMEM[41]);
        $display("DMEM[42] = %0d", `DMEM[42]);
        $display("DMEM[43] = %0d", `DMEM[43]);
        $display("DMEM[44] = %0d", `DMEM[44]);
        $display("Output DMEM[27] = %0d", `DMEM[27]);
        $display("Expected        = 150");

        if (`DMEM[27] == 150)
            $display("PASS: array sum working");
        else
            $display("FAIL: array sum wrong");

        $display("================================================");
        $display("");

        $finish;
    end

endmodule