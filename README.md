# RISC-V Pipeline Processor (RV32I)

Thiết kế bộ xử lý RISC-V 32-bit, bao gồm hai phiên bản:
- **Single-cycle** (`top_level.v`) — mỗi lệnh hoàn thành trong 1 clock cycle
- **5-stage Pipeline** (`top_level_pipeline.v`) — IF → ID → EX → MEM → WB, không có Forwarding Unit, dùng stall để xử lý hazard

---

## Cấu trúc thư mục

```
RISC-V/
├── rtl/                        # Mã nguồn RTL (Verilog)
│   ├── top_level.v             # CPU đơn chu kỳ (single-cycle)
│   ├── top_level_pipeline.v    # CPU pipeline 5 tầng
│   │
│   ├── -- Các module dùng chung --
│   ├── alu.v                   # Arithmetic Logic Unit
│   ├── branch_comp.v           # Branch Comparator (BrEq, BrLT)
│   ├── control_unit.v          # Control Unit (pipeline + single-cycle)
│   ├── dmem.v                  # Data Memory (DMEM)
│   ├── imm_gen.v               # Immediate Generator
│   ├── instruction_memory.v    # Instruction Memory (IMEM)
│   ├── pc.v                    # Program Counter (dùng cho single-cycle)
│   ├── register_file.v         # Register File (x0–x31)
│   │
│   └── -- Pipeline registers --
│       ├── if_id.v             # IF/ID register
│       ├── id_ex.v             # ID/EX register
│       ├── ex_mem.v            # EX/MEM register
│       ├── mem_wb.v            # MEM/WB register
│       └── hazard_unit.v       # Hazard Detection Unit
│
├── tb/                         # Testbenches
│   ├── tb_pipeline.v           # Testbench cho pipeline
│   ├── top_level_tb.v          # Testbench cho single-cycle
│   ├── alu_tb.v
│   ├── branch_comp_tb.v
│   ├── control_unit_tb.v
│   ├── dmem_tb.v
│   ├── imm_gen_tb.v
│   ├── instruction_memory_tb.v
│   ├── pc_tb.v
│   └── register_file_tb.v
│
├── sim/                        # File project ModelSim
│   └── RISCV.mpf
│
└── doc/
    └── reference-card.pdf      # RISC-V ISA reference card
```

---

## Kiến trúc Pipeline

### Sơ đồ tổng quan

```
        ┌──────┐   ┌───────┐   ┌──────┐   ┌─────────┐   ┌──────┐
  PC ──►│  IF  ├──►│  ID   ├──►│  EX  ├──►│   MEM   ├──►│  WB  │
        └──────┘   └───────┘   └──────┘   └─────────┘   └──────┘
           │       IF/ID reg   ID/EX reg   EX/MEM reg   MEM/WB reg
           │
           ▼
         IMEM          RegFile    ALU       DMEM       RegFile
                       ImmGen     BrComp               (write)
                       CtrlUnit
                                    │
                              ┌─────▼──────┐
                              │ HazardUnit │ ← stall
                              └────────────┘
```

### Các tầng pipeline

| Tầng | Viết tắt | Công việc |
|------|----------|-----------|
| Instruction Fetch | IF | Đọc lệnh từ IMEM theo PC |
| Instruction Decode | ID | Giải mã lệnh, đọc register, tính immediate, sinh control signals |
| Execute | EX | ALU tính toán, Branch Comparator quyết định nhảy |
| Memory Access | MEM | Đọc/ghi DMEM |
| Write Back | WB | Ghi kết quả vào register file |

---

## Xử lý Hazard

### Không dùng Forwarding — chỉ dùng Stall

Khi không có forwarding, kết quả được ghi vào register file ở cuối tầng WB (posedge clock). Instruction tiếp theo đọc register ở tầng ID (combinational). Do đó cần **3 stall cycles** cho mỗi RAW hazard:

```
Cycle:    1    2    3    4    5    6    7
ADDI x1: IF   ID   EX   MEM  WB
ADD x3:       IF   ID   ID   ID   EX   ...
                   ↑stall↑stall↑stall
                   (rd_EX) (rd_MEM) (rd_WB)
```

Hazard Unit kiểm tra cả 3 tầng EX, MEM, WB:

