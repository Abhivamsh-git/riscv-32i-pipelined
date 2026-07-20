# 5-Stage Pipelined RISC-V (RV32I) Processor Core

A synthesizable, 5-stage pipelined RISC-V processor core implementing the base integer instruction set (RV32I). The design features robust hardware hazard resolution, dynamic branch prediction, and has been verified via simulation executing a Fibonacci sequence program loaded in instruction memory.

---

## 🚀 Key Features & Architecture

The processor implements the classic 5-stage RISC-V pipeline model: **Fetch (IF) ➔ Decode (ID) ➔ Execute (EX) ➔ Memory (MEM) ➔ Write-Back (WB)**.

### ⚡ Architectural Highlights
* **Early Branch Resolution:** Conditional branches are evaluated in the **Decode (ID)** stage to minimize branch penalties to a single cycle.
* **Hazard Detection & Forwarding Unit:** 
  * Full execution-bypass forwarding (EX-to-EX, MEM-to-EX) to eliminate data stalls for R-type and I-type dependencies.
  * Internal Register File Bypassing (Write-Back-to-Decode) ensuring zero-cycle stalls for back-to-back dependency shifts.
  * Load-Use Hazard hardware stall engine that injects single-cycle `NOP` bubbles automatically.
* **Byte-Addressable Data Memory:** Built-in hardware decoding for memory sub-word operations (`LB`, `LH`, `LW`, `LBU`, `LHU`).

---

## 📂 Project Structure

```text
riscv-32i-pipelined/
├── README.md
├── src/
│   ├── riscv_pipeline.v
│   ├── alu.v
│   ├── control_unit.v
│   ├── imm_gen.v
│   ├── reg_file.v
│   ├── pc.v
│   ├── data_mem.v
│   └── instruction_mem.v
└── sim/
    └── riscv_pipeline_tb.v
