`timescale 1ns/1ps

module pipelined_top_tb;

    reg clk;
    reg rst;
    integer i;
    integer fail_count;

    `define IMEM dut.IF.inst_mem.memory
    `define REGS dut.ID.rf.registers
    `define DMEM dut.MEM.dm.memory

    pipelined_top dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    // -----------------------------
    // Instruction encoding functions
    // -----------------------------

    function [31:0] R_TYPE;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            R_TYPE = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] I_TYPE;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            I_TYPE = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] S_TYPE;
        input [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            S_TYPE = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
        end
    endfunction

    function [31:0] B_TYPE;
        input [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            B_TYPE = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
        end
    endfunction

    function [31:0] J_TYPE;
        input [20:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            J_TYPE = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
        end
    endfunction

    // -----------------------------
    // Opcodes / funct values
    // -----------------------------

    localparam [6:0] OPCODE_R      = 7'b0110011;
    localparam [6:0] OPCODE_I      = 7'b0010011;
    localparam [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam [6:0] OPCODE_STORE  = 7'b0100011;
    localparam [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam [6:0] OPCODE_JAL    = 7'b1101111;

    localparam [2:0] F3_ADD_SUB = 3'b000;
    localparam [2:0] F3_LW_SW   = 3'b010;
    localparam [2:0] F3_BEQ     = 3'b000;
    localparam [2:0] F3_BNE     = 3'b001;

    localparam [6:0] F7_ADD = 7'b0000000;
    localparam [6:0] F7_SUB = 7'b0100000;

    // -----------------------------
    // Instruction helpers
    // -----------------------------

    function [31:0] ADD;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            ADD = R_TYPE(F7_ADD, rs2, rs1, F3_ADD_SUB, rd, OPCODE_R);
        end
    endfunction

    function [31:0] SUB;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            SUB = R_TYPE(F7_SUB, rs2, rs1, F3_ADD_SUB, rd, OPCODE_R);
        end
    endfunction

    function [31:0] ADDI;
        input [4:0] rd;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            ADDI = I_TYPE(imm, rs1, F3_ADD_SUB, rd, OPCODE_I);
        end
    endfunction

    function [31:0] LW;
        input [4:0] rd;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            LW = I_TYPE(imm, rs1, F3_LW_SW, rd, OPCODE_LOAD);
        end
    endfunction

    function [31:0] SW;
        input [4:0] rs2;
        input [4:0] rs1;
        input [11:0] imm;
        begin
            SW = S_TYPE(imm, rs2, rs1, F3_LW_SW, OPCODE_STORE);
        end
    endfunction

    function [31:0] BEQ;
        input [4:0] rs1;
        input [4:0] rs2;
        input [12:0] imm;
        begin
            BEQ = B_TYPE(imm, rs2, rs1, F3_BEQ, OPCODE_BRANCH);
        end
    endfunction

    function [31:0] BNE;
        input [4:0] rs1;
        input [4:0] rs2;
        input [12:0] imm;
        begin
            BNE = B_TYPE(imm, rs2, rs1, F3_BNE, OPCODE_BRANCH);
        end
    endfunction

    function [31:0] JAL;
        input [4:0] rd;
        input [20:0] imm;
        begin
            JAL = J_TYPE(imm, rd, OPCODE_JAL);
        end
    endfunction

    // -----------------------------
    // Check tasks
    // -----------------------------

    task CHECK_REG;
        input [4:0] reg_no;
        input [31:0] expected;
        begin
            if (`REGS[reg_no] !== expected) begin
                $display("FAIL: x%0d = %0d, Expected = %0d", reg_no, `REGS[reg_no], expected);
                fail_count = fail_count + 1;
            end
            else begin
                $display("PASS: x%0d = %0d", reg_no, `REGS[reg_no]);
            end
        end
    endtask

    task CHECK_DMEM;
        input [31:0] mem_index;
        input [31:0] expected;
        begin
            if (`DMEM[mem_index] !== expected) begin
                $display("FAIL: DMEM[%0d] = %0d, Expected = %0d", mem_index, `DMEM[mem_index], expected);
                fail_count = fail_count + 1;
            end
            else begin
                $display("PASS: DMEM[%0d] = %0d", mem_index, `DMEM[mem_index]);
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        fail_count = 0;

        // Clear instruction memory with NOPs
        for (i = 0; i < 256; i = i + 1) begin
            `IMEM[i] = 32'h00000013; // nop = addi x0, x0, 0
        end

        // Clear data memory
        for (i = 0; i < 256; i = i + 1) begin
            `DMEM[i] = 32'd0;
        end

        // ------------------------------------------------------------
        // FULL PIPELINE PROGRAM
        //
        // Memory is word indexed in your data memory using addr[31:2].
        // Address 100 maps to DMEM[25].
        // ------------------------------------------------------------

        // Basic setup
        `IMEM[0]  = ADDI(5'd1,  5'd0, 12'd100);  // x1 = 100
        `IMEM[1]  = ADDI(5'd2,  5'd0, 12'd10);   // x2 = 10
        `IMEM[2]  = ADDI(5'd3,  5'd0, 12'd20);   // x3 = 20

        // ALU + forwarding chain
        `IMEM[3]  = ADD (5'd4,  5'd2, 5'd3);     // x4 = 30
        `IMEM[4]  = ADD (5'd5,  5'd4, 5'd2);     // x5 = 40, needs forwarding from x4
        `IMEM[5]  = ADD (5'd6,  5'd5, 5'd4);     // x6 = 70, forwarding chain

        // Store-data forwarding test
        `IMEM[6]  = SW  (5'd6,  5'd1, 12'd0);    // Mem[100] = x6 = 70

        // Load-use hazard test
        `IMEM[7]  = LW  (5'd7,  5'd1, 12'd0);    // x7 = Mem[100] = 70
        `IMEM[8]  = ADD (5'd8,  5'd7, 5'd2);     // x8 = 80, load-use stall needed
        `IMEM[9]  = ADDI(5'd9,  5'd8, 12'd1);    // x9 = 81, forwarding after load-use

        // BEQ not taken
        `IMEM[10] = ADDI(5'd14, 5'd0, 12'd1);    // x14 = 1
        `IMEM[11] = ADDI(5'd15, 5'd0, 12'd2);    // x15 = 2
        `IMEM[12] = BEQ (5'd14, 5'd15, 13'd8);   // not taken
        `IMEM[13] = ADDI(5'd16, 5'd0, 12'd33);   // should execute

        // BEQ taken + wrong path flush
        `IMEM[14] = ADDI(5'd18, 5'd0, 12'd5);    // x18 = 5
        `IMEM[15] = ADDI(5'd19, 5'd0, 12'd5);    // x19 = 5
        `IMEM[16] = BEQ (5'd18, 5'd19, 13'd12);  // taken, jump to IMEM[19]
        `IMEM[17] = ADDI(5'd20, 5'd0, 12'd99);   // wrong path, should be flushed
        `IMEM[18] = ADDI(5'd21, 5'd0, 12'd88);   // wrong path, should be flushed
        `IMEM[19] = ADDI(5'd22, 5'd0, 12'd55);   // branch target, should execute

        // JAL test
        `IMEM[20] = JAL (5'd23, 21'd12);          // jump to IMEM[23], x23 = PC+4 = 84
        `IMEM[21] = ADDI(5'd24, 5'd0, 12'd99);   // wrong path, should be flushed
        `IMEM[22] = ADDI(5'd25, 5'd0, 12'd88);   // wrong path, should be flushed
        `IMEM[23] = ADDI(5'd26, 5'd0, 12'd66);   // JAL target, should execute

        // Branch depending on previous ALU result
        `IMEM[24] = ADDI(5'd27, 5'd0, 12'd3);    // x27 = 3
        `IMEM[25] = ADDI(5'd28, 5'd0, 12'd3);    // x28 = 3
        `IMEM[26] = SUB (5'd29, 5'd27, 5'd28);   // x29 = 0
        `IMEM[27] = BEQ (5'd29, 5'd0, 13'd12);   // taken, depends on forwarded x29
        `IMEM[28] = ADDI(5'd30, 5'd0, 12'd99);   // wrong path, should be flushed
        `IMEM[29] = ADDI(5'd31, 5'd0, 12'd88);   // wrong path, should be flushed
        `IMEM[30] = ADDI(5'd11, 5'd9, 12'd1);    // final: x11 = 82

        #12;
        rst = 0;

        // Run enough cycles
        #800;

        $display("\n================ FULL PIPELINE TEST RESULTS ================");

        // Basic setup
        CHECK_REG(5'd1,  32'd100);
        CHECK_REG(5'd2,  32'd10);
        CHECK_REG(5'd3,  32'd20);

        // ALU + forwarding
        CHECK_REG(5'd4,  32'd30);
        CHECK_REG(5'd5,  32'd40);
        CHECK_REG(5'd6,  32'd70);

        // Store + load-use
        CHECK_DMEM(32'd25, 32'd70);  // address 100 -> index 25
        CHECK_REG(5'd7,  32'd70);
        CHECK_REG(5'd8,  32'd80);
        CHECK_REG(5'd9,  32'd81);

        // BEQ not taken
        CHECK_REG(5'd14, 32'd1);
        CHECK_REG(5'd15, 32'd2);
        CHECK_REG(5'd16, 32'd33);

        // BEQ taken + flush
        CHECK_REG(5'd18, 32'd5);
        CHECK_REG(5'd19, 32'd5);
        CHECK_REG(5'd20, 32'd0);     // must remain 0 if flushed
        CHECK_REG(5'd21, 32'd0);     // must remain 0 if flushed
        CHECK_REG(5'd22, 32'd55);

        // JAL + flush
        CHECK_REG(5'd23, 32'd84);    // JAL at PC=80, so PC+4=84
        CHECK_REG(5'd24, 32'd0);     // must remain 0 if flushed
        CHECK_REG(5'd25, 32'd0);     // must remain 0 if flushed
        CHECK_REG(5'd26, 32'd66);

        // Branch depending on forwarded ALU result
        CHECK_REG(5'd27, 32'd3);
        CHECK_REG(5'd28, 32'd3);
        CHECK_REG(5'd29, 32'd0);
        CHECK_REG(5'd30, 32'd0);     // must remain 0 if flushed
        CHECK_REG(5'd31, 32'd0);     // must remain 0 if flushed

        // Final instruction
        CHECK_REG(5'd11, 32'd82);

        if (fail_count == 0) begin
            $display("\nPASS: Full pipeline integration test passed.");
        end
        else begin
            $display("\nFAIL: Full pipeline integration test failed with %0d errors.", fail_count);
        end

        $display("=============================================================\n");

        $finish;
    end

    initial begin
        $dumpfile("sim/waveforms/full_pipeline_tb.vcd");
        $dumpvars(0, pipelined_top_tb);
    end

endmodule