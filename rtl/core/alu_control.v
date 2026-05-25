module alu_control (
    input [1:0] ALUop,
    input [2:0] funct3, 
    input [6:0] funct7,
    output reg [3:0] ALUControl
);

    always @(*) begin
        
        case (ALUop)
            //load,store,addi -> ADD
            2'b00: ALUControl = 4'd0;      

            //branch -> SUB
            2'b01: ALUControl = 4'd1;      

            //All funct3-based ALU decoding
            2'b10:
                begin                   
                    case (funct3)
                        3'b000:    if (funct7 == 7'b0000000) ALUControl = 4'd0;            //Add
                                else if (funct7 == 7'b0100000) ALUControl = 4'd1;       //Sub
                                else ALUControl = 4'bx;

                        3'b111: ALUControl = 4'd2;            //And
                        3'b110: ALUControl = 4'd3;            //Or
                        3'b100: ALUControl = 4'd4;            //Xor
                        3'b010: ALUControl = 4'd5;            //SLT

                        default: ALUControl = 4'bx;
                    endcase
                end

            2'b11: ALUControl = 4'bx;

            default: ALUControl = 4'bx;
        endcase

    end
    
endmodule