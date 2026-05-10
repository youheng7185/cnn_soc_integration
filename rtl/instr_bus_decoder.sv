module instr_bus_decoder (
    // =========================
    // CPU instruction interface
    // =========================
    input  wire        instr_req_i,
    output wire        instr_gnt_o,
    output wire        instr_rvalid_o,
    input  wire [31:0] instr_addr_i,
    output wire [31:0] instr_rdata_o,

    // =========================
    // Boot ROM (1 kB)
    // =========================
    output wire        boot_req_o,
    input  wire        boot_gnt_i,
    input  wire        boot_rvalid_i,
    output wire [31:0] boot_addr_o,
    input  wire [31:0] boot_rdata_i,

    // =========================
    // Instruction memory (8 kB)
    // =========================
    output wire        imem_req_o,
    input  wire        imem_gnt_i,
    input  wire        imem_rvalid_i,
    output wire [31:0] imem_addr_o,
    input  wire [31:0] imem_rdata_i
);

    // Address decode
    // 0x0000_0000 – 0x7FFF_FFFF → boot ROM
    // 0x8000_0000 – 0xFFFF_FFFF → instruction memory
    wire target_boot = ~instr_addr_i[31];
    wire target_imem =  instr_addr_i[31];

    // -------------------------
    // Request routing
    // -------------------------
    assign boot_req_o = instr_req_i & target_boot;
    assign imem_req_o = instr_req_i & target_imem;

    assign boot_addr_o = instr_addr_i;
    assign imem_addr_o = instr_addr_i;

    // -------------------------
    // Response mux back to CPU
    // -------------------------
    assign instr_gnt_o = target_boot ? boot_gnt_i
                                     : imem_gnt_i;

    assign instr_rvalid_o = target_boot ? boot_rvalid_i
                                        : imem_rvalid_i;

    assign instr_rdata_o = target_boot ? boot_rdata_i
                                       : imem_rdata_i;

endmodule
