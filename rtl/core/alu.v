module alu (
    input [31:0] A, B,
    input [3:0] ALUControl,
    output reg [31:0] result,
    output zero
);
    parameter ADD = 4'b0;
    parameter SUB = 4'b1;

    parameter AND = 4'b2;
    parameter OR = 4'b3;
    parameter XOR = 4'b4;

    parameter SLT = 4'b5;

    
    always @(*) begin
        case (ALUControl)
            ADD: result = A + B;
            SUB: result = A - B;
            AND: result = A & B;
            OR: result = A | B;
            XOR: result = A ^ B;
            SLT: result = $signed(A) < $signed(B);
            default: result = 32'bx;
        endcase
    end

    assign zero = (result == 0);

endmodule