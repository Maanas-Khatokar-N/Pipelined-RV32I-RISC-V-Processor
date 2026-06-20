<div align="center">

# 5-stage Pipelined RV32I RISC-V Processor

</div>

---

## Overview

This project is a Verilog implementation of an **RV32I RISC-V processor**, featuring both a **single-cycle design** and a **5-stage pipelined design**.

The pipelined processor is organized into IF, ID, EX, MEM, and WB stages with dedicated pipeline registers. It supports forwarding, load-use hazard stalling, branch/jump flushing, ALU control, register file operations, and instruction/data memory access.

The design is verified using module-level testbenches, processor-level tests, hazard-specific tests, and complete `.mem` program simulations.

---

## Architecture

<div align="center">

### 5-Stage Pipeline Datapath

<table>
<tr>
<td align="center">🟦<br><b>IF</b><br><sub>Instruction Fetch</sub></td>
<td align="center">→</td>
<td align="center">🟩<br><b>ID</b><br><sub>Instruction Decode</sub></td>
<td align="center">→</td>
<td align="center">🟨<br><b>EX</b><br><sub>Execute</sub></td>
<td align="center">→</td>
<td align="center">🟧<br><b>MEM</b><br><sub>Memory Access</sub></td>
<td align="center">→</td>
<td align="center">🟥<br><b>WB</b><br><sub>Write Back</sub></td>
</tr>
</table>

</div>

```mermaid
flowchart LR
    PC[("🎯 Program Counter")] --> IF["🟦 IF Stage"]
    IF --> IFID[/"IF/ID Register"/]
    IFID --> ID["🟩 ID Stage"]
    ID --> IDEX[/"ID/EX Register"/]
    IDEX --> EX["🟨 EX Stage"]
    EX --> EXMEM[/"EX/MEM Register"/]
    EXMEM --> MEM["🟧 MEM Stage"]
    MEM --> MEMWB[/"MEM/WB Register"/]
    MEMWB --> WB["🟥 WB Stage"]
    WB -. "Register Write Back" .-> ID

    style PC fill:#1e1e2e,stroke:#89b4fa,stroke-width:2px,color:#fff
    style IF fill:#1e3a5f,stroke:#74c7ec,stroke-width:2px,color:#fff
    style ID fill:#1e4f3a,stroke:#a6e3a1,stroke-width:2px,color:#fff
    style EX fill:#5f4f1e,stroke:#f9e2af,stroke-width:2px,color:#fff
    style MEM fill:#5f3a1e,stroke:#fab387,stroke-width:2px,color:#fff
    style WB fill:#5f1e2a,stroke:#f38ba8,stroke-width:2px,color:#fff
```

<div align="center">

<sub>📌 *Add architecture / datapath image here later — suggested path: `docs/images/pipeline_datapath.png`*</sub>

</div>

<br/>

<div align="center">

| Stage | Role |
|:---:|:---|
| 🟦 **IF** | Fetches instruction from instruction memory and computes the next PC |
| 🟩 **ID** | Decodes instruction, reads registers, generates immediates and control signals |
| 🟨 **EX** | Performs ALU operations, branch comparison, target calculation, and forwarding selection |
| 🟧 **MEM** | Handles load and store operations through data memory |
| 🟥 **WB** | Writes ALU result, memory data, or return address back to the register file |

</div>

---

## Supported Instruction Subset

<div align="center">

