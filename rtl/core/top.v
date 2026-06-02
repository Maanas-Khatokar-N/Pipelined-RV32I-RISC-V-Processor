module top (
    input clk, rst
);

    wire [31:0] pc;
    wire [31:0] pc_next;

    wire [31:0] inst;

    
    //Instruction Fetch (IF)

    adder pc_adder (.a(pc), .b(32'd4), .sum(pc_next));
    program_counter pc_reg (.clk(clk), .rst(rst), .pc_next(pc_next), .pc(pc));

    instruction_memory inst_mem (.pc(pc), .inst(inst));



endmodule