module forwarding_unit (
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,

    input [4:0] ex_mem_rd,
    input ex_mem_RegWrite,

    input [4:0] mem_wb_rd,
    input mem_wb_RegWrite,

    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

    always @(*) begin
        // Default: no forwarding
        ForwardA = 2'b00;
        ForwardB = 2'b00;

        // EX hazard
        if (ex_mem_RegWrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            ForwardA = 2'b10;
        end

        if (ex_mem_RegWrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            ForwardB = 2'b10;
        end

        // MEM hazard
        // Only if EX/MEM is not already forwarding
        if (mem_wb_RegWrite && (mem_wb_rd != 5'd0) &&
            !(ex_mem_RegWrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) &&  // Only if EX/MEM is not already forwarding
            (mem_wb_rd == id_ex_rs1)) begin
            ForwardA = 2'b01;
        end

        if (mem_wb_RegWrite && (mem_wb_rd != 5'd0) &&
            !(ex_mem_RegWrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) &&  // Only if EX/MEM is not already forwarding
            (mem_wb_rd == id_ex_rs2)) begin
            ForwardB = 2'b01;
        end
    end
    
endmodule