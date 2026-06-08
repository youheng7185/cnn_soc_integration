`include "axi/typedef.svh"
`include "axi/assign.svh"

module cv32e40p_sim (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic rx_i,
    output logic tx_o
);

  // =====================
  // Parameters
  // =====================
  localparam int unsigned NUM_SLAVES     = 2;
  localparam int unsigned AXI_ADDR_WIDTH = 32;
  localparam int unsigned AXI_DATA_WIDTH = 32;
  localparam int unsigned MAX_TRANS      = 4;

  // =====================
  // Type definitions
  // =====================
  typedef logic [AXI_ADDR_WIDTH-1:0]   addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0]   data_t;
  typedef logic [AXI_DATA_WIDTH/8-1:0] strb_t;

  `AXI_LITE_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t)
  `AXI_LITE_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t)
  `AXI_LITE_TYPEDEF_B_CHAN_T(b_chan_t)
  `AXI_LITE_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t)
  `AXI_LITE_TYPEDEF_R_CHAN_T(r_chan_t, data_t)
  `AXI_LITE_TYPEDEF_REQ_T(axi_lite_req_t, aw_chan_t, w_chan_t, ar_chan_t)
  `AXI_LITE_TYPEDEF_RESP_T(axi_lite_resp_t, b_chan_t, r_chan_t)

  typedef struct packed {
    int unsigned idx;
    addr_t       start_addr;
    addr_t       end_addr;
  } addr_map_rule_t;

  // Address map:
  //   Slave 0: Data Memory  0x1000_0000 – 0x1000_1FFF (8KB)
  //   Slave 1: UART0        0x8000_0200 – 0x8000_021F (32B)
  localparam addr_map_rule_t [NUM_SLAVES-1:0] ADDR_MAP = '{
    '{ idx: 1, start_addr: 32'h8000_0200, end_addr: 32'h8000_0220 },
    '{ idx: 0, start_addr: 32'h1000_0000, end_addr: 32'h1000_2000 }
  };

  // =====================
  // CPU data bus wires
  // =====================
  logic        data_req;
  logic        data_gnt;
  logic        data_rvalid;
  logic        data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;

  // =====================
  // Instruction bus wires
  // =====================
  logic        instr_req;
  logic        instr_gnt;
  logic        instr_rvalid;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;

  // =====================
  // AXI-Lite structs: CPU master → demux
  // =====================
  axi_lite_req_t  cpu_axi_req;
  axi_lite_resp_t cpu_axi_resp;

  // =====================
  // AXI-Lite structs: demux → slaves
  // =====================
  axi_lite_req_t  [NUM_SLAVES-1:0] slv_axi_reqs;
  axi_lite_resp_t [NUM_SLAVES-1:0] slv_axi_resps;

  // =====================
  // Address decode select signals
  // =====================
  logic [$clog2(NUM_SLAVES)-1:0] aw_select, ar_select;
  logic                          aw_dec_valid, ar_dec_valid;
  logic                          aw_dec_error, ar_dec_error;

  // =====================
  // Flat wires: demux slave 0 → axi_data_mem
  // =====================
  logic [31:0] data_mem_axi_awaddr;
  logic        data_mem_axi_awvalid;
  logic        data_mem_axi_awready;
  logic [31:0] data_mem_axi_wdata;
  logic [3:0]  data_mem_axi_wstrb;
  logic        data_mem_axi_wvalid;
  logic        data_mem_axi_wready;
  logic [1:0]  data_mem_axi_bresp;
  logic        data_mem_axi_bvalid;
  logic        data_mem_axi_bready;
  logic [31:0] data_mem_axi_araddr;
  logic        data_mem_axi_arvalid;
  logic        data_mem_axi_arready;
  logic [31:0] data_mem_axi_rdata;
  logic [1:0]  data_mem_axi_rresp;
  logic        data_mem_axi_rvalid;
  logic        data_mem_axi_rready;

  // =====================
  // Flat wires: demux slave 1 → axi_uart
  // =====================
  logic [31:0] uart0_axi_awaddr;
  logic        uart0_axi_awvalid;
  logic        uart0_axi_awready;
  logic [31:0] uart0_axi_wdata;
  logic [3:0]  uart0_axi_wstrb;
  logic        uart0_axi_wvalid;
  logic        uart0_axi_wready;
  logic [1:0]  uart0_axi_bresp;
  logic        uart0_axi_bvalid;
  logic        uart0_axi_bready;
  logic [31:0] uart0_axi_araddr;
  logic        uart0_axi_arvalid;
  logic        uart0_axi_arready;
  logic [31:0] uart0_axi_rdata;
  logic [1:0]  uart0_axi_rresp;
  logic        uart0_axi_rvalid;
  logic        uart0_axi_rready;

  // =====================
  // CPU core
  // =====================
  cv32e40p_top #(
    .COREV_PULP        (0),
    .COREV_CLUSTER     (0),
    .FPU               (0),
    .ZFINX             (0),
    .NUM_MHPMCOUNTERS  (1)
  ) u_core (
    .clk_i               (clk_i),
    .rst_ni              (rst_ni),
    .pulp_clock_en_i     (1'b1),
    .scan_cg_en_i        (1'b0),
    .boot_addr_i         (32'h0000_0000),
    .mtvec_addr_i        (32'h0000_0000),
    .dm_halt_addr_i      (32'h0000_0000),
    .hart_id_i           (32'h0),
    .dm_exception_addr_i (32'h0000_0000),
    .instr_req_o         (instr_req),
    .instr_gnt_i         (instr_gnt),
    .instr_rvalid_i      (instr_rvalid),
    .instr_addr_o        (instr_addr),
    .instr_rdata_i       (instr_rdata),
    .data_req_o          (data_req),
    .data_gnt_i          (data_gnt),
    .data_rvalid_i       (data_rvalid),
    .data_we_o           (data_we),
    .data_be_o           (data_be),
    .data_addr_o         (data_addr),
    .data_wdata_o        (data_wdata),
    .data_rdata_i        (data_rdata),
    .irq_i               (32'b0),
    .irq_ack_o           (),
    .irq_id_o            (),
    .debug_req_i         (1'b0),
    .debug_havereset_o   (),
    .debug_running_o     (),
    .debug_halted_o      (),
    .fetch_enable_i      (1'b1),
    .core_sleep_o        ()
  );

  // =====================
  // core2axi bridge
  // =====================
  core2axi u_core2axi (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .data_req_i    (data_req),
    .data_gnt_o    (data_gnt),
    .data_rvalid_o (data_rvalid),
    .data_addr_i   (data_addr),
    .data_we_i     (data_we),
    .data_be_i     (data_be),
    .data_rdata_o  (data_rdata),
    .data_wdata_i  (data_wdata),
    .aw_addr_o     (cpu_axi_req.aw.addr),
    .aw_prot_o     (),
    .aw_valid_o    (cpu_axi_req.aw_valid),
    .aw_ready_i    (cpu_axi_resp.aw_ready),
    .w_data_o      (cpu_axi_req.w.data),
    .w_strb_o      (cpu_axi_req.w.strb),
    .w_valid_o     (cpu_axi_req.w_valid),
    .w_ready_i     (cpu_axi_resp.w_ready),
    .b_resp_i      (cpu_axi_resp.b.resp),
    .b_valid_i     (cpu_axi_resp.b_valid),
    .b_ready_o     (cpu_axi_req.b_ready),
    .ar_addr_o     (cpu_axi_req.ar.addr),
    .ar_prot_o     (),
    .ar_valid_o    (cpu_axi_req.ar_valid),
    .ar_ready_i    (cpu_axi_resp.ar_ready),
    .r_data_i      (cpu_axi_resp.r.data),
    .r_resp_i      (cpu_axi_resp.r.resp),
    .r_valid_i     (cpu_axi_resp.r_valid),
    .r_ready_o     (cpu_axi_req.r_ready)
  );

  assign cpu_axi_req.aw.prot = 3'b000;
  assign cpu_axi_req.ar.prot = 3'b000;

  // =====================
  // Address decoder — AW channel
  // =====================
  addr_decode #(
    .NoIndices ( NUM_SLAVES      ),
    .NoRules   ( NUM_SLAVES      ),
    .addr_t    ( addr_t          ),
    .rule_t    ( addr_map_rule_t )
  ) u_aw_decode (
    .addr_i           ( cpu_axi_req.aw.addr ),
    .addr_map_i       ( ADDR_MAP            ),
    .idx_o            ( aw_select           ),
    .dec_valid_o      ( aw_dec_valid        ),
    .dec_error_o      ( aw_dec_error        ),
    .en_default_idx_i ( 1'b1               ),
    .default_idx_i    ( '0                 )
  );

  // =====================
  // Address decoder — AR channel
  // =====================
  addr_decode #(
    .NoIndices ( NUM_SLAVES      ),
    .NoRules   ( NUM_SLAVES      ),
    .addr_t    ( addr_t          ),
    .rule_t    ( addr_map_rule_t )
  ) u_ar_decode (
    .addr_i           ( cpu_axi_req.ar.addr ),
    .addr_map_i       ( ADDR_MAP            ),
    .idx_o            ( ar_select           ),
    .dec_valid_o      ( ar_dec_valid        ),
    .dec_error_o      ( ar_dec_error        ),
    .en_default_idx_i ( 1'b1               ),
    .default_idx_i    ( '0                 )
  );

  // =====================
  // AXI-Lite Demux (1 master → 2 slaves)
  // =====================
  axi_lite_demux #(
    .aw_chan_t   ( aw_chan_t       ),
    .w_chan_t    ( w_chan_t        ),
    .b_chan_t    ( b_chan_t        ),
    .ar_chan_t   ( ar_chan_t       ),
    .r_chan_t    ( r_chan_t        ),
    .axi_req_t   ( axi_lite_req_t  ),
    .axi_resp_t  ( axi_lite_resp_t ),
    .NoMstPorts  ( NUM_SLAVES     ),
    .MaxTrans    ( MAX_TRANS      ),
    .FallThrough ( 1'b0           ),
    .SpillAw     ( 1'b1           ),
    .SpillW      ( 1'b0           ),
    .SpillB      ( 1'b0           ),
    .SpillAr     ( 1'b1           ),
    .SpillR      ( 1'b0           )
  ) u_axi_lite_demux (
    .clk_i           ( clk_i         ),
    .rst_ni          ( rst_ni        ),
    .test_i          ( 1'b0          ),
    .slv_req_i       ( cpu_axi_req   ),
    .slv_aw_select_i ( aw_select     ),
    .slv_ar_select_i ( ar_select     ),
    .slv_resp_o      ( cpu_axi_resp  ),
    .mst_reqs_o      ( slv_axi_reqs  ),
    .mst_resps_i     ( slv_axi_resps )
  );

  // =====================
  // Unpack demux slave 0 → flat wires (data mem)
  // =====================
  assign data_mem_axi_awaddr  = slv_axi_reqs[0].aw.addr;
  assign data_mem_axi_awvalid = slv_axi_reqs[0].aw_valid;
  assign data_mem_axi_wdata   = slv_axi_reqs[0].w.data;
  assign data_mem_axi_wstrb   = slv_axi_reqs[0].w.strb;
  assign data_mem_axi_wvalid  = slv_axi_reqs[0].w_valid;
  assign data_mem_axi_bready  = slv_axi_reqs[0].b_ready;
  assign data_mem_axi_araddr  = slv_axi_reqs[0].ar.addr;
  assign data_mem_axi_arvalid = slv_axi_reqs[0].ar_valid;
  assign data_mem_axi_rready  = slv_axi_reqs[0].r_ready;

  assign slv_axi_resps[0].aw_ready = data_mem_axi_awready;
  assign slv_axi_resps[0].w_ready  = data_mem_axi_wready;
  assign slv_axi_resps[0].b.resp   = data_mem_axi_bresp;
  assign slv_axi_resps[0].b_valid  = data_mem_axi_bvalid;
  assign slv_axi_resps[0].ar_ready = data_mem_axi_arready;
  assign slv_axi_resps[0].r.data   = data_mem_axi_rdata;
  assign slv_axi_resps[0].r.resp   = data_mem_axi_rresp;
  assign slv_axi_resps[0].r_valid  = data_mem_axi_rvalid;

  // =====================
  // Unpack demux slave 1 → flat wires (uart)
  // =====================
  assign uart0_axi_awaddr  = slv_axi_reqs[1].aw.addr;
  assign uart0_axi_awvalid = slv_axi_reqs[1].aw_valid;
  assign uart0_axi_wdata   = slv_axi_reqs[1].w.data;
  assign uart0_axi_wstrb   = slv_axi_reqs[1].w.strb;
  assign uart0_axi_wvalid  = slv_axi_reqs[1].w_valid;
  assign uart0_axi_bready  = slv_axi_reqs[1].b_ready;
  assign uart0_axi_araddr  = slv_axi_reqs[1].ar.addr;
  assign uart0_axi_arvalid = slv_axi_reqs[1].ar_valid;
  assign uart0_axi_rready  = slv_axi_reqs[1].r_ready;

  assign slv_axi_resps[1].aw_ready = uart0_axi_awready;
  assign slv_axi_resps[1].w_ready  = uart0_axi_wready;
  assign slv_axi_resps[1].b.resp   = uart0_axi_bresp;
  assign slv_axi_resps[1].b_valid  = uart0_axi_bvalid;
  assign slv_axi_resps[1].ar_ready = uart0_axi_arready;
  assign slv_axi_resps[1].r.data   = uart0_axi_rdata;
  assign slv_axi_resps[1].r.resp   = uart0_axi_rresp;
  assign slv_axi_resps[1].r_valid  = uart0_axi_rvalid;

  // =====================
  // Boot ROM — directly on instruction bus
  // =====================
  boot_rom_1kB u_boot_rom (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
    .instr_req_i    (instr_req),
    .instr_gnt_o    (instr_gnt),
    .instr_rvalid_o (instr_rvalid),
    .instr_addr_i   (instr_addr),
    .instr_rdata_o  (instr_rdata)
  );

  // =====================
  // Data Memory (0x1000_0000) — 13-bit addr = 8KB
  // =====================
  axi_data_mem u_axi_data_mem (
    .S_AXI_ACLK    (clk_i),
    .S_AXI_ARESETN (rst_ni),
    .S_AXI_AWVALID (data_mem_axi_awvalid),
    .S_AXI_AWREADY (data_mem_axi_awready),
    .S_AXI_AWADDR  (data_mem_axi_awaddr[12:0]),
    .S_AXI_AWPROT  (3'b000),
    .S_AXI_WVALID  (data_mem_axi_wvalid),
    .S_AXI_WREADY  (data_mem_axi_wready),
    .S_AXI_WDATA   (data_mem_axi_wdata),
    .S_AXI_WSTRB   (data_mem_axi_wstrb),
    .S_AXI_BVALID  (data_mem_axi_bvalid),
    .S_AXI_BREADY  (data_mem_axi_bready),
    .S_AXI_BRESP   (data_mem_axi_bresp),
    .S_AXI_ARVALID (data_mem_axi_arvalid),
    .S_AXI_ARREADY (data_mem_axi_arready),
    .S_AXI_ARADDR  (data_mem_axi_araddr[12:0]),
    .S_AXI_ARPROT  (3'b000),
    .S_AXI_RVALID  (data_mem_axi_rvalid),
    .S_AXI_RREADY  (data_mem_axi_rready),
    .S_AXI_RDATA   (data_mem_axi_rdata),
    .S_AXI_RRESP   (data_mem_axi_rresp)
  );

  // =====================
  // UART0 (0x8000_0200) — 5-bit addr
  // =====================
  axi_uart u_axi_uart0 (
    .S_AXI_ACLK    (clk_i),
    .S_AXI_ARESETN (rst_ni),
    .S_AXI_AWVALID (uart0_axi_awvalid),
    .S_AXI_AWREADY (uart0_axi_awready),
    .S_AXI_AWADDR  (uart0_axi_awaddr[4:0]),
    .S_AXI_AWPROT  (3'b000),
    .S_AXI_WVALID  (uart0_axi_wvalid),
    .S_AXI_WREADY  (uart0_axi_wready),
    .S_AXI_WDATA   (uart0_axi_wdata),
    .S_AXI_WSTRB   (uart0_axi_wstrb),
    .S_AXI_BVALID  (uart0_axi_bvalid),
    .S_AXI_BREADY  (uart0_axi_bready),
    .S_AXI_BRESP   (uart0_axi_bresp),
    .S_AXI_ARVALID (uart0_axi_arvalid),
    .S_AXI_ARREADY (uart0_axi_arready),
    .S_AXI_ARADDR  (uart0_axi_araddr[4:0]),
    .S_AXI_ARPROT  (3'b000),
    .S_AXI_RVALID  (uart0_axi_rvalid),
    .S_AXI_RREADY  (uart0_axi_rready),
    .S_AXI_RDATA   (uart0_axi_rdata),
    .S_AXI_RRESP   (uart0_axi_rresp),
    .uart_rx_i     (rx_i),
    .uart_tx_o     (tx_o)
  );

endmodule