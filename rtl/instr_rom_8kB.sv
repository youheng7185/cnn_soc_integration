module instr_rom_8kB (
    input wire clk_i,
    input wire rst_ni,

    input wire instr_req_i,
    output wire instr_gnt_o,
    output logic instr_rvalid_o,
    input wire [31:0] instr_addr_i,
    output logic [31:0] instr_rdata_o
);

    // 8kB of data mem
    logic [31:0] instr_mem [0:2047];
    logic [31:0] rdata_q;

    assign instr_gnt_o = 1'b1; // Always ready
    assign instr_rdata_o = rdata_q;

    // initial begin
    //     instr_mem[0] = 32'h800002b7;  // lui t0, 0x80000
    //     instr_mem[1] = 32'h0002a303;  // lw  t1, 0(t0)
    //     instr_mem[2] = 32'h00000397;  // lui t2, 0x00000
    //     instr_mem[3] = 32'h0063a023;  // sw  t1, 0(t2)
    //     instr_mem[4] = 32'h00005e37;  // lui t3, 0x5
    //     instr_mem[5] = 32'ha5ae0e13;  // addi t3, t3, -1446
    //     instr_mem[6] = 32'h01c2a223;  // sh  t3, 4(t0)
    //     instr_mem[7] = 32'h0000006f;  // loop

    //     for (int i = 8; i < 2048; i++) begin
    //         instr_mem[i] = 32'h00000013;  // NOP (addi x0, x0, 0)
    //     end
    // end

    initial begin
        $readmemh("cnn_soc_c_project/build/firmware_clean.hex", instr_mem);
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            instr_rvalid_o <= 1'b0;
            rdata_q <= 32'b0;
        end else begin
            instr_rvalid_o <= 1'b0;

            if (instr_req_i) begin
                //rdata_q <= instr_mem[instr_addr_i[12:2]];
                rdata_q <= instr_mem[(instr_addr_i - 32'h80000000) >> 2];
                instr_rvalid_o <= 1'b1;
            end
        end
    end

endmodule
