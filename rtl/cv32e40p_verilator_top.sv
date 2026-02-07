module cv32e40p_verilator_top (
    input logic clk_i,
    input logic rst_ni
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
    // Memory wires
    // =====================
    logic        mem_req;
    logic        mem_gnt;
    logic        mem_rvalid;
    logic        mem_we;
    logic [3:0]  mem_be;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;

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

    // Boot ROM
    logic        boot_req;
    logic        boot_gnt;
    logic        boot_rvalid;
    logic [31:0] boot_addr;
    logic [31:0] boot_rdata;

    // IMEM
    logic        imem_req;
    logic        imem_gnt;
    logic        imem_rvalid;
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

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
        .mtvec_addr_i     (32'h0000_0100),
        .dm_halt_addr_i   (32'h0000_0800),
        .hart_id_i        (32'h0),
        .dm_exception_addr_i (32'h0000_0808),

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
        .irq_i            (32'h0),
        .irq_ack_o        (),
        .irq_id_o         (),
        .debug_req_i      (1'b0),
        .debug_havereset_o(),
        .debug_running_o  (),
        .debug_halted_o   (),
        .fetch_enable_i   (1'b1),
        .core_sleep_o     ()
    );

    // data bus decoder
    data_bus_decoder u_decoder (
        .data_req_i    (data_req),
        .data_gnt_o    (data_gnt),
        .data_rvalid_o (data_rvalid),
        .data_we_i     (data_we),
        .data_be_i     (data_be),
        .data_addr_i   (data_addr),
        .data_wdata_i  (data_wdata),
        .data_rdata_o  (data_rdata),

        .mem_req_o     (mem_req),
        .mem_gnt_i     (mem_gnt),
        .mem_rvalid_i  (mem_rvalid),
        .mem_we_o      (mem_we),
        .mem_be_o      (mem_be),
        .mem_addr_o    (mem_addr),
        .mem_wdata_o   (mem_wdata),
        .mem_rdata_i   (mem_rdata),

        .axi_req_o     (axi_req),
        .axi_gnt_i     (axi_gnt),
        .axi_rvalid_i  (axi_rvalid),
        .axi_we_o      (axi_we),
        .axi_be_o      (axi_be),
        .axi_addr_o    (axi_addr),
        .axi_wdata_o   (axi_wdata),
        .axi_rdata_i   (axi_rdata)
    );

    data_mem_8kB u_dmem (
        .clk_core      (clk_i),
        .rst_core_n    (rst_ni),
        .dmem_req_i    (mem_req),
        .dmem_gnt_o    (mem_gnt),
        .dmem_rvalid_o (mem_rvalid),
        .dmem_we_i     (mem_we),
        .dmem_be_i     (mem_be),
        .dmem_addr_i   (mem_addr),
        .dmem_wdata_i  (mem_wdata),
        .dmem_rdata_o  (mem_rdata)
    );

    core2axi u_core2axi (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),

        // cv32e40p data bus
        .data_req_i    (axi_req),
        .data_gnt_o    (axi_gnt),
        .data_rvalid_o (axi_rvalid),
        .data_addr_i  (axi_addr),
        .data_we_i    (axi_we),
        .data_be_i    (axi_be),
        .data_rdata_o (axi_rdata),
        .data_wdata_i (axi_wdata),

        // AXI write address
        .aw_addr_o    (axi_aw_addr),
        .aw_prot_o    (),
        .aw_valid_o   (axi_aw_valid),
        .aw_ready_i   (axi_aw_ready),

        // AXI write data
        .w_data_o     (axi_w_data),
        .w_strb_o     (axi_w_strb),
        .w_valid_o    (axi_w_valid),
        .w_ready_i   (axi_w_ready),

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


    instr_bus_decoder u_instr_decoder (
        .instr_req_i    (instr_req),
        .instr_gnt_o    (instr_gnt),
        .instr_rvalid_o (instr_rvalid),
        .instr_addr_i   (instr_addr),
        .instr_rdata_o  (instr_rdata),

        .boot_req_o     (boot_req),
        .boot_gnt_i     (boot_gnt),
        .boot_rvalid_i  (boot_rvalid),
        .boot_addr_o    (boot_addr),
        .boot_rdata_i   (boot_rdata),

        .imem_req_o     (imem_req),
        .imem_gnt_i     (imem_gnt),
        .imem_rvalid_i  (imem_rvalid),
        .imem_addr_o    (imem_addr),
        .imem_rdata_i   (imem_rdata)
    );

    boot_rom_1kB u_boot_rom (
        .clk_core      (clk_i),
        .rst_core_n    (rst_ni),

        .instr_req_i    (boot_req),
        .instr_gnt_o    (boot_gnt),
        .instr_rvalid_o (boot_rvalid),
        .instr_addr_i   (boot_addr),
        .instr_rdata_o  (boot_rdata)
    );

    instr_rom_8kB u_imem (
        .clk_core      (clk_i),
        .rst_core_n    (rst_ni),

        .instr_req_i    (imem_req),
        .instr_gnt_o    (imem_gnt),
        .instr_rvalid_o (imem_rvalid),
        .instr_addr_i   (imem_addr),
        .instr_rdata_o  (imem_rdata)
    );

    localparam GPIO_BASE = 32'h8000_0000;

    axi_gpio u_axi_gpio (
        .S_AXI_ACLK    (clk_i),
        .S_AXI_ARESETN (rst_ni),

        // -------------------------
        // Write address channel
        // -------------------------
        .S_AXI_AWVALID (axi_aw_valid),
        .S_AXI_AWREADY (axi_aw_ready),
        .S_AXI_AWADDR  (axi_aw_addr[5:2]), // 4-bit word address

        // -------------------------
        // Write data channel
        // -------------------------
        .S_AXI_WVALID  (axi_w_valid),
        .S_AXI_WREADY  (axi_w_ready),
        .S_AXI_WDATA   (axi_w_data),
        .S_AXI_WSTRB  (axi_w_strb),

        // -------------------------
        // Write response
        // -------------------------
        .S_AXI_BVALID  (axi_b_valid),
        .S_AXI_BREADY  (axi_b_ready),
        .S_AXI_BRESP   (axi_b_resp),

        // -------------------------
        // Read address channel
        // -------------------------
        .S_AXI_ARVALID (axi_ar_valid),
        .S_AXI_ARREADY (axi_ar_ready),
        .S_AXI_ARADDR  (axi_ar_addr[5:2]),

        // -------------------------
        // Read data channel
        // -------------------------
        .S_AXI_RVALID  (axi_r_valid),
        .S_AXI_RREADY  (axi_r_ready),
        .S_AXI_RDATA   (axi_r_data),
        .S_AXI_RRESP   (axi_r_resp),

        // -------------------------
        // GPIO pins
        // -------------------------
        .gpio_in       (gpio_in),
        .gpio_out      (gpio_out)
    );

endmodule
