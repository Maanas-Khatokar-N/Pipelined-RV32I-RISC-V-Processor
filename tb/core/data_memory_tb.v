`timescale 1ns/1ps

module data_memory_tb;

    reg clk;
    reg MemRead, MemWrite;

    reg [31:0] addr;
    reg [31:0] write_data;

    wire [31:0] read_data;


    // Instantiate DUT
    data_memory dut (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );


    // Clock generation
    always #5 clk = ~clk;


    initial begin

        // Initialize
        clk = 0;
        MemRead = 0;
        MemWrite = 0;
        addr = 0;
        write_data = 0;

        // -----------------------------
        // Test 1 : Write to memory
        // memory[0] = 32'h12345678
        // -----------------------------
        #10;
        MemWrite = 1;
        addr = 32'd0;
        write_data = 32'h12345678;

        #10;
        MemWrite = 0;


        // -----------------------------
        // Test 2 : Read from memory
        // -----------------------------
        #10;
        MemRead = 1;
        addr = 32'd0;

        #10;
        $display("Read Data = %h", read_data);


        // -----------------------------
        // Test 3 : Another write
        // memory[1] = 32'hAAAAAAAA
        // Address = 4
        // -----------------------------
        #10;
        MemRead = 0;
        MemWrite = 1;

        addr = 32'd4;
        write_data = 32'hAAAAAAAA;

        #10;
        MemWrite = 0;


        // -----------------------------
        // Test 4 : Read second location
        // -----------------------------
        #10;
        MemRead = 1;
        addr = 32'd4;

        #10;
        $display("Read Data = %h", read_data);


        #20;
        $finish;

    end


    initial begin
        $dumpfile("sim/waveforms/data_memory.vcd");
        $dumpvars(0, data_memory_tb);
    end

endmodule