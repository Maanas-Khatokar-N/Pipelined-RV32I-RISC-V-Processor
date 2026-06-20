# Hazards

This document explains the hazard handling logic used in the **RV32I Pipelined RISC-V Processor**.


```text
Forwarding paths
Load-use stall logic
Branch/jump flushing
```

---

## 1. Why Hazards Occur

In a pipelined processor, multiple instructions are active at the same time.

Example:

```asm
addi x1, x0, 10
add  x2, x1, x3
```

The second instruction needs `x1`, but the first instruction has not written `x1` back to the register file yet.

This creates a **data hazard**.

Without hazard handling, the processor may use an old value and produce an incorrect result.

---

## 2. Hazard Handling Used in This Processor

This design handles three main cases:

| Hazard Case                           | Solution                      |
| ------------------------------------- | ----------------------------- |
| ALU result needed by next instruction | Forwarding                    |
| Load result needed immediately        | One-cycle stall               |
| Branch/jump changes PC                | Flush wrong-path instructions |

> [!NOTE]
> The processor also uses WB-to-ID bypass to handle same-cycle register write/read cases.

---

# Forwarding

## 3. What Is Forwarding?

Forwarding sends a result directly from a later pipeline stage to the EX stage without waiting for the result to be written back to the register file.

This avoids unnecessary stalls for most ALU dependencies.

Example:

```asm
addi x1, x0, 10
addi x2, x1, 5
```

The value of `x1` is computed before it is written back. Forwarding allows the second instruction to use it directly.

---

## 4. Forwarding Paths

This processor uses these forwarding paths:

```text
EX/MEM -> EX
MEM/WB -> EX
```

The ALU operands in the EX stage can come from:

| Select | Source                      |
| ------ | --------------------------- |
| `00`   | Normal value from ID/EX     |
| `10`   | Forwarded value from EX/MEM |
| `01`   | Forwarded value from MEM/WB |

These select signals are usually called:

```text
ForwardA
ForwardB
```

`ForwardA` controls ALU operand A.

`ForwardB` controls ALU operand B.

---

## 5. Forwarding Unit Inputs

The forwarding unit compares source registers of the instruction in EX with destination registers of older instructions.

| Signal            | Meaning                                           |
| ----------------- | ------------------------------------------------- |
| `id_ex_rs1`       | Source register 1 of current EX-stage instruction |
| `id_ex_rs2`       | Source register 2 of current EX-stage instruction |
| `ex_mem_rd`       | Destination register of instruction in MEM stage  |
| `mem_wb_rd`       | Destination register of instruction in WB stage   |
| `ex_mem_RegWrite` | MEM-stage instruction writes to register file     |
| `mem_wb_RegWrite` | WB-stage instruction writes to register file      |

---

## 6. EX/MEM Forwarding Logic

EX/MEM forwarding is used when the previous instruction has produced a result that is needed by the current instruction.

For operand A:

```text
if ex_mem_RegWrite
and ex_mem_rd != 0
and ex_mem_rd == id_ex_rs1
then ForwardA = 10
```

For operand B:

```text
if ex_mem_RegWrite
and ex_mem_rd != 0
and ex_mem_rd == id_ex_rs2
then ForwardB = 10
```

Example:

```asm
addi x1, x0, 10
add  x2, x1, x3
```

Here, the result of `addi` can be forwarded from EX/MEM to the ALU input of `add`.

---

## 7. MEM/WB Forwarding Logic

MEM/WB forwarding is used when the required value is available in the WB stage.

For operand A:

```text
if mem_wb_RegWrite
and mem_wb_rd != 0
and mem_wb_rd == id_ex_rs1
then ForwardA = 01
```

For operand B:

```text
if mem_wb_RegWrite
and mem_wb_rd != 0
and mem_wb_rd == id_ex_rs2
then ForwardB = 01
```

Example:

```asm
addi x1, x0, 10
addi x4, x0, 5
add  x2, x1, x3
```

When `add` reaches EX, the value of `x1` may be available in MEM/WB.

---

## 8. Forwarding Priority

If both EX/MEM and MEM/WB match the same source register, EX/MEM gets priority.

Priority:

