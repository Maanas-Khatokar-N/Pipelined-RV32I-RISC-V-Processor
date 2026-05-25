module alu (
    input [31:0] A, B,
    input [3:0] ALUControl,
    output reg [31:0] result,
    output zero
);
    parameter ADD = 4'd0;
    parameter SUB = 4'd1;

    parameter AND = 4'd2;
    parameter OR = 4'd3;
    parameter XOR = 4'd4;

    parameter SLT = 4'd5;

    
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