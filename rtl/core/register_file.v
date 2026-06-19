module register_file (
    input clk, rst,

    input [4:0] rs1, rs2, rd,
    input [31:0] write_data,

    input write_en,

    output [31:0] read_data1, read_data2
);

    reg [31:0] registers [31:0];
    integer i;

    assign read_data1 = (rs1 == 5'd0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'b0 : registers[rs2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else begin
            registers[0] <= 32'b0;

            if (write_en && rd != 5'd0)
                registers[rd] <= write_data;
        end
    end

endmodule