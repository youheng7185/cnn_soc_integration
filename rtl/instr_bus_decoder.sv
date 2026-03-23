module instr_bus_decoder (
    input  logic        instr_req_i,
    output logic        instr_gnt_o,
    output logic        instr_rvalid_o,
    input  logic [31:0] instr_addr_i,
    output logic [31:0] instr_rdata_o,

    // Boot ROM (1 kB)
    output logic        boot_req_o,
    input  logic        boot_gnt_i,
    input  logic        boot_rvalid_i,
    output logic [31:0] boot_addr_o,
    input  logic [31:0] boot_rdata_i,

    // Instruction memory (8 kB)
    output logic        imem_req_o,
    input  logic        imem_gnt_i,
    input  logic        imem_rvalid_i,
    output logic [31:0] imem_addr_o,
    input  logic [31:0] imem_rdata_i,

    // DM program buffer (dm_top slave port) ← NEW
    output logic        dm_req_o,
    input  logic        dm_gnt_i,
    input  logic        dm_rvalid_i,
    output logic [31:0] dm_addr_o,
    input  logic [31:0] dm_rdata_i
);

    // DM program buffer lives at dm_halt_addr range
    // must match dm_halt_addr_i in your core instantiation
    localparam logic [31:0] DM_BASE = 32'h1A11_0000;
    localparam logic [31:0] DM_MASK = 32'hFFFF_F000;  // 4KB window

    wire target_dm   = ((instr_addr_i & DM_MASK) == DM_BASE);
    wire target_boot = ~instr_addr_i[31] & ~target_dm;
    wire target_imem =  instr_addr_i[31] & ~target_dm;

    // request routing
    assign boot_req_o = instr_req_i & target_boot;
    assign imem_req_o = instr_req_i & target_imem;
    assign dm_req_o   = instr_req_i & target_dm;    // ← NEW

    assign boot_addr_o = instr_addr_i;
    assign imem_addr_o = instr_addr_i;
    assign dm_addr_o   = instr_addr_i;              // ← NEW

    // response mux
    assign instr_gnt_o = target_dm   ? dm_gnt_i   :
                         target_boot ? boot_gnt_i  :
                                       imem_gnt_i;

    assign instr_rvalid_o = target_dm   ? dm_rvalid_i   :
                            target_boot ? boot_rvalid_i  :
                                          imem_rvalid_i;

    assign instr_rdata_o  = target_dm   ? dm_rdata_i   :
                            target_boot ? boot_rdata_i  :
                                          imem_rdata_i;

endmodule