module boot_rom_1kB (
    input wire clk_i,
    input wire rst_ni,

    input wire instr_req_i,
    output wire instr_gnt_o,
    output logic instr_rvalid_o,
    input wire [31:0] instr_addr_i,
    output logic [31:0] instr_rdata_o
);

    // 1kB boot ROM = 256 x 32-bit words
    logic [31:0] instr_mem [0:255];
    logic [31:0] rdata_q;

    // Always ready (no wait states)
    assign instr_gnt_o   = 1'b1;
    assign instr_rdata_o = rdata_q;

    // simple boot rom which jump to 0x80000000 directly
    initial begin
        instr_mem[0] = 32'h800002b7; // lui t0, 0x80000000
        instr_mem[1] = 32'h000280e7; // JALR x0, 0(t0), jump to address in t0
        for (int i = 2; i < 256; i++) begin
            instr_mem[i] = 32'h00000013;  // NOP (addi x0, x0, 0)
        end
    end

    // initial $readmemh("boot_rom_project/build/bootrom_clean.hex", instr_mem);
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            instr_rvalid_o <= 1'b0;
            rdata_q <= 32'b0;
        end else begin
            instr_rvalid_o <= 1'b0;

            if (instr_req_i) begin
                rdata_q <= instr_mem[instr_addr_i[9:2]];
                instr_rvalid_o <= 1'b1;
            end
        end
    end

endmodule
