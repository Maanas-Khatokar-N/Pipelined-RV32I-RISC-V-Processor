`timescale 1ns/1ps

module forwarding_stress_tb;

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

        $dumpfile("sim/waveforms/forwarding_stress_tb.vcd");
        $dumpvars(0, forwarding_stress_tb);

        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013;     // NOP
            `DMEM[i] = 32'd0;
        end

        $readmemh("programs/forwarding_stress.mem", `IMEM);

        #20;
        rst = 0;

        repeat (120) @(posedge clk);

        $display("");
        $display("================ FORWARDING STRESS TEST ================");
        $display("x1  = %0d   Expected = 10", `REGS[1]);
        $display("x2  = %0d   Expected = 20", `REGS[2]);
        $display("x3  = %0d   Expected = 30", `REGS[3]);
        $display("x4  = %0d   Expected = 40", `REGS[4]);
        $display("x5  = %0d   Expected = 20", `REGS[5]);
        $display("x6  = %0d   Expected = 30", `REGS[6]);
        $display("x7  = %0d   Expected = 30", `REGS[7]);
        $display("x8  = %0d   Expected = 10", `REGS[8]);
        $display("x9  = %0d   Expected = 0",  `REGS[9]);
        $display("DMEM[27] = %0d   Expected = 10", `DMEM[27]);
        $display("DMEM[28] = %0d   Expected = 0",  `DMEM[28]);

        if (`REGS[1]  == 10 &&
            `REGS[2]  == 20 &&
            `REGS[3]  == 30 &&
            `REGS[4]  == 40 &&
            `REGS[5]  == 20 &&
            `REGS[6]  == 30 &&
            `REGS[7]  == 30 &&
            `REGS[8]  == 10 &&
            `REGS[9]  == 0  &&
            `DMEM[27] == 10 &&
            `DMEM[28] == 0) begin
            $display("PASS: forwarding stress program working");
        end
        else begin
            $display("FAIL: forwarding stress program wrong");
        end

        $display("=========================================================");
        $display("");

        $finish;
    end

endmodule