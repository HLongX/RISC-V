// ID/EX pipeline register.
// On flush OR stall: inject NOP bubble (zero all control signals).
module id_ex (
    input clk,
    input rst,
    input flush,
    input stall,

    // Control signals
    input        RegWrite_in,
    input        MemRW_in,
    input  [1:0] ResultSrc_in,
    input  [3:0] ALUControl_in,
    input        ALUSrc_in,
    input        ASel_in,
    input        Branch_in,
    input        Jump_in,
    input        BrUn_in,

    // Data
    input [31:0] regA_in,
    input [31:0] regB_in,
    input [31:0] imm_in,
    input [31:0] pc_in,
    input [31:0] pc4_in,

    // Register addresses + funct3 (needed for hazard detection and branch type)
    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,
    input [2:0] funct3_in,

    // Control signals out
    output reg        RegWrite_out,
    output reg        MemRW_out,
    output reg  [1:0] ResultSrc_out,
    output reg  [3:0] ALUControl_out,
    output reg        ALUSrc_out,
    output reg        ASel_out,
    output reg        Branch_out,
    output reg        Jump_out,
    output reg        BrUn_out,

    // Data out
    output reg [31:0] regA_out,
    output reg [31:0] regB_out,
    output reg [31:0] imm_out,
    output reg [31:0] pc_out,
    output reg [31:0] pc4_out,

    // Register addresses + funct3 out
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [2:0] funct3_out
);

always @(posedge clk or posedge rst) begin
    if (rst || flush || stall) begin
        RegWrite_out   <= 0;
        MemRW_out      <= 0;
        ResultSrc_out  <= 0;
        ALUControl_out <= 0;
        ALUSrc_out     <= 0;
        ASel_out       <= 0;
        Branch_out     <= 0;
        Jump_out       <= 0;
        BrUn_out       <= 0;
        regA_out       <= 0;
        regB_out       <= 0;
        imm_out        <= 0;
        pc_out         <= 0;
        pc4_out        <= 0;
        rs1_out        <= 0;
        rs2_out        <= 0;
        rd_out         <= 0;
        funct3_out     <= 0;
    end else begin
        RegWrite_out   <= RegWrite_in;
        MemRW_out      <= MemRW_in;
        ResultSrc_out  <= ResultSrc_in;
        ALUControl_out <= ALUControl_in;
        ALUSrc_out     <= ALUSrc_in;
        ASel_out       <= ASel_in;
        Branch_out     <= Branch_in;
        Jump_out       <= Jump_in;
        BrUn_out       <= BrUn_in;
        regA_out       <= regA_in;
        regB_out       <= regB_in;
        imm_out        <= imm_in;
        pc_out         <= pc_in;
        pc4_out        <= pc4_in;
        rs1_out        <= rs1_in;
        rs2_out        <= rs2_in;
        rd_out         <= rd_in;
        funct3_out     <= funct3_in;
    end
end

endmodule
