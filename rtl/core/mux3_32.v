module mux3_32 (
    input [31:0] a,
    input [31:0] b,
    input [31:0] c,
    input [1:0] sel,
    
    output reg [31:0] y
);

    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b10: y = b;
            2'b01: y = c;
            default: y = a;
        endcase
    end

endmodule