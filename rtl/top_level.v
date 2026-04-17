module CPU (
    input clk,
    input rst
);

// ================= SIGNAL =================
wire [31:0] pc, next_pc, pc_plus4;
wire [31:0] instr;

wire PCSel, RegWEn, BrUn, BSel, ASel, MemRW;
wire [2:0] ImmSel;
wire [3:0] ALUSel;
wire [1:0] WBSel;

wire [31:0] imm;
wire [31:0] reg_rs1, reg_rs2;
wire [31:0] alu_in1, alu_in2, alu_out;
wire [31:0] dmem_data;
wire [31:0] wb_data;

wire BrEq, BrLT;

// ================= PC =================
PC pc_inst (
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc(pc)
);

assign pc_plus4 = pc + 4;

// ================= IMEM =================
IMEM imem_inst (
    .addr(pc),
    .instr(instr)
);

// ================= CONTROL =================
ControlUnit cu (
    .instr(instr),
    .BrEq(BrEq),
    .BrLT(BrLT),
    .PCSel(PCSel),
    .ImmSel(ImmSel),
    .RegWEn(RegWEn),
    .BrUn(BrUn),
    .BSel(BSel),
    .ASel(ASel),
    .ALUSel(ALUSel),
    .MemRW(MemRW),
    .WBSel(WBSel)
);

// ================= REGFILE =================
RegFile rf (
    .clk(clk),
    .rs1(instr[19:15]),
    .rs2(instr[24:20]),
    .rd(instr[11:7]),
    .wd(wb_data),
    .RegWrite(RegWEn),
    .rd1(reg_rs1),
    .rd2(reg_rs2)
);

// ================= IMMGEN =================
ImmGen immgen (
    .instr(instr),
    .ImmSel(ImmSel),
    .imm(imm)
);

// ================= BRANCH COMP =================
BranchComp bc (
    .A(reg_rs1),
    .B(reg_rs2),
    .BrUn(BrUn),
    .BrEq(BrEq),
    .BrLT(BrLT)
);

// ================= ALU INPUT MUX =================
assign alu_in1 = (ASel) ? pc : reg_rs1;
assign alu_in2 = (BSel) ? imm : reg_rs2;

// ================= ALU =================
ALU alu (
    .A(alu_in1),
    .B(alu_in2),
    .ALU_Sel(ALUSel),
    .ALU_Out(alu_out)
);

// ================= DMEM =================
DMEM dmem (
    .clk(clk),
    .addr(alu_out),
    .DataW(reg_rs2),
    .MemRW(MemRW),
    .DataR(dmem_data)
);

// ================= WRITE BACK =================
assign wb_data =
    (WBSel == 2'b00) ? dmem_data :
    (WBSel == 2'b01) ? alu_out   :
                       pc_plus4;

// ================= NEXT PC =================
assign next_pc = (PCSel) ? alu_out : pc_plus4;

endmodule