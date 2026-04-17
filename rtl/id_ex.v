module id_ex (
    input clk,
    input stall,

    input RegWrite_in,
    input MemRW_in,
    input [1:0] ResultSrc_in,
    input [3:0] ALUControl_in,

    output reg RegWrite_out,
    output reg MemRW_out,
    output reg [1:0] ResultSrc_out,
    output reg [3:0] ALUControl_out
);

always @(posedge clk) begin
    if (stall) begin
        // Inject NOP
        RegWrite_out <= 0;
        MemRW_out    <= 0;
        ResultSrc_out<= 0;
        ALUControl_out <= 0;
    end else begin
        RegWrite_out <= RegWrite_in;
        MemRW_out    <= MemRW_in;
        ResultSrc_out<= ResultSrc_in;
        ALUControl_out <= ALUControl_in;
    end
end

endmodule