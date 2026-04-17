module EX_MEM (
    input clk, rst,

    input [31:0] alu_in, regB_in, pc4_in,
    input [4:0] rd_in,

    input MemRead_in, MemWrite_in, RegWrite_in,
    input [1:0] WBSel_in,

    output reg [31:0] alu_out, regB_out, pc4_out,
    output reg [4:0] rd_out,

    output reg MemRead_out, MemWrite_out, RegWrite_out,
    output reg [1:0] WBSel_out
);

always @(posedge clk) begin
    if (rst) begin
        alu_out <= 0;
        regB_out <= 0;
        pc4_out <= 0;
        rd_out <= 0;

        MemRead_out <= 0;
        MemWrite_out <= 0;
        RegWrite_out <= 0;
        WBSel_out <= 0;
    end
    else begin
        alu_out <= alu_in;
        regB_out <= regB_in;
        pc4_out <= pc4_in;
        rd_out <= rd_in;

        MemRead_out <= MemRead_in;
        MemWrite_out <= MemWrite_in;
        RegWrite_out <= RegWrite_in;
        WBSel_out <= WBSel_in;
    end
end

endmodule