| Type   | Instructions                            |
| ------ | --------------------------------------- |
| R-Type | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT` |
| I-Type | `ADDI`, `ORI`, `ANDI`, `LW`             |
| S-Type | `SW`                                    |
| B-Type | `BEQ`, `BNE`                            |
| J-Type | `JAL`                                   |

</div>

---

## Implementation Highlights

- Single-cycle RV32I processor
- 5-stage pipelined RV32I processor
- Modular IF, ID, EX, MEM, and WB stages
- Dedicated pipeline registers
- ALU, register file, and immediate generator
- Instruction and data memory subsystem
- Data forwarding and load-use hazard handling
- Branch and jump flushing
- Program-level verification using `.mem` files
---

## 📂 Repository Structure

```text
Pipelined-RV32I-RISC-V-Processor/
│
├── programs/
│   ├── array_sum.mem
│   ├── fibonacci.mem
│   ├── forwarding_stress.mem
│   ├── gcd_subtraction.mem
│   └── max_array.mem
│
├── rtl/
│   │
│   ├── core/
│   │   ├── adder.v
│   │   ├── alu.v
│   │   ├── alu_control.v
│   │   ├── control_unit.v
│   │   ├── data_memory.v
│   │   ├── imm_gen.v
│   │   ├── instruction_memory.v
│   │   ├── mux2_32.v
│   │   ├── mux3_32.v
│   │   ├── program_counter.v
│   │   ├── register_file.v
│   │   └── single_cycled_top.v
│   │
│   └── pipeline/
│       ├── pipelined_top.v
│       │
│       ├── stages/
│       │   ├── if_stage.v
│       │   ├── id_stage.v
│       │   ├── ex_stage.v
│       │   ├── mem_stage.v
│       │   └── wb_stage.v
│       │
│       ├── registers/
│       │   ├── if_id.v
│       │   ├── id_ex.v
│       │   ├── ex_mem.v
│       │   └── mem_wb.v
│       │
│       └── hazard/
│           ├── forwarding_unit.v
│           └── load_use_hazard_unit.v
│
├── tb/
│   │
│   ├── core/
│   │   ├── alu_tb.v
│   │   ├── control_unit_tb.v
│   │   ├── data_memory_tb.v
│   │   ├── imm_gen_tb.v
│   │   ├── instruction_memory_tb.v
│   │   ├── pipelined_top_tb.v
│   │   ├── pipelined_top_forwarding_tb.v
│   │   ├── pipelined_top_load_use_hazard_tb.v
│   │   ├── program_counter_tb.v
│   │   ├── register_file_tb.v
│   │   └── single_cycle_top_tb.v
│   │
│   └── programs/
│       ├── array_sum_tb.v
│       ├── fibonacci_pipelined_tb.v
│       ├── fibonacci_single_cycled_tb.v
│       ├── forwarding_stress_tb.v
│       ├── gcd_subtraction_tb.v
│       └── max_array_tb.v
│
├── sim/
│   └── scripts/
│       ├── run_array_sum.sh
│       ├── run_fibonacci.sh
│       ├── run_forwarding_stress.sh
│       ├── run_gcd_subtraction.sh
│       └── run_max_array.sh
│
├── .gitignore
└── README.md
```

---

## RTL Organization

The RTL is divided into reusable core blocks and pipelined processor blocks.

<div align="center">

| Folder | Description |
|:---|:---|
| 📁 `rtl/core/` | Common datapath and control modules used by the processor |
| 📁 `rtl/pipeline/stages/` | The five pipeline stage modules |
| 📁 `rtl/pipeline/registers/` | IF/ID, ID/EX, EX/MEM, and MEM/WB pipeline registers |
| 📁 `rtl/pipeline/hazard/` | Forwarding and load-use hazard detection units |
| 📄 `rtl/pipeline/pipelined_top.v` | Top-level pipelined processor integration |

</div>


---

## 📚 Documentation

> [!NOTE]
> Detailed design explanations are available in the `docs/` folder.

<div align="center">

| Document | Purpose |
|:---|:---|
| 📘 `docs/architecture.md` | Overall processor architecture and top-level datapath |
| 📗 `docs/instruction_set.md` | Supported RV32I subset, instruction formats, opcode/funct mapping |
| 📙 `docs/pipeline_design.md` | Explanation of IF, ID, EX, MEM, WB stages and pipeline registers |
| 📕 `docs/hazard_forwarding.md` | Forwarding paths, load-use stall logic, branch/jump flushing |
| 📔 `docs/verification.md` | Testbench strategy, program tests, expected outputs, waveform debugging |
| 🖼️ `docs/images/` | Datapath diagrams, pipeline diagrams, screenshots, and waveform images |

</div>

---

## Datapath Summary

### Core Components

| Module                   | Description                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| `program_counter.v`      | Holds the current instruction address                              |
| `instruction_memory.v`   | Stores program instructions loaded from `.mem` files               |
| `register_file.v`        | 32-register file with two read ports and one write port            |
| `imm_gen.v`              | Generates sign-extended immediates                                 |
| `control_unit.v`         | Generates main control signals from opcode                         |
| `alu_control.v`          | Generates ALU control signal using `ALUOp`, `funct3`, and `funct7` |
| `alu.v`                  | Performs arithmetic, logical, and comparison operations            |
| `data_memory.v`          | Handles word-level load and store operations                       |
| `mux2_32.v`, `mux3_32.v` | Datapath selection multiplexers                                    |

### Pipeline Components

| Module                   | Description                                            |
| ------------------------ | ------------------------------------------------------ |
| `if_stage.v`             | Fetches instruction and updates PC                     |
| `id_stage.v`             | Decodes instruction and reads register operands        |
| `ex_stage.v`             | Executes ALU operation and computes branch/jump target |
| `mem_stage.v`            | Accesses data memory                                   |
| `wb_stage.v`             | Selects final write-back data                          |
| `if_id.v`                | Pipeline register between IF and ID                    |
| `id_ex.v`                | Pipeline register between ID and EX                    |
| `ex_mem.v`               | Pipeline register between EX and MEM                   |
| `mem_wb.v`               | Pipeline register between MEM and WB                   |
| `forwarding_unit.v`      | Resolves ALU-to-ALU RAW hazards                        |
| `load_use_hazard_unit.v` | Detects load-use hazards and inserts one-cycle stall   |

---


## 🚧 Pipeline Hazard Handling

A pipelined processor must handle cases where instructions overlap and depend on each other. This design includes both **forwarding** and **stalling** mechanisms.

### 🔁 Data Forwarding

Forwarding is used when an instruction needs a value that has already been computed by an older instruction but has not yet reached the register file.

```text
EX/MEM  →  EX
MEM/WB  →  EX
WB      →  ID
```

This allows back-to-back dependent arithmetic instructions to execute correctly without unnecessary stalls.

### ⏸️ Load-Use Hazard Stall

A load-use hazard occurs when an instruction immediately after `LW` depends on the loaded data.

```asm
lw   x1, 0(x2)
add  x3, x1, x4
```

Since load data becomes available only after the memory stage, the processor inserts one bubble by holding the PC and IF/ID register while flushing the ID/EX control signals.

### 🌊 Branch and Jump Flush

For `BEQ`, `BNE`, and `JAL`, the processor flushes wrong-path instructions after a taken branch or jump. This prevents incorrectly fetched instructions from updating architectural state.

---

## 💾 Memory Model

The processor uses separate instruction and data memories.

| Memory             | Usage                                                         |
| ------------------ | ------------------------------------------------------------- |
| Instruction Memory | Stores 32-bit instructions loaded from `.mem` files           |
| Data Memory        | Stores 32-bit data values used by load and store instructions |

Data memory is word-indexed internally using:

```verilog
memory[addr[31:2]]
```

So a byte address maps to a word location as follows:

```text
Address 40  -> memory[10]
Address 100 -> memory[25]
Address 104 -> memory[26]
```

<sub>This is useful while writing program testbenches and checking final memory outputs.

---


## ✅ Verification

The processor is verified through individual module tests, top-level processor tests, hazard-specific tests, and full program execution using `.mem` files.

| Verification Area | Test Coverage                                                                          | Status |
| ----------------- | -------------------------------------------------------------------------------------- | ------ |
| Core modules      | ALU, control unit, register file, immediate generator, instruction memory, data memory | PASS   |
| Single-cycle CPU  | End-to-end instruction execution on the single-cycle processor                         | PASS   |
| Pipelined CPU     | Stage connection, pipeline register propagation, PC update, and write-back correctness | PASS   |
| Forwarding        | Back-to-back RAW dependencies and forwarding paths                                     | PASS   |
| Load-use hazard   | Stall and bubble insertion after `LW`                                                  | PASS   |
| Branch / Jump     | Taken branch and jump flushing                                                         | PASS   |
| Program execution | Complete `.mem` programs running on the pipelined processor                            | PASS   |

<div align="center">

<!-- 
> Add verification output screenshot here later
> Suggested path: `docs/images/test_results.png`
-->

</div>

---

## Program Tests

<div align="center">

| Program                 | What it verifies                                          |
| ----------------------- | --------------------------------------------------------- |
| `fibonacci.mem`         | Loop execution, arithmetic, memory access, branch control |
| `array_sum.mem`         | Array traversal, repeated loads, accumulation             |
| `gcd_subtraction.mem`   | Branch-heavy loop execution                               |
| `max_array.mem`         | Comparisons, memory reads, conditional updates            |
| `forwarding_stress.mem` | Back-to-back dependencies and forwarding paths            |

</div>

---

## 🚀 Running the Project

### Requirements

| Tool           | Purpose                             |
| -------------- | ----------------------------------- |
| Icarus Verilog | Compile and run Verilog simulations |
| GTKWave        | View generated VCD waveforms        |
| Bash           | Run simulation scripts              |

Install on Ubuntu or WSL:

```bash
sudo apt update
sudo apt install iverilog gtkwave
```

Clone the repository:

```bash
git clone https://github.com/Maanas-Khatokar-N/Pipelined-RV32I-RISC-V-Processor.git
cd Pipelined-RV32I-RISC-V-Processor
```

Give execute permission to the scripts:

```bash
chmod +x sim/scripts/*.sh
```

### ▶️ Run Program Tests

| Test               | Command                                  |
| ------------------ | ---------------------------------------- |
| Fibonacci          | `./sim/scripts/run_fibonacci.sh`         |
| Array Sum          | `./sim/scripts/run_array_sum.sh`         |
| GCD by Subtraction | `./sim/scripts/run_gcd_subtraction.sh`   |
| Maximum in Array   | `./sim/scripts/run_max_array.sh`         |
| Forwarding Stress  | `./sim/scripts/run_forwarding_stress.sh` |

Each script compiles the RTL, runs the corresponding testbench, and prints the verification result in the terminal.

<details>
<summary><b>🧫 Run Core Testbenches Manually</b></summary>
<br/>

To run a testbench from `tb/core/`, use:

```bash
iverilog -o sim/build/<test_name>.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/core/<testbench_name>.v

vvp sim/build/<test_name>.vvp
```

</details>

<details>
<summary><b>🧫 Run Any Program Testbench Manually</b></summary>
<br/>

To run any testbench from `tb/programs/`, use:

```bash
iverilog -o sim/build/<program_test>.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/<program_testbench>.v

vvp sim/build/<program_test>.vvp
```

</details>



<div align="center">

<!-- 
> Add waveform screenshot here later
> Suggested path: `docs/images/waveforms/pipeline_waveform.png`
-->

</div>

---


## Future Improvements

| Improvement                                 | Purpose                                                 |
| ------------------------------------------- | ------------------------------------------------------- |
| Add remaining RV32I instructions            | Increase ISA completeness                               |
| Add RV32M multiplication/division extension | Support hardware multiply and divide operations         |
| Add `JALR` support                          | Improve control-flow capability                         |
| Add shift instructions                      | Support more arithmetic/logical programs                |
| Add branch prediction                       | Reduce control hazard penalties and improve performance |

---

<div align="center">

### Built to see how every instruction moves through the pipeline, one clock cycle at a time.

</div>
