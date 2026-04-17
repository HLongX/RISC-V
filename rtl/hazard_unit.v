module hazard_unit (
    input [4:0] rs1_ID,
    input [4:0] rs2_ID,

    input [4:0] rd_EX,
    input [4:0] rd_MEM,

    input RegWrite_EX,
    input RegWrite_MEM,

    output stall
);

assign stall =
    (RegWrite_EX && (rd_EX != 0) &&
    ((rd_EX == rs1_ID) || (rd_EX == rs2_ID))) ||

    (RegWrite_MEM && (rd_MEM != 0) &&
    ((rd_MEM == rs1_ID) || (rd_MEM == rs2_ID)));

endmodule