module data_memory (
    input clk,
    input MemRead, MemWrite, 
    input [31:0] addr, write_data,

    output reg [31:0] read_data
);

    reg [31:0] memory [0:255];
    

    //RISC-V addresses bytes. But your memory array is word-based (4 bytes).
    //So addr[31:2] is used instead of addr


    // Asynchronous Read
    always @(*) begin

        if (MemRead)
            read_data = memory[addr[31:2]];         

        else read_data = 32'b0;
    end


    // Synchronous Write
    always @(posedge clk) begin

       if (MemWrite)
            memory[addr[31:2]] <= write_data;

    end

endmodule