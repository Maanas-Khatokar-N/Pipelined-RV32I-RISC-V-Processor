`timescale 1ns/1ps

module fibonacci_pipelined_tb;

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

    // ================= DEBUG WIRES FOR GTKWave =================

    // Main pipeline view
    wire [31:0] dbg_pc        = dut.IF.pc;
    wire [31:0] dbg_inst      = dut.IF.inst;

    // Important Fibonacci registers
    wire [31:0] dbg_x1_count  = dut.ID.rf.registers[1];
    wire [31:0] dbg_x2_result = dut.ID.rf.registers[2];
    wire [31:0] dbg_x3_next   = dut.ID.rf.registers[3];
    wire [31:0] dbg_x4_temp   = dut.ID.rf.registers[4];
    wire [31:0] dbg_x10_base  = dut.ID.rf.registers[10];

    // Important data memory locations
    wire [31:0] dbg_input_N   = dut.MEM.dm.memory[10];
    wire [31:0] dbg_fib_out   = dut.MEM.dm.memory[11];

    // Optional WB view
    wire        dbg_RegWrite  = dut.MEM_WB.RegWrite_out;
    wire [4:0]  dbg_wb_rd     = dut.MEM_WB.rd_out;
    wire [31:0] dbg_wb_data   = dut.WB.wb_write_data;

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
        $dumpvars(0, fibonacci_pipelined_tb);
    end

endmodule