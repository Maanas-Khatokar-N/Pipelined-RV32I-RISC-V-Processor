`timescale 1ns/1ps

module program_counter_tb;

    reg clk;
    reg rst;

    reg [31:0] pc_next;

    wire [31:0] pc;


    // Instantiate DUT
    program_counter dut (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc(pc)
    );


    // Clock generation
    always #5 clk = ~clk;


    initial begin

        // Initialize
        clk = 0;
        rst = 1;
        pc_next = 0;

        // Release reset
        #10;
        rst = 0;

        // PC = 4
        #10;
        pc_next = 32'd4;

        // PC = 8
        #10;
        pc_next = 32'd8;

        // PC = 12
        #10;
        pc_next = 32'd12;

        #20;
        $finish;

    end


    initial begin
        $monitor("Time = %0t | PC = %d", $time, pc);

        $dumpfile("sim/waveforms/pc.vcd");
        $dumpvars(0, program_counter_tb);
    end

endmodule