```verilog
stall = (RegWrite_EX  && rd_EX  != 0 && (rd_EX  == rs1_ID || rd_EX  == rs2_ID))
     || (RegWrite_MEM && rd_MEM != 0 && (rd_MEM == rs1_ID || rd_MEM == rs2_ID))
     || (RegWrite_WB  && rd_WB  != 0 && (rd_WB  == rs1_ID || rd_WB  == rs2_ID));
```

Khi `stall = 1`:
- PC bị giữ nguyên (frozen)
- IF/ID register bị giữ nguyên (frozen)
- ID/EX register inject **NOP bubble** (toàn bộ control signals = 0)

### Branch Resolution

Branch được quyết định ở tầng **EX** (sử dụng Branch Comparator trên `regA_EX`, `regB_EX`). Khi branch taken:

- Flush **IF/ID** (inject NOP — lệnh tại PC+4 bị loại bỏ)
- Flush **ID/EX** (inject NOP — lệnh tại PC+8 bị loại bỏ)
- PC nhảy đến `alu_out_EX` (= PC_EX + imm_EX, tính bởi ALU)

```
Cycle:    1    2    3    4    5
BEQ:      IF   ID   EX   MEM  WB
PC+4:          IF   ID──►NOP (flush)
PC+8:               IF──►NOP (flush)
Target:                  IF   ...
```

---

## Tập lệnh hỗ trợ (RV32I subset)

| Nhóm | Lệnh |
|------|------|
| R-type | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLTU`, `SLL`, `SRL`, `SRA` |
| I-type ALU | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` |
| Load | `LW` |
| Store | `SW` |
| Branch | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Jump | `JAL`, `JALR` |

---

## Mô tả các module chính

### `control_unit.v`
Chứa 2 module:
- `control_unit` — dành cho **pipeline**: không nhận BrEq/BrLT (branch quyết định ở EX), output gồm `RegWrite`, `MemRW`, `ResultSrc`, `ALUControl`, `ALUSrc`, `ASel`, `Branch`, `Jump`, `BrUn`, `ImmSel`
- `ControlUnit` — dành cho **single-cycle**: nhận BrEq/BrLT từ Branch Comparator, output `PCSel` ngay

### `hazard_unit.v`
Phát hiện RAW hazard bằng cách so sánh `rs1_ID`, `rs2_ID` với `rd` ở cả 3 tầng EX/MEM/WB.

### `id_ex.v`
Pipeline register ID/EX. Khi `rst=1`, `flush=1`, hoặc `stall=1`: inject NOP bubble (zero toàn bộ control signals).

### `imm_gen.v` (`ImmGen`)
Hỗ trợ 4 kiểu immediate: I-type, S-type, B-type, J-type.

### `register_file.v` (`RegFile`)
- Đọc: combinational, 2 cổng đọc
- Ghi: sequential (posedge clock)
- `x0` luôn trả về 0, không cho phép ghi vào `x0`

---

## Mô phỏng với ModelSim

### Mở project
```
File → Open Project → sim/RISCV.mpf
```

### Chạy testbench pipeline

```tcl
vlog rtl/alu.v rtl/branch_comp.v rtl/control_unit.v rtl/dmem.v
vlog rtl/imm_gen.v rtl/instruction_memory.v rtl/register_file.v
vlog rtl/if_id.v rtl/id_ex.v rtl/ex_mem.v rtl/mem_wb.v rtl/hazard_unit.v
vlog rtl/top_level_pipeline.v
vlog tb/tb_pipeline.v
vsim pipeline_tb
run -all
```

### Kết quả mong đợi (testbench mặc định)

```
=== Final Register State ===
x1 = 5   (addi x1, x0, 5)
x2 = 10  (addi x2, x0, 10)
x3 = 15  (add  x3, x1, x2)
x4 = 20  (add  x4, x3, x1)
x7 = 0   (flushed bởi BEQ)
x8 = 1   (addi x8, x0, 1 — branch target)
```

---

## Hạn chế & hướng mở rộng

| Hạn chế hiện tại | Hướng mở rộng |
|---|---|
| Không có Forwarding Unit → 3 stall/RAW | Thêm Forwarding Unit → giảm stall về 0–1 |
| Chỉ hỗ trợ `LW`/`SW` 32-bit | Thêm `LB`, `LH`, `LBU`, `LHU`, `SB`, `SH` |
| Chưa có `LUI`, `AUIPC` | Thêm U-type và xử lý ImmSel mới |
| IMEM/DMEM cố định 1KB | Tham số hóa kích thước memory |
| JALR không clear bit LSB | Thêm `target & ~1` theo RISC-V spec |
