`timescale 1ns/1ps

module register_file_tb;

    reg clk, rst;

    reg [4:0] rs1, rs2, rd;
    reg [31:0] write_data;

    reg write_en;

    wire [31:0] read_data1, read_data2;

    register_file dut (
        clk,
        rst,
        rs1,
        rs2,
        rd,
        write_data,
        write_en,
        read_data1,
        read_data2
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin

        // Initialize signals
        clk = 0;
        rst = 1;

        rs1 = 0;
        rs2 = 0;
        rd  = 0;

        write_data = 0;
        write_en = 0;

        // Reset
        #12;
        rst = 0;

        // Write 10 into x7
        #8;
        write_en = 1;
        rd = 5'd7;
        write_data = 32'd10;

        // Wait for clock edge
        #10;

        // Read x7
        write_en = 0;
        rs1 = 5'd7;

        #5;

        $display("x7 = %d", read_data1);

        // Try writing to x0
        #10;
        write_en = 1;
        rd = 5'd0;
        write_data = 32'd999;

        #10;

        // Read x0
        write_en = 0;
        rs1 = 5'd0;

        #5;

        $display("x0 = %d", read_data1);

        #20;
        $finish;

    end

    initial begin
        $dumpfile("sim/waveforms/register_file.vcd");
        $dumpvars(0, register_file_tb);
    end

endmodule