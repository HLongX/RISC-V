module top_level_pipeline (
    input clk
);

// ================= IF =================
reg [31:0] pc;
wire [31:0] instr;
wire [31:0] pc_plus4;
wire [31:0] next_pc;

assign pc_plus4 = pc + 4;

// Instruction Memory
IMEM imem_inst (
    .addr(pc),
    .instr(instr)
);

// ================= IF/ID =================
wire [31:0] instr_ID, pc_ID;
wire stall, flush;

if_id ifid (
    .clk(clk),
    .stall(stall),
    .flush(flush),
    .instr_in(instr),
    .pc_in(pc),
    .instr_out(instr_ID),
    .pc_out(pc_ID)
);

// ================= ID =================
wire [4:0] rs1_ID, rs2_ID, rd_ID;
assign rs1_ID = instr_ID[19:15];
assign rs2_ID = instr_ID[24:20];
assign rd_ID  = instr_ID[11:7];

// Register File
wire [31:0] reg_rs1_ID, reg_rs2_ID;

wire RegWrite_WB;
wire [4:0] rd_WB;
wire [31:0] result_WB;

register_file rf (
    .clk(clk),
    .rs1(rs1_ID),
    .rs2(rs2_ID),
    .rd(rd_WB),
    .wd(result_WB),
    .RegWrite(RegWrite_WB),
    .rd1(reg_rs1_ID),
    .rd2(reg_rs2_ID)
);

// Immediate Generator
wire [31:0] imm_ID;
imm_gen ig (
    .instr(instr_ID),
    .imm_out(imm_ID)
);

// Control Unit
wire RegWrite_ID, MemRW_ID;
wire [1:0] ResultSrc_ID;
wire [3:0] ALUControl_ID;
wire ALUSrc_ID, Branch_ID;

control_unit cu (
    .instr(instr_ID),
    .RegWrite(RegWrite_ID),
    .MemRW(MemRW_ID),
    .ResultSrc(ResultSrc_ID),
    .ALUControl(ALUControl_ID),
    .ALUSrc(ALUSrc_ID),
    .Branch(Branch_ID)
);

// ================= ID/EX =================
wire RegWrite_EX, MemRW_EX;
wire [1:0] ResultSrc_EX;
wire [3:0] ALUControl_EX;
wire ALUSrc_EX;
wire [31:0] regA_EX, regB_EX, imm_EX;
wire [4:0] rs1_EX, rs2_EX, rd_EX;

id_ex idex (
    .clk(clk),
    .stall(stall),

    .RegWrite_in(RegWrite_ID),
    .MemRW_in(MemRW_ID),
    .ResultSrc_in(ResultSrc_ID),
    .ALUControl_in(ALUControl_ID),
    .ALUSrc_in(ALUSrc_ID),

    .regA_in(reg_rs1_ID),
    .regB_in(reg_rs2_ID),
    .imm_in(imm_ID),

    .rs1_in(rs1_ID),
    .rs2_in(rs2_ID),
    .rd_in(rd_ID),

    .RegWrite_out(RegWrite_EX),
    .MemRW_out(MemRW_EX),
    .ResultSrc_out(ResultSrc_EX),
    .ALUControl_out(ALUControl_EX),
    .ALUSrc_out(ALUSrc_EX),

    .regA_out(regA_EX),
    .regB_out(regB_EX),
    .imm_out(imm_EX),

    .rs1_out(rs1_EX),
    .rs2_out(rs2_EX),
    .rd_out(rd_EX)
);

// ================= EX =================
wire [31:0] alu_in2;
assign alu_in2 = ALUSrc_EX ? imm_EX : regB_EX;

wire [31:0] alu_out_EX;

ALU alu (
    .A(regA_EX),
    .B(alu_in2),
    .ALU_Sel(ALUControl_EX),
    .ALU_Out(alu_out_EX)
);

// Branch comparator
wire branch_taken;

branch_comp bc (
    .A(regA_EX),
    .B(regB_EX),
    .branch_taken(branch_taken)
);

// PC select
wire PCSel_EX;
assign PCSel_EX = Branch_ID & branch_taken;

// ================= EX/MEM =================
wire RegWrite_MEM, MemRW_MEM;
wire [1:0] ResultSrc_MEM;
wire [31:0] alu_MEM, regB_MEM;
wire [4:0] rd_MEM;

ex_mem exmem (
    .clk(clk),

    .RegWrite_in(RegWrite_EX),
    .MemRW_in(MemRW_EX),
    .ResultSrc_in(ResultSrc_EX),

    .alu_in(alu_out_EX),
    .regB_in(regB_EX),
    .rd_in(rd_EX),

    .RegWrite_out(RegWrite_MEM),
    .MemRW_out(MemRW_MEM),
    .ResultSrc_out(ResultSrc_MEM),

    .alu_out(alu_MEM),
    .regB_out(regB_MEM),
    .rd_out(rd_MEM)
);

// ================= MEM =================
wire [31:0] dmem_data_MEM;

DMEM dmem (
    .clk(clk),
    .addr(alu_MEM),
    .DataW(regB_MEM),
    .MemRW(MemRW_MEM),
    .DataR(dmem_data_MEM)
);

// ================= MEM/WB =================
wire [1:0] ResultSrc_WB;
wire [31:0] alu_WB, mem_WB;

mem_wb memwb (
    .clk(clk),

    .RegWrite_in(RegWrite_MEM),
    .ResultSrc_in(ResultSrc_MEM),

    .alu_in(alu_MEM),
    .mem_in(dmem_data_MEM),
    .rd_in(rd_MEM),

    .RegWrite_out(RegWrite_WB),
    .ResultSrc_out(ResultSrc_WB),

    .alu_out(alu_WB),
    .mem_out(mem_WB),
    .rd_out(rd_WB)
);

// ================= WB =================
assign result_WB = (ResultSrc_WB == 2'b00) ? alu_WB :
                   (ResultSrc_WB == 2'b01) ? mem_WB :
                   pc_plus4;

// ================= HAZARD =================
hazard_unit hz (
    .rs1_ID(rs1_ID),
    .rs2_ID(rs2_ID),

    .rd_EX(rd_EX),
    .rd_MEM(rd_MEM),

    .RegWrite_EX(RegWrite_EX),
    .RegWrite_MEM(RegWrite_MEM),

    .stall(stall)
);

// ================= CONTROL =================
assign flush = PCSel_EX;
assign next_pc = PCSel_EX ? alu_out_EX : pc_plus4;

// ================= PC =================
always @(posedge clk) begin
    if (!stall)
        pc <= next_pc;
end

endmodule