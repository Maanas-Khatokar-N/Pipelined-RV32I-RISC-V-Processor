module alu_control (
    input [1:0] ALUop,
    input [2:0] funct3, 
    input [6:0] funct7,
    output reg [3:0] ALUControl
);

    always @(*) begin
        
        case (ALUop)
            //load,store -> ADD
            2'b00: ALUControl = 4'd0;      

            //branch -> SUB
            2'b01: ALUControl = 4'd1;      

            //R-Type
            2'b10: begin                   
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

            //I-Type
            2'b11: begin
                    case (funct3)
                        3'b000: ALUControl = 4'd0;            //Addi
                        3'b111: ALUControl = 4'd2;            //Andi
                        3'b110: ALUControl = 4'd3;            //Ori

                        default: ALUControl = 4'bx;
                    endcase
            end

            default: ALUControl = 4'bx;
        endcase

    end
    
endmodule