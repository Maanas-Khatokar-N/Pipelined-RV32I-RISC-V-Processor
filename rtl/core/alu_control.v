module alu_control (
    input [1:0] ALUop,
    input [2:0] funct3, 
    input [6:0] funct7,
    output reg [3:0] ALUControl
);

    always @(*) begin
        
        case (ALUop)
            //load,store,addi -> ADD
            00: ALUControl = 4'b0;      

            //branch -> SUB
            01: ALUControl = 4'b1;      

            //All funct3-based ALU decoding
            10:
                begin                   
                    case (funct3)
                        000:    if (funct7 == 7'b0000000) ALUControl = 4'b0;            //Add
                                else if (funct7 == 7'b0100000) ALUControl = 4'b1;       //Sub
                                else ALUControl = 4'bx;

                        111: ALUControl = 4'b2;            //And
                        110: ALUControl = 4'b3;            //Or
                        100: ALUControl = 4'b4;            //Xor
                        010: ALUControl = 4'b5;            //SLT

                        default: ALUControl = 4'bx;
                    endcase
                end

            11: ALUControl = 4'bx;

            default: ALUControl = 4'bx;
        endcase

    end
    
endmodule