```text
1. EX/MEM forwarding
2. MEM/WB forwarding
3. Normal ID/EX value
```

Reason:

```text
EX/MEM contains the newer result
MEM/WB contains an older result
```

Example:

```asm
addi x1, x0, 5
addi x1, x1, 1
add  x2, x1, x3
```

The `add` instruction must use the result of the second `addi`, not the first one.

---

## 9. Forwarding and x0

Register `x0` is hardwired to zero.

Forwarding must not happen when the destination register is `x0`.

So every forwarding condition includes:

```text
rd != 0
```

Example:

```asm
addi x0, x0, 10
add  x2, x0, x3
```

The second instruction must still receive zero from `x0`.

---

## 10. Forwarding for Store Data

Store instructions use `rs2` as the data to be written to memory.

Example:

```asm
addi x5, x0, 77
sw   x5, 0(x1)
```

The store instruction needs the latest value of `x5`.

If the value is not yet written back, it should be forwarded and then passed as store write data to the MEM stage.

```text
forwarded rs2 value -> write_data -> data_memory
```

---

## 11. Forwarding for Branch Operands

Branch instructions compare register values.

Example:

```asm
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, target
```

If the branch comparison is done in the EX stage, the branch operands should use the same forwarded ALU operand values.

This ensures the branch decision is made using the latest register values.

---

## 12. WB-to-ID Bypass

WB-to-ID bypass handles the case where one instruction writes a register in the WB stage while another instruction reads the same register in the ID stage.

Example:

```asm
addi x1, x0, 10
nop
nop
add  x2, x1, x3
```

At one point, `addi` may be writing `x1` while `add` is reading `x1`.

Bypass logic:

```text
if wb_RegWrite
and wb_rd != 0
and wb_rd == id_rs1
then read_data1 = wb_write_data
```

For `rs2`:

```text
if wb_RegWrite
and wb_rd != 0
and wb_rd == id_rs2
then read_data2 = wb_write_data
```

This prevents the ID stage from reading an old register value.

---

# Load-Use Stall

## 13. Why Load-Use Needs a Stall

Forwarding cannot solve every case.

Example:

```asm
lw   x1, 0(x2)
addi x3, x1, 5
```

The load data is available only after the MEM stage.

The next instruction needs the value in its EX stage immediately after the load, so the data is not ready in time.

Therefore, the processor inserts one stall cycle.

---

## 14. Load-Use Hazard Detection

The hazard detection unit checks whether the instruction in EX is a load and whether the instruction in ID uses the loaded register.

Condition:

```text
if id_ex_MemRead
and id_ex_rd != 0
and (
    id_ex_rd == if_id_rs1
    or
    id_ex_rd == if_id_rs2
)
then load_use_hazard = 1
```

Here:

| Signal          | Meaning                                |
| --------------- | -------------------------------------- |
| `id_ex_MemRead` | Instruction in EX is a load            |
| `id_ex_rd`      | Destination register of load           |
| `if_id_rs1`     | Source register 1 of instruction in ID |
| `if_id_rs2`     | Source register 2 of instruction in ID |

---

## 15. Stall Action

When a load-use hazard is detected:

```text
PC is held
IF/ID register is held
ID/EX receives a bubble
```

This means:

| Action                      | Purpose                            |
| --------------------------- | ---------------------------------- |
| Hold PC                     | Prevent fetching a new instruction |
| Hold IF/ID                  | Keep dependent instruction in ID   |
| Clear ID/EX control signals | Insert bubble into EX              |

The bubble gives the load instruction enough time to get data from memory.

---

## 16. Bubble Insertion

A bubble is created by clearing control signals.

Typical control signals cleared:

```text
RegWrite = 0
MemRead  = 0
MemWrite = 0
Branch   = 0
Jump     = 0
```

Even if datapath values are present, the bubble cannot modify register file or data memory because the write/control signals are zero.

---

## 17. Load-Use Example

Program:

```asm
lw   x1, 0(x2)
addi x3, x1, 5
```

Pipeline behavior:

