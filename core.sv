`default_nettype none

module core (
    input  wire        clk,
    input  wire        rst_n,

    // Instruction Memory Interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // Data Memory Interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    output wire        dmem_we,
    output wire        dmem_re
);

    logic [31:0] pc, next_pc;

    // Fetch
    assign imem_addr = pc;
    logic [31:0] instr;
    assign instr = imem_rdata;

    // Decode
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    decoder u_decoder (
        .instr(instr),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm_i(imm_i),
        .imm_s(imm_s),
        .imm_b(imm_b),
        .imm_u(imm_u),
        .imm_j(imm_j)
    );

    // Control
    logic reg_write, alu_src_b, mem_read, mem_write, branch, jump;
    logic [3:0] alu_op;

    control u_control (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_op(alu_op),
        .alu_src_b(alu_src_b),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump)
    );

    // Regfile
    logic [31:0] rs1_data, rs2_data, rd_data;

    regfile u_regfile (
        .clk(clk),
        .we(reg_write),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ALU
    logic [31:0] alu_in_a, alu_in_b, alu_result;
    logic alu_zero;

    assign alu_in_a = (opcode == 7'b0010111 || opcode == 7'b1101111) ? pc : rs1_data; // AUIPC, JAL uses PC
    
    always_comb begin
        if (alu_src_b) begin
            case (opcode)
                7'b0010011, 7'b0000011, 7'b1100111: alu_in_b = imm_i; // OP-IMM, LOAD, JALR
                7'b0100011: alu_in_b = imm_s; // STORE
                7'b0010111: alu_in_b = imm_u; // AUIPC
                default: alu_in_b = imm_i;
            endcase
        end else begin
            alu_in_b = rs2_data;
        end
    end

    alu u_alu (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Memory Interface
    assign dmem_addr  = alu_result;
    assign dmem_wdata = rs2_data;
    assign dmem_we    = mem_write;
    assign dmem_re    = mem_read;

    // Writeback
    always_comb begin
        if (opcode == 7'b0110111) // LUI
            rd_data = imm_u;
        else if (mem_read)
            rd_data = dmem_rdata;
        else if (jump)
            rd_data = pc + 4;
        else
            rd_data = alu_result;
    end

    // PC Logic
    always_comb begin
        next_pc = pc + 4;
        if (jump) begin
            if (opcode == 7'b1101111) // JAL
                next_pc = pc + imm_j;
            else if (opcode == 7'b1100111) // JALR
                next_pc = (rs1_data + imm_i) & ~32'b1;
        end else if (branch) begin
            logic take_branch;
            case (funct3)
                3'b000: take_branch = alu_zero;           // BEQ
                3'b001: take_branch = !alu_zero;          // BNE
                3'b100: take_branch = (alu_result[31]);   // BLT
                3'b101: take_branch = (!alu_result[31]);  // BGE
                3'b110: take_branch = (alu_result[0]);    // BLTU (simplification)
                3'b111: take_branch = (!alu_result[0]);   // BGEU (simplification)
                default: take_branch = 1'b0;
            endcase
            if (take_branch)
                next_pc = pc + imm_b;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'b0;
        else
            pc <= next_pc;
    end

endmodule
