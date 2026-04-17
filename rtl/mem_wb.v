module MEM_WB (
    input clk, rst,

    input [31:0] mem_data_in, alu_in, pc4_in,
    input [4:0] rd_in,

    input RegWrite_in,
    input [1:0] WBSel_in,

    output reg [31:0] mem_data_out, alu_out, pc4_out,
    output reg [4:0] rd_out,

    output reg RegWrite_out,
    output reg [1:0] WBSel_out
);

always @(posedge clk) begin
    if (rst) begin
        mem_data_out <= 0;
        alu_out <= 0;
        pc4_out <= 0;
        rd_out <= 0;

        RegWrite_out <= 0;
        WBSel_out <= 0;
    end
    else begin
        mem_data_out <= mem_data_in;
        alu_out <= alu_in;
        pc4_out <= pc4_in;
        rd_out <= rd_in;

        RegWrite_out <= RegWrite_in;
        WBSel_out <= WBSel_in;
    end
end

endmodule