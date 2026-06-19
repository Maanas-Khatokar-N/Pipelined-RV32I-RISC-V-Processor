module load_use_hazard_unit (
    input id_ex_MemRead,
    input [4:0] id_ex_rd,

    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,

    output stall,
    output id_ex_flush
);

    assign stall = id_ex_MemRead &&
                   (id_ex_rd != 5'd0) &&
                   ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    assign id_ex_flush = stall;

endmodule