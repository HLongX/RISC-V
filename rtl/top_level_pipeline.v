module top_level_pipeline (
    input clk,
    input rst
);

// ============================================================
// IF — Instruction Fetch
// ============================================================
reg [31:0] pc = 32'd0;
wire [31:0] instr;
wire [31:0] pc_plus4;
wire [31:0] next_pc;
wire        stall, flush;

assign pc_plus4 = pc + 4;

IMEM imem_inst (
    .addr(pc),
    .instr(instr)
);

// ============================================================
// IF/ID pipeline register
// ============================================================
wire [31:0] instr_ID, pc_ID, pc4_ID;

if_id ifid (
    .clk(clk),
    .rst(rst),
    .stall(stall),
    .flush(flush),
    .instr_in(instr),
    .pc_in(pc),
    .pc4_in(pc_plus4),
    .instr_out(instr_ID),
    .pc_out(pc_ID),
    .pc4_out(pc4_ID)
);

// ============================================================
// ID — Instruction Decode
// ============================================================
wire [4:0] rs1_ID, rs2_ID, rd_ID;
wire [2:0] funct3_ID;
assign rs1_ID    = instr_ID[19:15];
assign rs2_ID    = instr_ID[24:20];
assign rd_ID     = instr_ID[11:7];
assign funct3_ID = instr_ID[14:12];

// Register file (write-back wires declared below, forward-declared here)
wire        RegWrite_WB;
wire [4:0]  rd_WB;
wire [31:0] result_WB;
wire [31:0] reg_rs1_ID, reg_rs2_ID;

RegFile rf (
    .clk(clk),
    .rs1(rs1_ID),
    .rs2(rs2_ID),
    .rd(rd_WB),
    .wd(result_WB),
    .RegWrite(RegWrite_WB),
    .rd1(reg_rs1_ID),
    .rd2(reg_rs2_ID)
);

// Immediate generator
wire [31:0] imm_ID;
wire [2:0]  ImmSel_ID;

ImmGen ig (
    .instr(instr_ID),
    .ImmSel(ImmSel_ID),
    .imm(imm_ID)
);

// Pipeline control unit
wire        RegWrite_ID, MemRW_ID;
wire [1:0]  ResultSrc_ID;
wire [3:0]  ALUControl_ID;
wire        ALUSrc_ID, ASel_ID, Branch_ID, Jump_ID, BrUn_ID;

control_unit cu (
    .instr(instr_ID),
    .RegWrite(RegWrite_ID),
    .MemRW(MemRW_ID),
    .ResultSrc(ResultSrc_ID),
    .ALUControl(ALUControl_ID),
    .ALUSrc(ALUSrc_ID),
    .ASel(ASel_ID),
    .Branch(Branch_ID),
    .Jump(Jump_ID),
    .BrUn(BrUn_ID),
    .ImmSel(ImmSel_ID)
);

// ============================================================
// ID/EX pipeline register
// ============================================================
wire        RegWrite_EX, MemRW_EX;
wire [1:0]  ResultSrc_EX;
wire [3:0]  ALUControl_EX;
wire        ALUSrc_EX, ASel_EX, Branch_EX, Jump_EX, BrUn_EX;
wire [31:0] regA_EX, regB_EX, imm_EX, pc_EX, pc4_EX;
wire [4:0]  rs1_EX, rs2_EX, rd_EX;
wire [2:0]  funct3_EX;

id_ex idex (
    .clk(clk),
    .rst(rst),
    .flush(flush),
    .stall(stall),

    .RegWrite_in(RegWrite_ID),
    .MemRW_in(MemRW_ID),
    .ResultSrc_in(ResultSrc_ID),
    .ALUControl_in(ALUControl_ID),
    .ALUSrc_in(ALUSrc_ID),
    .ASel_in(ASel_ID),
    .Branch_in(Branch_ID),
    .Jump_in(Jump_ID),
    .BrUn_in(BrUn_ID),

    .regA_in(reg_rs1_ID),
    .regB_in(reg_rs2_ID),
    .imm_in(imm_ID),
    .pc_in(pc_ID),
    .pc4_in(pc4_ID),

    .rs1_in(rs1_ID),
    .rs2_in(rs2_ID),
    .rd_in(rd_ID),
    .funct3_in(funct3_ID),

    .RegWrite_out(RegWrite_EX),
    .MemRW_out(MemRW_EX),
    .ResultSrc_out(ResultSrc_EX),
    .ALUControl_out(ALUControl_EX),
    .ALUSrc_out(ALUSrc_EX),
    .ASel_out(ASel_EX),
    .Branch_out(Branch_EX),
    .Jump_out(Jump_EX),
    .BrUn_out(BrUn_EX),

    .regA_out(regA_EX),
    .regB_out(regB_EX),
    .imm_out(imm_EX),
    .pc_out(pc_EX),
    .pc4_out(pc4_EX),

    .rs1_out(rs1_EX),
    .rs2_out(rs2_EX),
    .rd_out(rd_EX),
    .funct3_out(funct3_EX)
);

