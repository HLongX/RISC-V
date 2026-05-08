module ex_mem (
    input clk,
    input rst,

    input        RegWrite_in,
    input        MemRW_in,
    input  [1:0] ResultSrc_in,

    input [31:0] alu_in,
    input [31:0] regB_in,
    input [31:0] pc4_in,
    input [4:0]  rd_in,

    output reg        RegWrite_out,
    output reg        MemRW_out,
    output reg  [1:0] ResultSrc_out,

    output reg [31:0] alu_out,
    output reg [31:0] regB_out,
    output reg [31:0] pc4_out,
    output reg [4:0]  rd_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        RegWrite_out  <= 0;
        MemRW_out     <= 0;
        ResultSrc_out <= 0;
        alu_out       <= 0;
        regB_out      <= 0;
        pc4_out       <= 0;
        rd_out        <= 0;
    end else begin
        RegWrite_out  <= RegWrite_in;
        MemRW_out     <= MemRW_in;
        ResultSrc_out <= ResultSrc_in;
        alu_out       <= alu_in;
        regB_out      <= regB_in;
        pc4_out       <= pc4_in;
        rd_out        <= rd_in;
    end
end

endmodule
