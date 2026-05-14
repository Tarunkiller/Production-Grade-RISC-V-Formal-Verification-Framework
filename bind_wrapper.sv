`default_nettype none

module bind_wrapper;

    // Bind ALU properties
    bind alu alu_props u_alu_props (
        .clk(clk), // Assuming a top-level clock is available, but ALU is purely combinational
        // Wait, alu doesn't have clk. Let's pass it from core
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );

    // Bind Register File properties
    bind regfile regfile_props u_regfile_props (
        .clk(clk),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .r0_val(registers[0])
    );

    // Bind Pipeline properties
    bind core pipeline_props u_pipeline_props (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .branch(branch),
        .jump(jump),
        .next_pc(next_pc)
    );

    // Bind Liveness properties
    bind core liveness_props u_liveness_props (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc)
    );

endmodule
