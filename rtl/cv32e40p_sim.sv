module cv32e40p_sim (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        rx_i,
    output logic        tx_o
);
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
    // AXI wires (core2axi side)
    // =====================
    logic [31:0] axi_aw_addr;
    logic        axi_aw_valid;
    logic        axi_aw_ready;

    logic [31:0] axi_w_data;
    logic [3:0]  axi_w_strb;
    logic        axi_w_valid;
    logic        axi_w_ready;

    logic [1:0]  axi_b_resp;
    logic        axi_b_valid;
    logic        axi_b_ready;

    logic [31:0] axi_ar_addr;
    logic        axi_ar_valid;
    logic        axi_ar_ready;

    logic [31:0] axi_r_data;
    logic [1:0]  axi_r_resp;
    logic        axi_r_valid;
    logic        axi_r_ready;

    // =====================
    // Instruction bus wires
    // =====================
    logic        instr_req;
    logic        instr_gnt;
    logic        instr_rvalid;
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;

    assign axi_awaddr  = axi_aw_addr;
    assign axi_awvalid = axi_aw_valid;
    assign axi_aw_ready = axi_awready;

    assign axi_wdata   = axi_w_data;
    assign axi_wstrb   = axi_w_strb;
    assign axi_wvalid  = axi_w_valid;
    assign axi_w_ready = axi_wready;

    assign axi_b_resp  = axi_bresp;
    assign axi_b_valid = axi_bvalid;
    assign axi_bready  = axi_b_ready;

    assign axi_araddr  = axi_ar_addr;
    assign axi_arvalid = axi_ar_valid;
    assign axi_ar_ready = axi_arready;

    assign axi_r_data  = axi_rdata;
    assign axi_r_resp  = axi_rresp;
    assign axi_r_valid = axi_rvalid;
    assign axi_rready  = axi_r_ready;

    cv32e40p_top #(
        .COREV_PULP(0),
        .COREV_CLUSTER(0),
        .FPU(0),
        .ZFINX(0),
        .NUM_MHPMCOUNTERS(1)        
    ) u_core (
        .clk_i            (clk_i),
        .rst_ni            (rst_ni),

        .pulp_clock_en_i  (1'b1),
        .scan_cg_en_i     (1'b0),

        .boot_addr_i      (32'h0000_0000),
        .mtvec_addr_i     (32'h0000_0000),
        .dm_halt_addr_i   (32'h0000_0000),
        .hart_id_i        (32'h0),
        .dm_exception_addr_i (32'h0000_0000),

        // instruction bus
        .instr_req_o    (instr_req),
        .instr_gnt_i    (instr_gnt),
        .instr_rvalid_i (instr_rvalid),
        .instr_addr_o   (instr_addr),
        .instr_rdata_i  (instr_rdata),

        // data bus
        .data_req_o       (data_req),
        .data_gnt_i       (data_gnt),
        .data_rvalid_i    (data_rvalid),
        .data_we_o        (data_we),
        .data_be_o        (data_be),
        .data_addr_o      (data_addr),
        .data_wdata_o     (data_wdata),
        .data_rdata_i     (data_rdata),

        // interrupts/debug unused
        .irq_i            (32'b0),
        .irq_ack_o        (),
        .irq_id_o         (),
        .debug_req_i      (1'b0),
        .debug_havereset_o(),
        .debug_running_o  (),
        .debug_halted_o   (),
        .fetch_enable_i   (1'b1),
        .core_sleep_o     ()
    );

    core2axi u_core2axi (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),

        // cv32e40p data bus
        .data_req_i    (data_req),
        .data_gnt_o    (data_gnt),
        .data_rvalid_o (data_rvalid),
        .data_addr_i   (data_addr),
        .data_we_i     (data_we),
        .data_be_i     (data_be),
        .data_rdata_o  (data_rdata),
        .data_wdata_i  (data_wdata),

        // AXI write address
        .aw_addr_o    (axi_aw_addr),
        .aw_prot_o    (),
        .aw_valid_o   (axi_aw_valid),
        .aw_ready_i   (axi_aw_ready),

        // AXI write data
        .w_data_o     (axi_w_data),
        .w_strb_o     (axi_w_strb),
        .w_valid_o    (axi_w_valid),
        .w_ready_i    (axi_w_ready),

        // AXI write response
        .b_resp_i     (axi_b_resp),
        .b_valid_i    (axi_b_valid),
        .b_ready_o    (axi_b_ready),

        // AXI read address
        .ar_addr_o    (axi_ar_addr),
        .ar_prot_o    (),
        .ar_valid_o   (axi_ar_valid),
        .ar_ready_i   (axi_ar_ready),

        // AXI read data
        .r_data_i     (axi_r_data),
        .r_resp_i     (axi_r_resp),
        .r_valid_i    (axi_r_valid),
        .r_ready_o    (axi_r_ready)
    );

    boot_rom_1kB u_boot_rom (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),

        .instr_req_i    (instr_req),
        .instr_gnt_o    (instr_gnt),
        .instr_rvalid_o (instr_rvalid),
        .instr_addr_i   (instr_addr),
        .instr_rdata_o  (instr_rdata)
    );

    // =====================================================
    // AXI Peripheral wires - UART0 (0x8000_0200)
    // =====================================================
    logic [31:0] axi_awaddr;
    logic        axi_awvalid;
    logic        axi_awready;
    logic [31:0] axi_wdata;
    logic [3:0]  axi_wstrb;
    logic        axi_wvalid;
    logic        axi_wready;
    logic [1:0]  axi_bresp;
    logic        axi_bvalid;
    logic        axi_bready;
    logic [31:0] axi_araddr;
    logic        axi_arvalid;
    logic        axi_arready;
    logic [31:0] axi_rdata;
    logic [1:0]  axi_rresp;
    logic        axi_rvalid;
    logic        axi_rready;

    // =====================================================
    // UART0 (0x8000_0200) - 5-bit address
    // =====================================================
    axi_uart u_axi_uart0 (
        .S_AXI_ACLK    (clk_i),
        .S_AXI_ARESETN (rst_ni),
        .S_AXI_AWVALID (axi_awvalid),
        .S_AXI_AWREADY (axi_awready),
        .S_AXI_AWADDR  (axi_awaddr[4:0]),
        .S_AXI_AWPROT  (3'b000),
        .S_AXI_WVALID  (axi_wvalid),
        .S_AXI_WREADY  (axi_wready),
        .S_AXI_WDATA   (axi_wdata),
        .S_AXI_WSTRB   (axi_wstrb),
        .S_AXI_BVALID  (axi_bvalid),
        .S_AXI_BREADY  (axi_bready),
        .S_AXI_BRESP   (axi_bresp),
        .S_AXI_ARVALID (axi_arvalid),
        .S_AXI_ARREADY (axi_arready),
        .S_AXI_ARADDR  (axi_araddr[4:0]),
        .S_AXI_ARPROT  (3'b000),
        .S_AXI_RVALID  (axi_rvalid),
        .S_AXI_RREADY  (axi_rready),
        .S_AXI_RDATA   (axi_rdata),
        .S_AXI_RRESP   (axi_rresp),
        .uart_rx_i     (rx_i),
        .uart_tx_o     (tx_o)
    );

endmodule