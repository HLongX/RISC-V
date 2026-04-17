module RegFile (
    input clk,
    input RegWrite,
    input [4:0] rs1, rs2, rd,
    input [31:0] wd,
    output [31:0] rd1, rd2
);

reg [31:0] regfile [31:0];

// Read (combinational)
assign rd1 = (rs1 == 0) ? 32'd0 : regfile[rs1];
assign rd2 = (rs2 == 0) ? 32'd0 : regfile[rs2];

// Write (sequential)
always @(posedge clk) begin
    if (RegWrite && rd != 0)
        regfile[rd] <= wd;
end

endmodule