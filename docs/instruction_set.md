# Instruction Set

This document describes the instruction subset supported by the **RV32I Pipelined RISC-V Processor**.

The processor is based on the RV32I base integer instruction set, but only a selected subset of instructions is implemented. The selected instructions are enough to demonstrate arithmetic operations, memory access, branches, jumps, pipelining, forwarding, stalling, flushing, and program-level execution.

---

## Supported Instruction Categories

| Category   | Instructions                            |
| ---------- | --------------------------------------- |
| R-type ALU | `add`, `sub`, `and`, `or`, `xor`, `slt` |
| I-type ALU | `addi`, `andi`, `ori`                   |
| Load       | `lw`                                    |
| Store      | `sw`                                    |
| Branch     | `beq`, `bne`                            |
| Jump       | `jal`                                   |
| NOP        | `addi x0, x0, 0`                        |

---

## Instruction Width

All instructions are 32 bits wide.

```text
instruction[31:0]
```

The program counter is byte-addressed, so the next sequential instruction is at:

```text
PC + 4
```

Instruction memory is internally word-indexed using:

```verilog
memory[pc[31:2]]
```

---

## Register Convention

The processor contains 32 integer registers.

```text
x0  to x31
```

Register `x0` is hardwired to zero.

```text
x0 = 0
```

Writes to `x0` are ignored.

Example:

```asm
addi x0, x0, 5
```

This instruction does not change `x0`.

---

## Instruction Formats

The implemented instructions use the following RV32I instruction formats:

| Format | Used By                                 |
| ------ | --------------------------------------- |
| R-type | `add`, `sub`, `and`, `or`, `xor`, `slt` |
| I-type | `addi`, `andi`, `ori`, `lw`             |
| S-type | `sw`                                    |
| B-type | `beq`, `bne`                            |
| J-type | `jal`                                   |

---

## R-Type Format

R-type instructions operate on two source registers and write the result to one destination register.

```text
31        25 24    20 19    15 14    12 11     7 6      0
+-----------+--------+--------+--------+--------+--------+
|  funct7   |  rs2   |  rs1   | funct3 |   rd   | opcode |
+-----------+--------+--------+--------+--------+--------+
```

### Supported R-Type Instructions

| Instruction        | Operation                    | opcode    | funct3    | funct7    |           |
| ------------------ | ---------------------------- | --------- | --------- | --------- | --------- |
| `add rd, rs1, rs2` | `rd = rs1 + rs2`             | `0110011` | `000`     | `0000000` |           |
| `sub rd, rs1, rs2` | `rd = rs1 - rs2`             | `0110011` | `000`     | `0100000` |           |
| `and rd, rs1, rs2` | `rd = rs1 & rs2`             | `0110011` | `111`     | `0000000` |           |
| `or rd, rs1, rs2`  | `rd = rs1                    | rs2`      | `0110011` | `110`     | `0000000` |
| `xor rd, rs1, rs2` | `rd = rs1 ^ rs2`             | `0110011` | `100`     | `0000000` |           |
| `slt rd, rs1, rs2` | `rd = 1 if rs1 < rs2 else 0` | `0110011` | `010`     | `0000000` |           |

For `slt`, the comparison is signed.

### Example

```asm
add x3, x1, x2
```

Meaning:

```text
x3 = x1 + x2
```

Machine code:

```text
0x002081B3
```

---

## I-Type Format

I-type instructions use one source register, one destination register, and a 12-bit immediate.

```text
31        20 19    15 14    12 11     7 6      0
+-----------+--------+--------+--------+--------+
| imm[11:0] |  rs1   | funct3 |   rd   | opcode |
+-----------+--------+--------+--------+--------+
```

The immediate is sign-extended to 32 bits.

```verilog
imm_i = {{20{inst[31]}}, inst[31:20]};
```

---

## I-Type ALU Instructions

| Instruction         | Operation        | opcode    | funct3    |       |
| ------------------- | ---------------- | --------- | --------- | ----- |
| `addi rd, rs1, imm` | `rd = rs1 + imm` | `0010011` | `000`     |       |
| `andi rd, rs1, imm` | `rd = rs1 & imm` | `0010011` | `111`     |       |
| `ori rd, rs1, imm`  | `rd = rs1        | imm`      | `0010011` | `110` |

