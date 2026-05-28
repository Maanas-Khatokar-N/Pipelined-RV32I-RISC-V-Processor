module instruction_memory (
    input [31:0] pc,
    output [31:0] inst
);
    
    reg [31:0] memory [0:255];


    //RISC-V addresses bytes. But your memory array is word-based (4 bytes).
    //So pc[31:2] is used instead of pc
    
    assign inst = memory[pc[31:2]];

endmodule