// ============================================================
// EX — Execute
// ============================================================
wire [31:0] alu_in1, alu_in2, alu_out_EX;

assign alu_in1 = ASel_EX  ? pc_EX  : regA_EX;
assign alu_in2 = ALUSrc_EX ? imm_EX : regB_EX;

ALU alu (
    .A(alu_in1),
    .B(alu_in2),
    .ALU_Sel(ALUControl_EX),
    .ALU_Out(alu_out_EX)
);

// Branch comparator (operates on register values, not ALU inputs)
wire BrEq, BrLT;

BranchComp bc (
    .A(regA_EX),
    .B(regB_EX),
    .BrUn(BrUn_EX),
    .BrEq(BrEq),
    .BrLT(BrLT)
);

// Branch taken decision based on funct3 of the branch instruction
reg branch_cond;
always @(*) begin
    case (funct3_EX)
        3'b000: branch_cond =  BrEq;  // BEQ
        3'b001: branch_cond = ~BrEq;  // BNE
        3'b100: branch_cond =  BrLT;  // BLT
        3'b101: branch_cond = ~BrLT;  // BGE
        3'b110: branch_cond =  BrLT;  // BLTU
        3'b111: branch_cond = ~BrLT;  // BGEU
        default: branch_cond = 1'b0;
    endcase
end

wire PCSel_EX;
assign PCSel_EX = (Branch_EX & branch_cond) | Jump_EX;

// ============================================================
// EX/MEM pipeline register
// ============================================================
wire        RegWrite_MEM, MemRW_MEM;
wire [1:0]  ResultSrc_MEM;
wire [31:0] alu_MEM, regB_MEM, pc4_MEM;
wire [4:0]  rd_MEM;

ex_mem exmem (
    .clk(clk),
    .rst(rst),

    .RegWrite_in(RegWrite_EX),
    .MemRW_in(MemRW_EX),
    .ResultSrc_in(ResultSrc_EX),

    .alu_in(alu_out_EX),
    .regB_in(regB_EX),
    .pc4_in(pc4_EX),
    .rd_in(rd_EX),

    .RegWrite_out(RegWrite_MEM),
    .MemRW_out(MemRW_MEM),
    .ResultSrc_out(ResultSrc_MEM),

    .alu_out(alu_MEM),
    .regB_out(regB_MEM),
    .pc4_out(pc4_MEM),
    .rd_out(rd_MEM)
);

// ============================================================
// MEM — Memory Access
// ============================================================
wire [31:0] dmem_data_MEM;

DMEM dmem (
    .clk(clk),
    .addr(alu_MEM),
    .DataW(regB_MEM),
    .MemRW(MemRW_MEM),
    .DataR(dmem_data_MEM)
);

// ============================================================
// MEM/WB pipeline register
// ============================================================
wire [1:0]  ResultSrc_WB;
wire [31:0] alu_WB, mem_WB, pc4_WB;

mem_wb memwb (
    .clk(clk),
    .rst(rst),

    .RegWrite_in(RegWrite_MEM),
    .ResultSrc_in(ResultSrc_MEM),

    .alu_in(alu_MEM),
    .mem_in(dmem_data_MEM),
    .pc4_in(pc4_MEM),
    .rd_in(rd_MEM),

    .RegWrite_out(RegWrite_WB),
    .ResultSrc_out(ResultSrc_WB),

    .alu_out(alu_WB),
    .mem_out(mem_WB),
    .pc4_out(pc4_WB),
    .rd_out(rd_WB)
);

// ============================================================
// WB — Write Back
// ============================================================
// ResultSrc: 00=ALU result, 01=memory data, 10=PC+4 (JAL/JALR)
assign result_WB = (ResultSrc_WB == 2'b00) ? alu_WB  :
                   (ResultSrc_WB == 2'b01) ? mem_WB  :
                   pc4_WB;

// ============================================================
// Hazard detection (no forwarding — 3 stall cycles for RAW)
// ============================================================
hazard_unit hz (
    .rs1_ID(rs1_ID),
    .rs2_ID(rs2_ID),

    .rd_EX(rd_EX),
    .rd_MEM(rd_MEM),
    .rd_WB(rd_WB),

    .RegWrite_EX(RegWrite_EX),
    .RegWrite_MEM(RegWrite_MEM),
    .RegWrite_WB(RegWrite_WB),

    .stall(stall)
);

// ============================================================
// PC and flush control
// ============================================================
// Branch target / jump target is computed by ALU in EX stage.
// flush discards two wrong-path instructions (in IF/ID and ID/EX).
// flush takes priority over stall so we jump even if ID is stalled.
assign flush   = PCSel_EX;
assign next_pc = PCSel_EX ? alu_out_EX : pc_plus4;

always @(posedge clk or posedge rst) begin
    if (rst)
        pc <= 32'd0;
    else if (flush || !stall)
        pc <= next_pc;
end

endmodule