### Example

```asm
addi x1, x0, 10
```

Meaning:

```text
x1 = 0 + 10
```

Machine code:

```text
0x00A00093
```

---

## Load Instruction

The processor supports word load using `lw`.

| Instruction       | Operation                | opcode    | funct3 |
| ----------------- | ------------------------ | --------- | ------ |
| `lw rd, imm(rs1)` | `rd = memory[rs1 + imm]` | `0000011` | `010`  |

The effective address is calculated in the EX stage:

```text
address = rs1 + sign_extended_immediate
```

The memory data is read in the MEM stage and written back in the WB stage.

### Example

```asm
lw x2, 0(x1)
```

Meaning:

```text
x2 = memory[x1 + 0]
```

Machine code:

```text
0x0000A103
```

---

## S-Type Format

S-type instructions are used for store operations.

```text
31        25 24    20 19    15 14    12 11      7 6      0
+-----------+--------+--------+--------+---------+--------+
| imm[11:5] |  rs2   |  rs1   | funct3 | imm[4:0]| opcode |
+-----------+--------+--------+--------+---------+--------+
```

The immediate is formed by combining two fields from the instruction.

```verilog
imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
```

---

## Store Instruction

The processor supports word store using `sw`.

| Instruction        | Operation                 | opcode    | funct3 |
| ------------------ | ------------------------- | --------- | ------ |
| `sw rs2, imm(rs1)` | `memory[rs1 + imm] = rs2` | `0100011` | `010`  |

The effective address is calculated in the EX stage.

The data from `rs2` is written to data memory in the MEM stage.

### Example

```asm
sw x3, 0(x1)
```

Meaning:

```text
memory[x1 + 0] = x3
```

Machine code:

```text
0x0030A023
```

---

## B-Type Format

B-type instructions are used for conditional branches.

```text
31       30     25 24    20 19    15 14    12 11      8 7       6      0
+----------+--------+--------+--------+--------+---------+--------+--------+
| imm[12]  |imm[10:5]| rs2   |  rs1   | funct3 | imm[4:1]|imm[11] | opcode |
+----------+--------+--------+--------+--------+---------+--------+--------+
```

The branch immediate is reconstructed as:

```verilog
imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
```

The least significant bit is always zero because branch targets are aligned.

---

## Branch Instructions

| Instruction         | Condition              | opcode    | funct3 |
| ------------------- | ---------------------- | --------- | ------ |
| `beq rs1, rs2, imm` | branch if `rs1 == rs2` | `1100011` | `000`  |
| `bne rs1, rs2, imm` | branch if `rs1 != rs2` | `1100011` | `001`  |

The branch target is calculated as:

```text
branch_target = PC + branch_immediate
```

### Example

```asm
beq x1, x2, label
```

Meaning:

```text
if x1 == x2:
    PC = label
else:
    PC = PC + 4
```

---

## J-Type Format

J-type instructions are used for jump operations.

```text
31       30      21 20       19      12 11     7 6      0
+----------+---------+----------+---------+--------+--------+
| imm[20]  |imm[10:1]| imm[11]  |imm[19:12]|  rd   | opcode |
+----------+---------+----------+---------+--------+--------+
```

The jump immediate is reconstructed as:

```verilog
imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
```

The least significant bit is always zero because jump targets are aligned.

---

## Jump Instruction

| Instruction   | Operation                      | opcode    |
| ------------- | ------------------------------ | --------- |
| `jal rd, imm` | `rd = PC + 4`, `PC = PC + imm` | `1101111` |

The `jal` instruction stores the return address in `rd`.

```text
rd = PC + 4
```

Then the PC is redirected to the jump target.

```text
PC = PC + immediate
```

### Example

```asm
jal x1, label
```

Meaning:

```text
x1 = PC + 4
PC = label
```

If the return address is not needed, `x0` can be used as the destination register.

```asm
jal x0, label
```

---

## NOP Instruction

The processor uses the standard RISC-V NOP instruction:

