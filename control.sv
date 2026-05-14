`default_nettype none

module control (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output logic       reg_write,
    output logic [3:0] alu_op,
    output logic       alu_src_b,
    output logic       mem_read,
    output logic       mem_write,
    output logic       branch,
    output logic       jump
);

    // Opcodes
    localparam [6:0] OPC_LOAD   = 7'b0000011,
                     OPC_STORE  = 7'b0100011,
                     OPC_BRANCH = 7'b1100011,
                     OPC_JALR   = 7'b1100111,
                     OPC_JAL    = 7'b1101111,
                     OPC_OP_IMM = 7'b0010011,
                     OPC_OP     = 7'b0110011,
                     OPC_AUIPC  = 7'b0010111,
                     OPC_LUI    = 7'b0110111;

    always_comb begin
        reg_write = 1'b0;
        alu_op    = 4'b0000;
        alu_src_b = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;

        case (opcode)
            OPC_OP: begin
                reg_write = 1'b1;
                alu_src_b = 1'b0; // Use rs2
                if (funct7 == 7'b0100000 && (funct3 == 3'b000 || funct3 == 3'b101))
                    alu_op = {1'b1, funct3}; // SUB or SRA
                else
                    alu_op = {1'b0, funct3};
            end
            OPC_OP_IMM: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1; // Use imm
                if (funct7 == 7'b0100000 && funct3 == 3'b101)
                    alu_op = {1'b1, funct3}; // SRAI
                else
                    alu_op = {1'b0, funct3};
            end
            OPC_LOAD: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                mem_read  = 1'b1;
                alu_op    = 4'b0000; // ADD
            end
            OPC_STORE: begin
                alu_src_b = 1'b1;
                mem_write = 1'b1;
                alu_op    = 4'b0000; // ADD
            end
            OPC_BRANCH: begin
                branch    = 1'b1;
                alu_src_b = 1'b0; // Use rs2
                alu_op    = 4'b1000; // SUB for comparison
            end
            OPC_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
            end
            OPC_JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 4'b0000; // ADD
            end
            OPC_LUI: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                // Just pass imm through ALU (or we can handle logic in datapath)
            end
            OPC_AUIPC: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 4'b0000; // ADD
            end
            default: ; // Defaults handled at top
        endcase
    end

endmodule
