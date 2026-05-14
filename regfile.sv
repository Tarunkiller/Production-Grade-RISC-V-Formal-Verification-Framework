`default_nettype none

module regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] registers [0:31];

    always_comb begin
        // Read port 1 with internal forwarding (if reading same reg as writing)
        if (rs1_addr == 5'b0)
            rs1_data = 32'b0;
        else if (we && (rs1_addr == rd_addr))
            rs1_data = rd_data;
        else
            rs1_data = registers[rs1_addr];

        // Read port 2 with internal forwarding
        if (rs2_addr == 5'b0)
            rs2_data = 32'b0;
        else if (we && (rs2_addr == rd_addr))
            rs2_data = rd_data;
        else
            rs2_data = registers[rs2_addr];
    end

    always_ff @(posedge clk) begin
        if (we && (rd_addr != 5'b0)) begin
            registers[rd_addr] <= rd_data;
        end
    end

endmodule
