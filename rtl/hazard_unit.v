// Hazard detection unit — no forwarding.
// Without forwarding, a producer in EX needs 3 stall cycles before the
// consumer can safely read from the register file (write happens at posedge
// of WB cycle; consumer reads combinationally before that posedge).
// Checking EX + MEM + WB covers all three stall cycles.
module hazard_unit (
    input [4:0] rs1_ID,
    input [4:0] rs2_ID,

    input [4:0] rd_EX,
    input [4:0] rd_MEM,
    input [4:0] rd_WB,

    input RegWrite_EX,
    input RegWrite_MEM,
    input RegWrite_WB,

    output stall
);

wire dep_EX  = RegWrite_EX  && (rd_EX  != 5'd0)
             && ((rd_EX  == rs1_ID) || (rd_EX  == rs2_ID));

wire dep_MEM = RegWrite_MEM && (rd_MEM != 5'd0)
             && ((rd_MEM == rs1_ID) || (rd_MEM == rs2_ID));

wire dep_WB  = RegWrite_WB  && (rd_WB  != 5'd0)
             && ((rd_WB  == rs1_ID) || (rd_WB  == rs2_ID));

assign stall = dep_EX || dep_MEM || dep_WB;

endmodule
