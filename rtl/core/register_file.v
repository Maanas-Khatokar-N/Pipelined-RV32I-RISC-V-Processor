module register_file (
    input clk, rst,

    input [4:0] rs1, rs2, rd,
    input [31:0] write_data,

    input write_en,

    output [31:0] read_data1, read_data2
);


    reg [31:0] registers [31:0];

    //Read
    assign read_data1 = registers[rs1];
    assign read_data2 = registers[rs2];


    //Write
    always @(posedge clk) begin

        //Reset
        if (rst) begin
            //All registers assigned to 0
            integer i;
            for(i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end

        //Write when write is enabled and rd != 0
        else begin

            //Fix x0 = 0;
            registers[0] <= 32'b0;

            if (write_en && rd != 5'b00000)
                registers[rd] <= write_data;

        end

    end


endmodule