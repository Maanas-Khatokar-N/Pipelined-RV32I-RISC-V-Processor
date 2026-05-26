module imm_gen (
    input [31:0] inst,
    output reg [31:0] imm_out
);
    
    reg [6:0] opcode;

    always @(*) begin
        opcode = inst[6:0];

        case (opcode)

            //I-Type
            7'b0010011, 7'b0000011: begin
                imm_out = {{20{inst[31]}}, inst[31:20]};
            end

            //S-Type
            7'b0100011: begin
                imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end

            //B-Type
            7'b1100011: begin
                imm_out = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            end

            //J-Type
            7'b1101111: begin
                imm_out = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            end

            default: imm_out = 32'bx;
        endcase

    end

endmodule