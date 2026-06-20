# Verification

This document explains the verification strategy used for the **RV32I Pipelined RISC-V Processor**.

The goal of verification is to confirm that the processor executes instructions correctly, handles hazards properly, and produces the expected register and memory results for complete programs.

This file focuses on:

```text
Testbench strategy
Program-level tests
Expected outputs
Waveform debugging
```

---

## 1. Verification Approach

The processor is verified mainly through simulation using **Icarus Verilog** and **GTKWave**.

The verification flow is:

```text
Write program as .mem file
Load program into instruction memory
Initialize required data memory values
Run simulation
Check register and memory outputs
Generate waveform if needed
Debug using GTKWave
```

The processor is tested at two levels:

| Level                 | Purpose                                                                                             |
| --------------------- | --------------------------------------------------------------------------------------------------- |
| Module-level testing  | Tests individual blocks such as ALU, register file, immediate generator, control unit, and memories |
| Program-level testing | Runs complete programs on the pipelined processor and checks final results                          |

---

## 2. Tools Used

| Tool           | Purpose                                   |
| -------------- | ----------------------------------------- |
| Icarus Verilog | Compiling and running Verilog simulations |
| vvp            | Running compiled simulation output        |
| GTKWave        | Viewing waveform files                    |
| `.mem` files   | Storing machine-code programs             |
| Shell scripts  | Automating compile and run commands       |

---

## 3. Testbench Structure

A typical processor testbench performs the following steps:

```text
1. Instantiate the processor top module
2. Generate clock and reset
3. Load the instruction memory with a .mem program
4. Initialize data memory if required
5. Run the simulation for enough cycles
6. Check final register and memory values
7. Print PASS or FAIL messages
8. Dump waveform output for debugging
```

---

## 4. Clock and Reset

All testbenches use a clock signal to run the processor.

Example:

```verilog
always #5 clk = ~clk;
```

This gives a clock period of 10 time units.

Reset is applied at the start of simulation to initialize the processor state.

```verilog
rst = 1;
#20;
rst = 0;
```

After reset is released, the processor starts executing instructions from the program loaded into instruction memory.

---

## 5. Loading Programs

Programs are stored as hexadecimal machine code in `.mem` files.

Example `.mem` file:

```text
00a00093
01400113
002081b3
00000013
```

This represents:

```asm
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
nop
```

The testbench loads the program using:

```verilog
$readmemh("tb/programs/program.mem", dut.IF.inst_mem.memory);
```

The exact hierarchy may change depending on the top module and instance names.

---

## 6. Checking Register Outputs

The testbench checks register values after the program has completed.

Example:

```verilog
if (`REGS[3] == 32'd30)
    $display("PASS: x3 = 30");
