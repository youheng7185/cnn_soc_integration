module cv32e40p_verilator_top (
    input logic clk_i,
    input logic rst_ni,
    input logic [15:0] gpio_in,
    output logic [15:0] gpio_out,
    input logic uart_rx_i,
    output logic uart_tx_o
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
        .mtvec_addr_i     (32'h8000_1E00),
        .dm_halt_addr_i   (32'h8000_1F00),
        .hart_id_i        (32'h0),
        .dm_exception_addr_i (32'h8000_1F08),

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

    // axi peripheral
    // data mem
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
    // AXI Peripheral wires - GPIO
    // =====================
    logic [31:0] gpio_axi_awaddr;
    logic        gpio_axi_awvalid;
    logic        gpio_axi_awready;
    logic [31:0] gpio_axi_wdata;
    logic [3:0]  gpio_axi_wstrb;
    logic        gpio_axi_wvalid;
    logic        gpio_axi_wready;
    logic [1:0]  gpio_axi_bresp;
    logic        gpio_axi_bvalid;
    logic        gpio_axi_bready;
    logic [31:0] gpio_axi_araddr;
    logic        gpio_axi_arvalid;
    logic        gpio_axi_arready;
    logic [31:0] gpio_axi_rdata;
    logic [1:0]  gpio_axi_rresp;
    logic        gpio_axi_rvalid;
    logic        gpio_axi_rready;

    // =====================
    // AXI Peripheral wires - Timer
    // =====================
    logic [31:0] timer_axi_awaddr;
    logic        timer_axi_awvalid;
    logic        timer_axi_awready;
    logic [31:0] timer_axi_wdata;
    logic [3:0]  timer_axi_wstrb;
    logic        timer_axi_wvalid;
    logic        timer_axi_wready;
    logic [1:0]  timer_axi_bresp;
    logic        timer_axi_bvalid;
    logic        timer_axi_bready;
    logic [31:0] timer_axi_araddr;
    logic        timer_axi_arvalid;
    logic        timer_axi_arready;
    logic [31:0] timer_axi_rdata;
    logic [1:0]  timer_axi_rresp;
    logic        timer_axi_rvalid;
    logic        timer_axi_rready;    

    // =====================
    // AXI Peripheral wires - UART
    // =====================
    logic [31:0] uart_axi_awaddr;
    logic        uart_axi_awvalid;
    logic        uart_axi_awready;
    logic [31:0] uart_axi_wdata;
    logic [3:0]  uart_axi_wstrb;
    logic        uart_axi_wvalid;
    logic        uart_axi_wready;
    logic [1:0]  uart_axi_bresp;
    logic        uart_axi_bvalid;
    logic        uart_axi_bready;
    logic [31:0] uart_axi_araddr;
    logic        uart_axi_arvalid;
    logic        uart_axi_arready;
    logic [31:0] uart_axi_rdata;
    logic [1:0]  uart_axi_rresp;
    logic        uart_axi_rvalid;
    logic        uart_axi_rready;

    // =====================
    // AXI Peripheral wires - I2C
    // =====================
    logic [31:0] i2c_axi_awaddr;
    logic        i2c_axi_awvalid;
    logic        i2c_axi_awready;
    logic [31:0] i2c_axi_wdata;
    logic [3:0]  i2c_axi_wstrb;
    logic        i2c_axi_wvalid;
    logic        i2c_axi_wready;
    logic [1:0]  i2c_axi_bresp;
    logic        i2c_axi_bvalid;
    logic        i2c_axi_bready;
    logic [31:0] i2c_axi_araddr;
    logic        i2c_axi_arvalid;
    logic        i2c_axi_arready;
    logic [31:0] i2c_axi_rdata;
    logic [1:0]  i2c_axi_rresp;
    logic        i2c_axi_rvalid;
    logic        i2c_axi_rready;

    // =====================
    // AXI Peripheral wires - QSPI
    // =====================
    logic [31:0] qspi_axi_awaddr;
    logic        qspi_axi_awvalid;
    logic        qspi_axi_awready;
    logic [31:0] qspi_axi_wdata;
    logic [3:0]  qspi_axi_wstrb;
    logic        qspi_axi_wvalid;
    logic        qspi_axi_wready;
    logic [1:0]  qspi_axi_bresp;
    logic        qspi_axi_bvalid;
    logic        qspi_axi_bready;
    logic [31:0] qspi_axi_araddr;
    logic        qspi_axi_arvalid;
    logic        qspi_axi_arready;
    logic [31:0] qspi_axi_rdata;
    logic [1:0]  qspi_axi_rresp;
    logic        qspi_axi_rvalid;
    logic        qspi_axi_rready;

    // =====================
    // AXI Peripheral wires - CNN Accelerator
    // =====================
    logic [31:0] cnn_axi_awaddr;
    logic        cnn_axi_awvalid;
    logic        cnn_axi_awready;
    logic [31:0] cnn_axi_wdata;
    logic [3:0]  cnn_axi_wstrb;
    logic        cnn_axi_wvalid;
    logic        cnn_axi_wready;
    logic [1:0]  cnn_axi_bresp;
    logic        cnn_axi_bvalid;
    logic        cnn_axi_bready;
    logic [31:0] cnn_axi_araddr;
    logic        cnn_axi_arvalid;
    logic        cnn_axi_arready;
    logic [31:0] cnn_axi_rdata;
    logic [1:0]  cnn_axi_rresp;
    logic        cnn_axi_rvalid;
    logic        cnn_axi_rready;


     // =====================
    // AXI Interconnect (1-to-6)
    // =====================

    axi_interconnect u_axi_interconnect (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),

        // Master interface (from core2axi)
        .m_axi_awaddr  (axi_aw_addr),
        .m_axi_awvalid (axi_aw_valid),
        .m_axi_awready (axi_aw_ready),
        .m_axi_wdata   (axi_w_data),
        .m_axi_wstrb   (axi_w_strb),
        .m_axi_wvalid  (axi_w_valid),
        .m_axi_wready  (axi_w_ready),
        .m_axi_bresp   (axi_b_resp),
        .m_axi_bvalid  (axi_b_valid),
        .m_axi_bready  (axi_b_ready),
        .m_axi_araddr  (axi_ar_addr),
        .m_axi_arvalid (axi_ar_valid),
        .m_axi_arready (axi_ar_ready),
        .m_axi_rdata   (axi_r_data),
        .m_axi_rresp   (axi_r_resp),
        .m_axi_rvalid  (axi_r_valid),
        .m_axi_rready  (axi_r_ready),

        // Slave 0: Data Memory (0x1000_0000)
        .s0_axi_awaddr  (data_mem_axi_awaddr),
        .s0_axi_awvalid (data_mem_axi_awvalid),
        .s0_axi_awready (data_mem_axi_awready),
        .s0_axi_wdata   (data_mem_axi_wdata),
        .s0_axi_wstrb   (data_mem_axi_wstrb),
        .s0_axi_wvalid  (data_mem_axi_wvalid),
        .s0_axi_wready  (data_mem_axi_wready),
        .s0_axi_bresp   (data_mem_axi_bresp),
        .s0_axi_bvalid  (data_mem_axi_bvalid),
        .s0_axi_bready  (data_mem_axi_bready),
        .s0_axi_araddr  (data_mem_axi_araddr),
        .s0_axi_arvalid (data_mem_axi_arvalid),
        .s0_axi_arready (data_mem_axi_arready),
        .s0_axi_rdata   (data_mem_axi_rdata),
        .s0_axi_rresp   (data_mem_axi_rresp),
        .s0_axi_rvalid  (data_mem_axi_rvalid),
        .s0_axi_rready  (data_mem_axi_rready),

        // Slave 1: GPIO (0x8000_0000) - 4-bit address
        .s1_axi_awaddr  (gpio_axi_awaddr),
        .s1_axi_awvalid (gpio_axi_awvalid),
        .s1_axi_awready (gpio_axi_awready),
        .s1_axi_wdata   (gpio_axi_wdata),
        .s1_axi_wstrb   (gpio_axi_wstrb),
        .s1_axi_wvalid  (gpio_axi_wvalid),
        .s1_axi_wready  (gpio_axi_wready),
        .s1_axi_bresp   (gpio_axi_bresp),
        .s1_axi_bvalid  (gpio_axi_bvalid),
        .s1_axi_bready  (gpio_axi_bready),
        .s1_axi_araddr  (gpio_axi_araddr),
        .s1_axi_arvalid (gpio_axi_arvalid),
        .s1_axi_arready (gpio_axi_arready),
        .s1_axi_rdata   (gpio_axi_rdata),
        .s1_axi_rresp   (gpio_axi_rresp),
        .s1_axi_rvalid  (gpio_axi_rvalid),
        .s1_axi_rready  (gpio_axi_rready),

        // Slave 2: Timer (0x8000_0100) - 5-bit address
        .s2_axi_awaddr  (timer_axi_awaddr),
        .s2_axi_awvalid (timer_axi_awvalid),
        .s2_axi_awready (timer_axi_awready),
        .s2_axi_wdata   (timer_axi_wdata),
        .s2_axi_wstrb   (timer_axi_wstrb),
        .s2_axi_wvalid  (timer_axi_wvalid),
        .s2_axi_wready  (timer_axi_wready),
        .s2_axi_bresp   (timer_axi_bresp),
        .s2_axi_bvalid  (timer_axi_bvalid),
        .s2_axi_bready  (timer_axi_bready),
        .s2_axi_araddr  (timer_axi_araddr),
        .s2_axi_arvalid (timer_axi_arvalid),
        .s2_axi_arready (timer_axi_arready),
        .s2_axi_rdata   (timer_axi_rdata),
        .s2_axi_rresp   (timer_axi_rresp),
        .s2_axi_rvalid  (timer_axi_rvalid),
        .s2_axi_rready  (timer_axi_rready),

        // Slave 3: UART (0x8000_0200) - 5-bit address
        .s3_axi_awaddr  (uart_axi_awaddr),
        .s3_axi_awvalid (uart_axi_awvalid),
        .s3_axi_awready (uart_axi_awready),
        .s3_axi_wdata   (uart_axi_wdata),
        .s3_axi_wstrb   (uart_axi_wstrb),
        .s3_axi_wvalid  (uart_axi_wvalid),
        .s3_axi_wready  (uart_axi_wready),
        .s3_axi_bresp   (uart_axi_bresp),
        .s3_axi_bvalid  (uart_axi_bvalid),
        .s3_axi_bready  (uart_axi_bready),
        .s3_axi_araddr  (uart_axi_araddr),
        .s3_axi_arvalid (uart_axi_arvalid),
        .s3_axi_arready (uart_axi_arready),
        .s3_axi_rdata   (uart_axi_rdata),
        .s3_axi_rresp   (uart_axi_rresp),
        .s3_axi_rvalid  (uart_axi_rvalid),
        .s3_axi_rready  (uart_axi_rready),

        // Slave 4: I2C (0x8000_0300) - 5-bit address
        .s4_axi_awaddr  (i2c_axi_awaddr),
        .s4_axi_awvalid (i2c_axi_awvalid),
        .s4_axi_awready (i2c_axi_awready),
        .s4_axi_wdata   (i2c_axi_wdata),
        .s4_axi_wstrb   (i2c_axi_wstrb),
        .s4_axi_wvalid  (i2c_axi_wvalid),
        .s4_axi_wready  (i2c_axi_wready),
        .s4_axi_bresp   (i2c_axi_bresp),
        .s4_axi_bvalid  (i2c_axi_bvalid),
        .s4_axi_bready  (i2c_axi_bready),
        .s4_axi_araddr  (i2c_axi_araddr),
        .s4_axi_arvalid (i2c_axi_arvalid),
        .s4_axi_arready (i2c_axi_arready),
        .s4_axi_rdata   (i2c_axi_rdata),
        .s4_axi_rresp   (i2c_axi_rresp),
        .s4_axi_rvalid  (i2c_axi_rvalid),
        .s4_axi_rready  (i2c_axi_rready),

        // Slave 5: QSPI (0x8000_0400) - 5-bit address
        .s5_axi_awaddr  (qspi_axi_awaddr),
        .s5_axi_awvalid (qspi_axi_awvalid),
        .s5_axi_awready (qspi_axi_awready),
        .s5_axi_wdata   (qspi_axi_wdata),
        .s5_axi_wstrb   (qspi_axi_wstrb),
        .s5_axi_wvalid  (qspi_axi_wvalid),
        .s5_axi_wready  (qspi_axi_wready),
        .s5_axi_bresp   (qspi_axi_bresp),
        .s5_axi_bvalid  (qspi_axi_bvalid),
        .s5_axi_bready  (qspi_axi_bready),
        .s5_axi_araddr  (qspi_axi_araddr),
        .s5_axi_arvalid (qspi_axi_arvalid),
        .s5_axi_arready (qspi_axi_arready),
        .s5_axi_rdata   (qspi_axi_rdata),
        .s5_axi_rresp   (qspi_axi_rresp),
        .s5_axi_rvalid  (qspi_axi_rvalid),
        .s5_axi_rready  (qspi_axi_rready),

        // Slave 6: CNN Accelerator (0x8000_1000)
        .s6_axi_awaddr  (cnn_axi_awaddr),
        .s6_axi_awvalid (cnn_axi_awvalid),
        .s6_axi_awready (cnn_axi_awready),
        .s6_axi_wdata   (cnn_axi_wdata),
        .s6_axi_wstrb   (cnn_axi_wstrb),
        .s6_axi_wvalid  (cnn_axi_wvalid),
        .s6_axi_wready  (cnn_axi_wready),
        .s6_axi_bresp   (cnn_axi_bresp),
        .s6_axi_bvalid  (cnn_axi_bvalid),
        .s6_axi_bready  (cnn_axi_bready),
        .s6_axi_araddr  (cnn_axi_araddr),
        .s6_axi_arvalid (cnn_axi_arvalid),
        .s6_axi_arready (cnn_axi_arready),
        .s6_axi_rdata   (cnn_axi_rdata),
        .s6_axi_rresp   (cnn_axi_rresp),
        .s6_axi_rvalid  (cnn_axi_rvalid),
        .s6_axi_rready  (cnn_axi_rready)
    );

    // 13-bit address = 8KB address space
    axi_data_mem u_axi_data_mem (
        .S_AXI_ACLK    (clk_i),
        .S_AXI_ARESETN (rst_ni),
        
        // Write address channel
        .S_AXI_AWVALID (data_mem_axi_awvalid),
        .S_AXI_AWREADY (data_mem_axi_awready),
        .S_AXI_AWADDR  (data_mem_axi_awaddr[12:0]),  // Use lower 13 bits
        .S_AXI_AWPROT  (3'b000),                      // Default protection
        
        // Write data channel
        .S_AXI_WVALID  (data_mem_axi_wvalid),
        .S_AXI_WREADY  (data_mem_axi_wready),
        .S_AXI_WDATA   (data_mem_axi_wdata),
        .S_AXI_WSTRB   (data_mem_axi_wstrb),
        
        // Write response channel
        .S_AXI_BVALID  (data_mem_axi_bvalid),
        .S_AXI_BREADY  (data_mem_axi_bready),
        .S_AXI_BRESP   (data_mem_axi_bresp),
        
        // Read address channel
        .S_AXI_ARVALID (data_mem_axi_arvalid),
        .S_AXI_ARREADY (data_mem_axi_arready),
        .S_AXI_ARADDR  (data_mem_axi_araddr[12:0]),  // Use lower 13 bits
        .S_AXI_ARPROT  (3'b000),                      // Default protection
        
        // Read data channel
        .S_AXI_RVALID  (data_mem_axi_rvalid),
        .S_AXI_RREADY  (data_mem_axi_rready),
        .S_AXI_RDATA   (data_mem_axi_rdata),
        .S_AXI_RRESP   (data_mem_axi_rresp)
    );

    // =====================
    // GPIO Peripheral (0x8000_0000)
    // 4-bit address
    // =====================
    axi_gpio u_axi_gpio (
        .S_AXI_ACLK    (clk_i),
        .S_AXI_ARESETN (rst_ni),

        // Write address channel
        .S_AXI_AWVALID (gpio_axi_awvalid),
        .S_AXI_AWREADY (gpio_axi_awready),
        .S_AXI_AWADDR  (gpio_axi_awaddr[3:0]),
        .S_AXI_AWPROT  (3'b000),

        // Write data channel
        .S_AXI_WVALID  (gpio_axi_wvalid),
        .S_AXI_WREADY  (gpio_axi_wready),
        .S_AXI_WDATA   (gpio_axi_wdata),
        .S_AXI_WSTRB   (gpio_axi_wstrb),

        // Write response
        .S_AXI_BVALID  (gpio_axi_bvalid),
        .S_AXI_BREADY  (gpio_axi_bready),
        .S_AXI_BRESP   (gpio_axi_bresp),

        // Read address channel
        .S_AXI_ARVALID (gpio_axi_arvalid),
        .S_AXI_ARREADY (gpio_axi_arready),
        .S_AXI_ARADDR  (gpio_axi_araddr[3:0]),
        .S_AXI_ARPROT  (3'b000),

        // Read data channel
        .S_AXI_RVALID  (gpio_axi_rvalid),
        .S_AXI_RREADY  (gpio_axi_rready),
        .S_AXI_RDATA   (gpio_axi_rdata),
        .S_AXI_RRESP   (gpio_axi_rresp),

        // GPIO pins
        .gpio_in       (gpio_in),
        .gpio_out      (gpio_out)
    );

    // =====================
    // Timer Peripheral (0x8000_0100)
    // 5-bit address
    // =====================
    axi_timer u_axi_timer (
        .S_AXI_ACLK    (clk_i),
        .S_AXI_ARESETN (rst_ni),

        // Write address channel
        .S_AXI_AWVALID (timer_axi_awvalid),
        .S_AXI_AWREADY (timer_axi_awready),
        .S_AXI_AWADDR  (timer_axi_awaddr[4:0]),
        .S_AXI_AWPROT  (3'b000),

        // Write data channel
        .S_AXI_WVALID  (timer_axi_wvalid),
        .S_AXI_WREADY  (timer_axi_wready),
        .S_AXI_WDATA   (timer_axi_wdata),
        .S_AXI_WSTRB   (timer_axi_wstrb),

        // Write response
        .S_AXI_BVALID  (timer_axi_bvalid),
        .S_AXI_BREADY  (timer_axi_bready),
        .S_AXI_BRESP   (timer_axi_bresp),

        // Read address channel
        .S_AXI_ARVALID (timer_axi_arvalid),
        .S_AXI_ARREADY (timer_axi_arready),
        .S_AXI_ARADDR  (timer_axi_araddr[4:0]),
        .S_AXI_ARPROT  (3'b000),

        // Read data channel
        .S_AXI_RVALID  (timer_axi_rvalid),
        .S_AXI_RREADY  (timer_axi_rready),
        .S_AXI_RDATA   (timer_axi_rdata),
        .S_AXI_RRESP   (timer_axi_rresp)
    );

    // =====================
    // UART Peripheral (0x8000_0200)
    // 5-bit address
    // =====================
    axi_uart u_axi_uart (
        .S_AXI_ACLK    (clk_i),
        .S_AXI_ARESETN (rst_ni),

        // Write address channel
        .S_AXI_AWVALID (uart_axi_awvalid),
        .S_AXI_AWREADY (uart_axi_awready),
        .S_AXI_AWADDR  (uart_axi_awaddr[4:0]),
        .S_AXI_AWPROT  (3'b000),

        // Write data channel
        .S_AXI_WVALID  (uart_axi_wvalid),
        .S_AXI_WREADY  (uart_axi_wready),
        .S_AXI_WDATA   (uart_axi_wdata),
        .S_AXI_WSTRB   (uart_axi_wstrb),

        // Write response
        .S_AXI_BVALID  (uart_axi_bvalid),
        .S_AXI_BREADY  (uart_axi_bready),
        .S_AXI_BRESP   (uart_axi_bresp),

        // Read address channel
        .S_AXI_ARVALID (uart_axi_arvalid),
        .S_AXI_ARREADY (uart_axi_arready),
        .S_AXI_ARADDR  (uart_axi_araddr[4:0]),
        .S_AXI_ARPROT  (3'b000),

        // Read data channel
        .S_AXI_RVALID  (uart_axi_rvalid),
        .S_AXI_RREADY  (uart_axi_rready),
        .S_AXI_RDATA   (uart_axi_rdata),
        .S_AXI_RRESP   (uart_axi_rresp),

        // UART signals
        .uart_rx_i     (uart_rx_i),
        .uart_tx_o     (uart_tx_o)
    );
    

endmodule