```asm
addi x0, x0, 0
```

Machine code:

```text
0x00000013
```

Since `x0` is always zero and writes to `x0` are ignored, this instruction does not change the processor state.

NOPs are useful in simple tests, waveform debugging, and manual hazard isolation.

---

## Opcode Summary

| Instruction Type | opcode    | Hex    |
| ---------------- | --------- | ------ |
| R-type ALU       | `0110011` | `0x33` |
| I-type ALU       | `0010011` | `0x13` |
| Load             | `0000011` | `0x03` |
| Store            | `0100011` | `0x23` |
| Branch           | `1100011` | `0x63` |
| JAL              | `1101111` | `0x6F` |

---

## Funct3 Summary

| Instruction | funct3 |
| ----------- | ------ |
| `add`       | `000`  |
| `sub`       | `000`  |
| `and`       | `111`  |
| `or`        | `110`  |
| `xor`       | `100`  |
| `slt`       | `010`  |
| `addi`      | `000`  |
| `andi`      | `111`  |
| `ori`       | `110`  |
| `lw`        | `010`  |
| `sw`        | `010`  |
| `beq`       | `000`  |
| `bne`       | `001`  |

---

## Funct7 Summary

| Instruction | funct7    |
| ----------- | --------- |
| `add`       | `0000000` |
| `sub`       | `0100000` |
| `and`       | `0000000` |
| `or`        | `0000000` |
| `xor`       | `0000000` |
| `slt`       | `0000000` |

Only R-type instructions use `funct7` in this processor.

---

## Immediate Summary

| Type   | Immediate Source                                       |
| ------ | ------------------------------------------------------ |
| I-type | `inst[31:20]`                                          |
| S-type | `{inst[31:25], inst[11:7]}`                            |
| B-type | `{inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}`   |
| J-type | `{inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}` |

All immediates are sign-extended to 32 bits.

---

## Memory Access Instructions

Only word-level memory operations are implemented.

| Instruction | Access Size           | Supported |
| ----------- | --------------------- | --------- |
| `lw`        | 32-bit word           | Yes       |
| `sw`        | 32-bit word           | Yes       |
| `lb`        | 8-bit byte            | No        |
| `lh`        | 16-bit halfword       | No        |
| `lbu`       | unsigned byte         | No        |
| `lhu`       | unsigned halfword     | No        |
| `sb`        | 8-bit byte store      | No        |
| `sh`        | 16-bit halfword store | No        |

The data memory uses word indexing:

```verilog
memory[addr[31:2]]
```

---

## Unsupported RV32I Instructions

The following RV32I instructions are not implemented in this version:

* `lui`
* `auipc`
* `jalr`
* `lb`
* `lh`
* `lbu`
* `lhu`
* `sb`
* `sh`
* `slti`
* `sltiu`
* `xori`
* `slli`
* `srli`
* `srai`
* `sll`
* `sltu`
* `srl`
* `sra`
* `blt`
* `bge`
* `bltu`
* `bgeu`
* `fence`
* `ecall`
* `ebreak`
* CSR instructions

These instructions can be added later by extending the control unit, ALU control, immediate generator, memory access logic, and verification programs.

---

## `.mem` File Format

Programs are stored as hexadecimal machine code words.

Each line contains one 32-bit instruction.

Example:

```text
00a00093
01400113
002081b3
00000013
```

This corresponds to:

```asm
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
nop
```

The instruction memory loads these values during simulation using `$readmemh`.

---

## Example Program

Example program to add two numbers:

```asm
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
nop
```

Expected result:

```text
x1 = 10
x2 = 20
x3 = 30
```

Machine code:

```text
00a00093
01400113
002081b3
00000013
```

---

## Summary

This processor implements a focused RV32I subset suitable for demonstrating a 5-stage pipelined datapath.

The supported instructions cover:

```text
ALU operations
Immediate operations
Load/store memory access
Conditional branches
Unconditional jumps
NOP execution
```

This subset is small enough to keep the RTL understandable, but complete enough to run useful programs such as Fibonacci, array sum, GCD, maximum array element, and forwarding stress tests.
