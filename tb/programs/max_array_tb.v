`timescale 1ns/1ps

module max_array_tb;

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

        $dumpfile("sim/waveforms/max_array_tb.vcd");
        $dumpvars(0, max_array_tb);

        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013;     // NOP
            `DMEM[i] = 32'd0;
        end

        $readmemh("programs/max_array.mem", `IMEM);

        // Array at DMEM[40] to DMEM[44]
        `DMEM[40] = 12;
        `DMEM[41] = 7;
        `DMEM[42] = 45;
        `DMEM[43] = 23;
        `DMEM[44] = 31;

        #20;
        rst = 0;

        repeat (250) @(posedge clk);

        $display("");
        $display("================ MAX ARRAY TEST ================");
        $display("DMEM[40] = %0d", `DMEM[40]);
        $display("DMEM[41] = %0d", `DMEM[41]);
        $display("DMEM[42] = %0d", `DMEM[42]);
        $display("DMEM[43] = %0d", `DMEM[43]);
        $display("DMEM[44] = %0d", `DMEM[44]);
        $display("Output DMEM[27] = %0d", `DMEM[27]);
        $display("Expected        = 45");

        if (`DMEM[27] == 45)
            $display("PASS: max array working");
        else
            $display("FAIL: max array wrong");

        $display("================================================");
        $display("");

        $finish;
    end

endmodule