| Cycle | `lw` | `addi`  |
| ----- | ---- | ------- |
| 1     | IF   | -       |
| 2     | ID   | IF      |
| 3     | EX   | ID      |
| 4     | MEM  | ID held |
| 5     | WB   | EX      |
| 6     | -    | MEM     |
| 7     | -    | WB      |

At cycle 4, a bubble is inserted into EX.

After one stall, the loaded value can be forwarded to the dependent instruction.

---

# Branch and Jump Flush

## 18. Control Hazards

A control hazard occurs when a branch or jump changes the PC after younger instructions have already been fetched.

Example:

```asm
beq  x1, x2, target
addi x3, x0, 10
target:
addi x4, x0, 20
```

If the branch is taken, `addi x3, x0, 10` is a wrong-path instruction and must be removed.

---

## 19. Branch Handling

Supported branch instructions:

```asm
beq rs1, rs2, imm
bne rs1, rs2, imm
```

Branch conditions:

```text
beq: branch taken if rs1 == rs2
bne: branch taken if rs1 != rs2
```

Branch target:

```text
pc_target = pc + immediate
```

The branch decision is made in the EX stage.

---

## 20. Jump Handling

Supported jump instruction:

```asm
jal rd, imm
```

For `jal`:

```text
rd = PC + 4
PC = PC + immediate
```

Since `jal` always redirects the PC, younger instructions fetched after it must be flushed.

---

## 21. Flush Action

When a branch or jump redirects the PC:

```text
PC is updated with target address
wrong-path instructions are cleared
control signals are set to zero
```

The flushed instruction becomes a bubble.

Important signals to clear:

```text
RegWrite
MemRead
MemWrite
Branch
Jump
```

This prevents wrong-path instructions from changing architectural state.

---

## 22. What Gets Flushed

When branch/jump decision is made in EX, the younger instructions are in earlier stages.

Typical flush action:

```text
Flush IF/ID
Flush ID/EX
```

This removes the wrong-path instructions from the pipeline.

Older instructions in later stages should not be flushed because they are valid instructions before the branch/jump.

---

## 23. Why EX/MEM and MEM/WB Are Not Flushed

Instructions in EX/MEM and MEM/WB are older than the branch or jump instruction.

They are already before the control-flow instruction in program order.

Therefore, they should complete normally.

```text
Do not flush EX/MEM
Do not flush MEM/WB
```

Only younger wrong-path instructions are flushed.

---

## 24. Branch Flush Example

Program:

```asm
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, target
addi x3, x0, 100
target:
addi x4, x0, 200
```

Since `x1 == x2`, the branch is taken.

Expected behavior:

```text
x3 should not be updated
x4 should be updated
```

The wrong-path instruction after the branch is flushed.

---

## 25. Jump Flush Example

Program:

```asm
jal  x1, target
addi x2, x0, 50
target:
addi x3, x0, 60
```

Expected behavior:

```text
x1 = return address
x2 should not be updated
x3 = 60
```

The instruction after `jal` is flushed.

---

## 26. Stall vs Flush

| Feature        | Stall           | Flush                         |
| -------------- | --------------- | ----------------------------- |
| Purpose        | Wait for data   | Remove wrong-path instruction |
| Used For       | Load-use hazard | Branch/jump hazard            |
| PC Behavior    | Hold PC         | Redirect PC                   |
| IF/ID Behavior | Hold            | Clear                         |
| ID/EX Behavior | Insert bubble   | Clear                         |

A stall keeps an instruction for later execution.

A flush removes an instruction because it should not execute.

---

## 27. Summary

The hazard handling logic allows the pipeline to execute dependent instructions correctly.

| Hazard                          | Solution                              |
| ------------------------------- | ------------------------------------- |
| ALU dependency                  | Forward from EX/MEM or MEM/WB         |
| Store data dependency           | Forward store data                    |
| Branch operand dependency       | Use forwarded operands for comparison |
| WB and ID same-cycle dependency | WB-to-ID bypass                       |
| Load-use dependency             | One-cycle stall                       |
| Taken branch                    | Flush wrong-path instructions         |
| Jump                            | Flush wrong-path instructions         |
| Destination is `x0`             | Ignore forwarding/write               |

The processor uses forwarding whenever possible, stalls only when required, and flushes wrong-path instructions after branch or jump redirection.