else
    $display("FAIL: x3 = %0d, Expected = 30", `REGS[3]);
```

For easier access, testbenches may define register hierarchy macros:

```verilog
`define REGS dut.ID.rf.registers
```

This makes checks easier to write and read.

---

## 7. Checking Data Memory Outputs

For programs that use load/store instructions, the testbench checks data memory locations.

Example:

```verilog
if (`DMEM[25] == 32'd70)
    $display("PASS: DMEM[25] = 70");
else
    $display("FAIL: DMEM[25] = %0d, Expected = 70", `DMEM[25]);
```

A macro may be used for data memory access:

```verilog
`define DMEM dut.MEM.dm.memory
```

The exact hierarchy depends on the module names used in the RTL.

---

## 8. PASS/FAIL Style

The testbenches use simple PASS/FAIL messages.

Example output:

```text
PASS: x1 = 10
PASS: x2 = 20
PASS: x3 = 30
PASS: DMEM[25] = 70
```

This makes it easy to quickly confirm whether the processor executed the program correctly.

If a value is incorrect, the testbench prints both actual and expected values.

```text
FAIL: x3 = 25, Expected = 30
```

---

## 9. Program-Level Tests

The main verification is done using complete programs.

| Program                | Purpose                                                           |
| ---------------------- | ----------------------------------------------------------------- |
| Fibonacci              | Tests loop execution, arithmetic operations, branch/jump behavior |
| Array Sum              | Tests memory loads, additions, loop control, and final store      |
| GCD by Subtraction     | Tests repeated branches and arithmetic dependency                 |
| Maximum in Array       | Tests array traversal, comparisons, branches, and memory reads    |
| Forwarding Stress Test | Tests forwarding paths and dependent instruction sequences        |

These tests verify the processor as a complete system instead of only testing individual modules.

---

## 10. Fibonacci Test

The Fibonacci test verifies arithmetic operations, loop execution, and branch/jump control.

### Test Purpose

```text
Check whether the processor can execute a loop-based program correctly.
```

### Main Features Tested

| Feature                      | Tested |
| ---------------------------- | ------ |
| `addi`                       | Yes    |
| `add`                        | Yes    |
| `sw` / memory result storage | Yes    |
| Branch/jump flow             | Yes    |
| Pipeline execution           | Yes    |

### Expected Result

The expected Fibonacci result depends on the input value selected in the testbench or data memory.

---

## 11. Array Sum Test

The array sum test verifies memory access and loop-based addition.

### Test Purpose

```text
Read array elements from data memory, add them, and store the final sum.
```

### Main Features Tested

| Feature           | Tested |
| ----------------- | ------ |
| `lw`              | Yes    |
| `sw`              | Yes    |
| `add` / `addi`    | Yes    |
| Loop branch       | Yes    |
| Load-use behavior | Yes    |

### Example Expected Output

If the array is:

```text
10, 20, 30, 40
```

Expected sum:

```text
100
```

Example PASS message:

```text
PASS: Array sum = 100
```

---

## 12. GCD by Subtraction Test

The GCD test verifies repeated arithmetic and conditional branching.

### Test Purpose

```text
Compute GCD using repeated subtraction.
```

### Main Features Tested

| Feature                                              | Tested |
| ---------------------------------------------------- | ------ |
| `sub`                                                | Yes    |
| `beq` / `bne`                                        | Yes    |
| Loop execution                                       | Yes    |
| Branch flush                                         | Yes    |
| Forwarding between dependent arithmetic instructions | Yes    |

### Example Expected Output

For:

```text
GCD(48, 18)
```

Expected result:

```text
6
```

Example PASS message:

```text
PASS: GCD result = 6
```

---

## 13. Maximum in Array Test

The maximum array test verifies memory traversal and conditional updates.

### Test Purpose

```text
Read array elements and find the maximum value.
```

### Main Features Tested

| Feature                      | Tested |
| ---------------------------- | ------ |
| `lw`                         | Yes    |
| `slt`                        | Yes    |
| Conditional branch           | Yes    |
| Loop execution               | Yes    |
| Final memory/register result | Yes    |

### Example Expected Output

For:

```text
Array = 7, 12, 3, 25, 9
```

Expected maximum:

```text
25
```

Example PASS message:

```text
PASS: Maximum value = 25
```

---

## 14. Forwarding Stress Test

The forwarding stress test checks dependent instruction sequences.

### Test Purpose

```text
Verify that ALU results are correctly forwarded without unnecessary stalls.
```

### Example Dependency

```asm
addi x1, x0, 10
addi x2, x1, 20
add  x3, x2, x1
```

Expected values:

```text
x1 = 10
x2 = 30
x3 = 40
```

### Features Tested

| Feature                   | Tested |
| ------------------------- | ------ |
| EX/MEM forwarding         | Yes    |
| MEM/WB forwarding         | Yes    |
| Consecutive dependencies  | Yes    |
| `x0` protection           | Yes    |
| Store-data forwarding     | Yes    |
| Branch operand forwarding | Yes    |

---

## 15. Load-Use Hazard Test

This test verifies that the processor inserts one stall when a load result is immediately used by the next instruction.

### Example Program

```asm
lw   x1, 0(x2)
addi x3, x1, 5
```

### Expected Behavior

```text
The processor should stall for one cycle.
The loaded value should be forwarded after it becomes available.
x3 should receive loaded_value + 5.
```

### PASS Condition

```text
Final register result matches expected value.
No incorrect old value is used.
```

---

## 16. Branch and Jump Flush Test

This test verifies that wrong-path instructions are removed when a branch or jump redirects the PC.

### Branch Example

```asm
addi x1, x0, 5
addi x2, x0, 5
beq  x1, x2, target
addi x3, x0, 100
target:
addi x4, x0, 200
```

Expected behavior:

```text
x3 should not be updated by the wrong-path instruction.
x4 should be updated.
```

### Jump Example

```asm
jal  x1, target
addi x2, x0, 50
target:
addi x3, x0, 60
```

Expected behavior:

```text
x1 should contain PC + 4.
x2 should not be updated by the wrong-path instruction.
x3 should be updated.
```

---

## 17. Running Tests Using Scripts

Shell scripts can be used to automate compilation and simulation.

Example:

```bash
./sim/scripts/run_fibonacci.sh
```

A typical script performs:

```text
1. Go to repository root
2. Create build and waveform folders
3. Compile RTL and testbench using iverilog
4. Stop if compilation fails
5. Run simulation using vvp
6. Print completion message
```

Example compile command:

```bash
iverilog -o sim/build/fibonacci.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/fibonacci_pipelined_tb.v
```

Example run command:

```bash
vvp sim/build/fibonacci.vvp
```

---

## 18. Running a Custom Testbench

To run any other testbench manually:

```bash
iverilog -o sim/build/custom_test.vvp \
rtl/core/*.v \
rtl/pipeline/hazard/*.v \
rtl/pipeline/registers/*.v \
rtl/pipeline/stages/*.v \
rtl/pipeline/*.v \
tb/programs/custom_test_tb.v
```

Then run:

```bash
vvp sim/build/custom_test.vvp
```

If the testbench generates a waveform file, open it using:

```bash
gtkwave sim/waveforms/custom_test.vcd
```

---

## 19. Waveform Debugging

Waveform debugging is useful when a test fails.

The testbench should include:

```verilog
$dumpfile("sim/waveforms/test.vcd");
$dumpvars(0, testbench_name);
```

This generates a `.vcd` waveform file.

Open it in GTKWave:

```bash
gtkwave sim/waveforms/test.vcd
```

---

## 20. Important Signals to Check in Waveforms

When debugging, the following signals are useful.

### IF Stage

| Signal     | Why It Is Useful                   |
| ---------- | ---------------------------------- |
| `pc`       | Checks instruction flow            |
| `inst`     | Confirms correct instruction fetch |
| `pc_plus4` | Confirms normal PC increment       |

### ID Stage

| Signal                     | Why It Is Useful                     |
| -------------------------- | ------------------------------------ |
| `rs1`, `rs2`, `rd`         | Confirms instruction decoding        |
| `read_data1`, `read_data2` | Confirms register file output        |
| `imm`                      | Confirms immediate generation        |
| Control signals            | Confirms correct instruction control |

### EX Stage

| Signal                 | Why It Is Useful              |
| ---------------------- | ----------------------------- |
| `alu_result`           | Confirms ALU output           |
| `pc_target`            | Confirms branch/jump target   |
| `pc_src`               | Confirms PC redirection       |
| `ForwardA`, `ForwardB` | Confirms forwarding decisions |

### MEM Stage

| Signal          | Why It Is Useful         |
| --------------- | ------------------------ |
| `MemRead`       | Confirms load operation  |
| `MemWrite`      | Confirms store operation |
| `mem_read_data` | Confirms memory output   |
| `write_data`    | Confirms store data      |

### WB Stage

| Signal          | Why It Is Useful                |
| --------------- | ------------------------------- |
| `RegWrite`      | Confirms register write enable  |
| `rd`            | Confirms destination register   |
| `wb_write_data` | Confirms final write-back value |

### Hazard Signals

| Signal     | Why It Is Useful              |
| ---------- | ----------------------------- |
| `stall`    | Confirms load-use stall       |
| `flush`    | Confirms branch/jump flush    |
| `ForwardA` | Confirms operand A forwarding |
| `ForwardB` | Confirms operand B forwarding |

---

## 21. Debugging Method

When a test fails, debug in this order:

```text
1. Check whether the correct program is loaded into instruction memory.
2. Check PC sequence.
3. Check instruction decode fields.
4. Check control signals.
5. Check register read values.
6. Check ALU input values.
7. Check forwarding select signals.
8. Check ALU result.
9. Check memory read/write behavior.
10. Check final write-back value.
```

---

## 22. Common Issues Found During Verification

| Issue                                  | What to Check                              |
| -------------------------------------- | ------------------------------------------ |
| Register result is old                 | Check forwarding and WB-to-ID bypass       |
| Load-use result is wrong               | Check stall signal and ID/EX bubble        |
| Store writes wrong value               | Check store-data forwarding                |
| Branch goes to wrong location          | Check immediate generation and `pc_target` |
| Wrong-path instruction writes register | Check flush and cleared control signals    |
| x0 changes value                       | Check register file x0 protection          |
| Instruction not loaded                 | Check `$readmemh` path                     |
| Simulation stops too early             | Increase simulation run time               |
| No waveform generated                  | Check `$dumpfile` and `$dumpvars`          |

---

## 23. Verification Summary Table

| Test               | Main Feature Verified                      |
| ------------------ | ------------------------------------------ |
| Basic ALU program  | Arithmetic and write-back                  |
| Load/store program | Data memory read/write                     |
| Forwarding stress  | EX/MEM and MEM/WB forwarding               |
| Load-use test      | Stall and bubble insertion                 |
| Branch test        | Conditional PC redirection and flush       |
| Jump test          | `jal`, PC redirection, and PC+4 write-back |
| Fibonacci          | Loop execution and arithmetic              |
| Array sum          | Memory traversal and accumulation          |
| GCD subtraction    | Branch-heavy loop execution                |
| Maximum array      | Comparison and conditional update          |

The final result is a working 5-stage pipelined RV32I processor that can execute complete test programs correctly.
