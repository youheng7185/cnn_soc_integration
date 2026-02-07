module boot_rom_1kB (
    input logic clk_core,
    input logic rst_core_n,

    input logic instr_req_i,
    output logic instr_gnt_o,
    output logic instr_rvalid_o,
    input logic [31:0] instr_addr_i,
    output logic [31:0] instr_rdata_o
);

    // 1kB boot ROM = 256 x 32-bit words
    logic [31:0] instr_mem [0:255];
    logic [31:0] rdata_q;

    // Always ready (no wait states)
    assign instr_gnt_o   = 1'b1;
    assign instr_rdata_o = rdata_q;

    always_ff @(posedge clk_core or negedge rst_core_n) begin
        if (!rst_core_n) begin
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
