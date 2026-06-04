module axi_interconnect (
    // =====================================================
    // Master interface (from core2axi)
    // =====================================================
    // Write address channel
    input  wire [31:0] m_axi_awaddr,
    input  wire        m_axi_awvalid,
    output wire        m_axi_awready,

    // Write data channel
    input  wire [31:0] m_axi_wdata,
    input  wire [3:0]  m_axi_wstrb,
    input  wire        m_axi_wvalid,
    output wire        m_axi_wready,

    // Write response channel
    output wire [1:0]  m_axi_bresp,
    output wire        m_axi_bvalid,
    input  wire        m_axi_bready,

    // Read address channel
    input  wire [31:0] m_axi_araddr,
    input  wire        m_axi_arvalid,
    output wire        m_axi_arready,

    // Read data channel
    output wire [31:0] m_axi_rdata,
    output wire [1:0]  m_axi_rresp,
    output wire        m_axi_rvalid,
    input  wire        m_axi_rready,

    // =====================================================
    // Slave 0: Data Memory (0x1000_0000, 8KB)
    // =====================================================
    output wire [31:0] s0_axi_awaddr,
    output wire        s0_axi_awvalid,
    input  wire        s0_axi_awready,

    output wire [31:0] s0_axi_wdata,
    output wire [3:0]  s0_axi_wstrb,
    output wire        s0_axi_wvalid,
    input  wire        s0_axi_wready,

    input  wire [1:0]  s0_axi_bresp,
    input  wire        s0_axi_bvalid,
    output wire        s0_axi_bready,

    output wire [31:0] s0_axi_araddr,
    output wire        s0_axi_arvalid,
    input  wire        s0_axi_arready,

    input  wire [31:0] s0_axi_rdata,
    input  wire [1:0]  s0_axi_rresp,
    input  wire        s0_axi_rvalid,
    output wire        s0_axi_rready,

    // =====================================================
    // Slave 1: Instruction Memory (0x2000_0000, 8KB)
    // =====================================================
    output wire [31:0] s1_axi_awaddr,
    output wire        s1_axi_awvalid,
    input  wire        s1_axi_awready,

    output wire [31:0] s1_axi_wdata,
    output wire [3:0]  s1_axi_wstrb,
    output wire        s1_axi_wvalid,
    input  wire        s1_axi_wready,

    input  wire [1:0]  s1_axi_bresp,
    input  wire        s1_axi_bvalid,
    output wire        s1_axi_bready,

    output wire [31:0] s1_axi_araddr,
    output wire        s1_axi_arvalid,
    input  wire        s1_axi_arready,

    input  wire [31:0] s1_axi_rdata,
    input  wire [1:0]  s1_axi_rresp,
    input  wire        s1_axi_rvalid,
    output wire        s1_axi_rready,

    // =====================================================
    // Slave 2: GPIO (0x8000_0000)
    // =====================================================
    output wire [31:0] s2_axi_awaddr,
    output wire        s2_axi_awvalid,
    input  wire        s2_axi_awready,

    output wire [31:0] s2_axi_wdata,
    output wire [3:0]  s2_axi_wstrb,
    output wire        s2_axi_wvalid,
    input  wire        s2_axi_wready,

    input  wire [1:0]  s2_axi_bresp,
    input  wire        s2_axi_bvalid,
    output wire        s2_axi_bready,

    output wire [31:0] s2_axi_araddr,
    output wire        s2_axi_arvalid,
    input  wire        s2_axi_arready,

    input  wire [31:0] s2_axi_rdata,
    input  wire [1:0]  s2_axi_rresp,
    input  wire        s2_axi_rvalid,
    output wire        s2_axi_rready,

    // =====================================================
    // Slave 3: Timer (0x8000_0100)
    // =====================================================
    output wire [31:0] s3_axi_awaddr,
    output wire        s3_axi_awvalid,
    input  wire        s3_axi_awready,

    output wire [31:0] s3_axi_wdata,
    output wire [3:0]  s3_axi_wstrb,
    output wire        s3_axi_wvalid,
    input  wire        s3_axi_wready,

    input  wire [1:0]  s3_axi_bresp,
    input  wire        s3_axi_bvalid,
    output wire        s3_axi_bready,

    output wire [31:0] s3_axi_araddr,
    output wire        s3_axi_arvalid,
    input  wire        s3_axi_arready,

    input  wire [31:0] s3_axi_rdata,
    input  wire [1:0]  s3_axi_rresp,
    input  wire        s3_axi_rvalid,
    output wire        s3_axi_rready,

    // =====================================================
    // Slave 4: UART0 (0x8000_0200)
    // =====================================================
    output wire [31:0] s4_axi_awaddr,
    output wire        s4_axi_awvalid,
    input  wire        s4_axi_awready,

    output wire [31:0] s4_axi_wdata,
    output wire [3:0]  s4_axi_wstrb,
    output wire        s4_axi_wvalid,
    input  wire        s4_axi_wready,

    input  wire [1:0]  s4_axi_bresp,
    input  wire        s4_axi_bvalid,
    output wire        s4_axi_bready,

    output wire [31:0] s4_axi_araddr,
    output wire        s4_axi_arvalid,
    input  wire        s4_axi_arready,

    input  wire [31:0] s4_axi_rdata,
    input  wire [1:0]  s4_axi_rresp,
    input  wire        s4_axi_rvalid,
    output wire        s4_axi_rready,

    // =====================================================
    // Slave 5: UART1 (0x8000_0300)
    // =====================================================
    output wire [31:0] s5_axi_awaddr,
    output wire        s5_axi_awvalid,
    input  wire        s5_axi_awready,

    output wire [31:0] s5_axi_wdata,
    output wire [3:0]  s5_axi_wstrb,
    output wire        s5_axi_wvalid,
    input  wire        s5_axi_wready,

    input  wire [1:0]  s5_axi_bresp,
    input  wire        s5_axi_bvalid,
    output wire        s5_axi_bready,

    output wire [31:0] s5_axi_araddr,
    output wire        s5_axi_arvalid,
    input  wire        s5_axi_arready,

    input  wire [31:0] s5_axi_rdata,
    input  wire [1:0]  s5_axi_rresp,
    input  wire        s5_axi_rvalid,
    output wire        s5_axi_rready,

    /* verilator lint_off PINMISSING */
    // =====================================================
    // Slave 6: I2C (0x8000_0400)
    // =====================================================
    output wire [31:0] s6_axi_awaddr,
    output wire        s6_axi_awvalid,
    input  wire        s6_axi_awready,

    output wire [31:0] s6_axi_wdata,
    output wire [3:0]  s6_axi_wstrb,
    output wire        s6_axi_wvalid,
    input  wire        s6_axi_wready,

    input  wire [1:0]  s6_axi_bresp,
    input  wire        s6_axi_bvalid,
    output wire        s6_axi_bready,

    output wire [31:0] s6_axi_araddr,
    output wire        s6_axi_arvalid,
    input  wire        s6_axi_arready,

    input  wire [31:0] s6_axi_rdata,
    input  wire [1:0]  s6_axi_rresp,
    input  wire        s6_axi_rvalid,
    output wire        s6_axi_rready,

    /* verilator lint_off PINMISSING */
    // =====================================================
    // Slave 7: QSPI (0x8000_0500)
    // =====================================================
    output wire [31:0] s7_axi_awaddr,
    output wire        s7_axi_awvalid,
    input  wire        s7_axi_awready,

    output wire [31:0] s7_axi_wdata,
    output wire [3:0]  s7_axi_wstrb,
    output wire        s7_axi_wvalid,
    input  wire        s7_axi_wready,

    input  wire [1:0]  s7_axi_bresp,
    input  wire        s7_axi_bvalid,
    output wire        s7_axi_bready,

    output wire [31:0] s7_axi_araddr,
    output wire        s7_axi_arvalid,
    input  wire        s7_axi_arready,

    input  wire [31:0] s7_axi_rdata,
    input  wire [1:0]  s7_axi_rresp,
    input  wire        s7_axi_rvalid,
    output wire        s7_axi_rready,

    /* verilator lint_off PINMISSING */
    // =====================================================
    // Slave 8: CNN Accelerator (0x8000_1000)
    // =====================================================
    output wire [31:0] s8_axi_awaddr,
    output wire        s8_axi_awvalid,
    input  wire        s8_axi_awready,

    output wire [31:0] s8_axi_wdata,
    output wire [3:0]  s8_axi_wstrb,
    output wire        s8_axi_wvalid,
    input  wire        s8_axi_wready,

    input  wire [1:0]  s8_axi_bresp,
    input  wire        s8_axi_bvalid,
    output wire        s8_axi_bready,

    output wire [31:0] s8_axi_araddr,
    output wire        s8_axi_arvalid,
    input  wire        s8_axi_arready,

    input  wire [31:0] s8_axi_rdata,
    input  wire [1:0]  s8_axi_rresp,
    input  wire        s8_axi_rvalid,
    output wire        s8_axi_rready
);

    // =====================================================
    // Address decoding parameters
    // =====================================================
    // Memory slaves — decoded on upper nibble (bits [31:28])
    localparam logic [31:0] DATA_MEM_BASE  = 32'h1000_0000;
    localparam logic [31:0] INSTR_MEM_BASE = 32'h2000_0000;
    localparam logic [31:0] MEM_MASK       = 32'hF000_0000;

    // Peripheral slaves — decoded on upper 24 bits (bits [31:8])
    localparam logic [31:0] GPIO_BASE      = 32'h8000_0000;
    localparam logic [31:0] TIMER_BASE     = 32'h8000_0100;
    localparam logic [31:0] UART0_BASE     = 32'h8000_0200;
    localparam logic [31:0] UART1_BASE     = 32'h8000_0300;
    localparam logic [31:0] I2C_BASE       = 32'h8000_0400;
    localparam logic [31:0] QSPI_BASE      = 32'h8000_0500;
    localparam logic [31:0] PERIPH_MASK    = 32'hFFFF_FF00;

    // CNN — decoded on upper 20 bits (bits [31:12])
    localparam logic [31:0] CNN_BASE       = 32'h8000_1000;
    localparam logic [31:0] CNN_MASK       = 32'hFFFF_F000;

    // =====================================================
    // Slave selection signals
    // Bit mapping:
    //   [0] Data Memory   [1] Instr Memory  [2] GPIO
    //   [3] Timer         [4] UART0         [5] UART1
    //   [6] I2C           [7] QSPI          [8] CNN
    // =====================================================
    logic [8:0] aw_slave_sel;
    logic [8:0] ar_slave_sel;

    // =====================================================
    // Address decoding task (shared decode logic)
    // Priority order matters: MEM_MASK checked first, then
    // CNN_MASK (larger region inside 0x8000_xxxx), then
    // PERIPH_MASK for the 256-byte-granularity peripherals.
    // =====================================================
    // function automatic [8:0] decode_addr(input logic [31:0] addr);
    //     logic [8:0] sel;
    //     sel = 9'b0;
    //     if      ((addr & MEM_MASK)    == DATA_MEM_BASE)  sel[0] = 1'b1;
    //     else if ((addr & MEM_MASK)    == INSTR_MEM_BASE) sel[1] = 1'b1;
    //     else if ((addr & CNN_MASK)    == CNN_BASE)        sel[8] = 1'b1;
    //     else if ((addr & PERIPH_MASK) == GPIO_BASE)       sel[2] = 1'b1;
    //     else if ((addr & PERIPH_MASK) == TIMER_BASE)      sel[3] = 1'b1;
    //     else if ((addr & PERIPH_MASK) == UART0_BASE)      sel[4] = 1'b1;
    //     else if ((addr & PERIPH_MASK) == UART1_BASE)      sel[5] = 1'b1;
    //     else if ((addr & PERIPH_MASK) == I2C_BASE)        sel[6] = 1'b1;
    //     else if ((addr & PERIPH_MASK) == QSPI_BASE)       sel[7] = 1'b1;
    //     return sel;
    // endfunction
    function automatic [8:0] decode_addr(input logic [31:0] addr);
        logic [8:0] sel;
        begin
            sel = 9'b0;

            if      ((addr & MEM_MASK)    == DATA_MEM_BASE)  sel[0] = 1'b1;
            else if ((addr & MEM_MASK)    == INSTR_MEM_BASE) sel[1] = 1'b1;
            else if ((addr & CNN_MASK)    == CNN_BASE)       sel[8] = 1'b1;
            else if ((addr & PERIPH_MASK) == GPIO_BASE)      sel[2] = 1'b1;
            else if ((addr & PERIPH_MASK) == TIMER_BASE)     sel[3] = 1'b1;
            else if ((addr & PERIPH_MASK) == UART0_BASE)     sel[4] = 1'b1;
            else if ((addr & PERIPH_MASK) == UART1_BASE)     sel[5] = 1'b1;
            else if ((addr & PERIPH_MASK) == I2C_BASE)       sel[6] = 1'b1;
            else if ((addr & PERIPH_MASK) == QSPI_BASE)      sel[7] = 1'b1;

            decode_addr = sel;
        end
    endfunction
    
    // =====================================================
    // Address decoding — Write Address Channel
    // =====================================================
    always_comb begin
        aw_slave_sel = 9'b0;
        if (m_axi_awvalid)
            aw_slave_sel = decode_addr(m_axi_awaddr);
    end

    // =====================================================
    // Address decoding — Read Address Channel
    // =====================================================
    always_comb begin
        ar_slave_sel = 9'b0;
        if (m_axi_arvalid)
            ar_slave_sel = decode_addr(m_axi_araddr);
    end

    // =====================================================
    // Write address channel routing
    // =====================================================
    assign s0_axi_awaddr  = m_axi_awaddr;
    assign s0_axi_awvalid = m_axi_awvalid & aw_slave_sel[0];

    assign s1_axi_awaddr  = m_axi_awaddr;
    assign s1_axi_awvalid = m_axi_awvalid & aw_slave_sel[1];

    assign s2_axi_awaddr  = m_axi_awaddr;
    assign s2_axi_awvalid = m_axi_awvalid & aw_slave_sel[2];

    assign s3_axi_awaddr  = m_axi_awaddr;
    assign s3_axi_awvalid = m_axi_awvalid & aw_slave_sel[3];

    assign s4_axi_awaddr  = m_axi_awaddr;
    assign s4_axi_awvalid = m_axi_awvalid & aw_slave_sel[4];

    assign s5_axi_awaddr  = m_axi_awaddr;
    assign s5_axi_awvalid = m_axi_awvalid & aw_slave_sel[5];

    assign s6_axi_awaddr  = m_axi_awaddr;
    assign s6_axi_awvalid = m_axi_awvalid & aw_slave_sel[6];

    assign s7_axi_awaddr  = m_axi_awaddr;
    assign s7_axi_awvalid = m_axi_awvalid & aw_slave_sel[7];

    assign s8_axi_awaddr  = m_axi_awaddr;
    assign s8_axi_awvalid = m_axi_awvalid & aw_slave_sel[8];

    assign m_axi_awready = (s0_axi_awready & aw_slave_sel[0]) |
                           (s1_axi_awready & aw_slave_sel[1]) |
                           (s2_axi_awready & aw_slave_sel[2]) |
                           (s3_axi_awready & aw_slave_sel[3]) |
                           (s4_axi_awready & aw_slave_sel[4]) |
                           (s5_axi_awready & aw_slave_sel[5]) |
                           (s6_axi_awready & aw_slave_sel[6]) |
                           (s7_axi_awready & aw_slave_sel[7]) |
                           (s8_axi_awready & aw_slave_sel[8]);

    // =====================================================
    // Write data channel routing
    // =====================================================
    assign s0_axi_wdata  = m_axi_wdata;
    assign s0_axi_wstrb  = m_axi_wstrb;
    assign s0_axi_wvalid = m_axi_wvalid & aw_slave_sel[0];

    assign s1_axi_wdata  = m_axi_wdata;
    assign s1_axi_wstrb  = m_axi_wstrb;
    assign s1_axi_wvalid = m_axi_wvalid & aw_slave_sel[1];

    assign s2_axi_wdata  = m_axi_wdata;
    assign s2_axi_wstrb  = m_axi_wstrb;
    assign s2_axi_wvalid = m_axi_wvalid & aw_slave_sel[2];

    assign s3_axi_wdata  = m_axi_wdata;
    assign s3_axi_wstrb  = m_axi_wstrb;
    assign s3_axi_wvalid = m_axi_wvalid & aw_slave_sel[3];

    assign s4_axi_wdata  = m_axi_wdata;
    assign s4_axi_wstrb  = m_axi_wstrb;
    assign s4_axi_wvalid = m_axi_wvalid & aw_slave_sel[4];

    assign s5_axi_wdata  = m_axi_wdata;
    assign s5_axi_wstrb  = m_axi_wstrb;
    assign s5_axi_wvalid = m_axi_wvalid & aw_slave_sel[5];

    assign s6_axi_wdata  = m_axi_wdata;
    assign s6_axi_wstrb  = m_axi_wstrb;
    assign s6_axi_wvalid = m_axi_wvalid & aw_slave_sel[6];

    assign s7_axi_wdata  = m_axi_wdata;
    assign s7_axi_wstrb  = m_axi_wstrb;
    assign s7_axi_wvalid = m_axi_wvalid & aw_slave_sel[7];

    assign s8_axi_wdata  = m_axi_wdata;
    assign s8_axi_wstrb  = m_axi_wstrb;
    assign s8_axi_wvalid = m_axi_wvalid & aw_slave_sel[8];

    assign m_axi_wready = (s0_axi_wready & aw_slave_sel[0]) |
                          (s1_axi_wready & aw_slave_sel[1]) |
                          (s2_axi_wready & aw_slave_sel[2]) |
                          (s3_axi_wready & aw_slave_sel[3]) |
                          (s4_axi_wready & aw_slave_sel[4]) |
                          (s5_axi_wready & aw_slave_sel[5]) |
                          (s6_axi_wready & aw_slave_sel[6]) |
                          (s7_axi_wready & aw_slave_sel[7]) |
                          (s8_axi_wready & aw_slave_sel[8]);

    // =====================================================
    // Write response channel routing
    // =====================================================
    assign s0_axi_bready = m_axi_bready;
    assign s1_axi_bready = m_axi_bready;
    assign s2_axi_bready = m_axi_bready;
    assign s3_axi_bready = m_axi_bready;
    assign s4_axi_bready = m_axi_bready;
    assign s5_axi_bready = m_axi_bready;
    assign s6_axi_bready = m_axi_bready;
    assign s7_axi_bready = m_axi_bready;
    assign s8_axi_bready = m_axi_bready;

    assign m_axi_bresp = s0_axi_bvalid ? s0_axi_bresp :
                         s1_axi_bvalid ? s1_axi_bresp :
                         s2_axi_bvalid ? s2_axi_bresp :
                         s3_axi_bvalid ? s3_axi_bresp :
                         s4_axi_bvalid ? s4_axi_bresp :
                         s5_axi_bvalid ? s5_axi_bresp :
                         s6_axi_bvalid ? s6_axi_bresp :
                         s7_axi_bvalid ? s7_axi_bresp :
                         s8_axi_bvalid ? s8_axi_bresp :
                         2'b00;

    assign m_axi_bvalid = s0_axi_bvalid |
                          s1_axi_bvalid |
                          s2_axi_bvalid |
                          s3_axi_bvalid |
                          s4_axi_bvalid |
                          s5_axi_bvalid |
                          s6_axi_bvalid |
                          s7_axi_bvalid |
                          s8_axi_bvalid;

    // =====================================================
    // Read address channel routing
    // =====================================================
    assign s0_axi_araddr  = m_axi_araddr;
    assign s0_axi_arvalid = m_axi_arvalid & ar_slave_sel[0];

    assign s1_axi_araddr  = m_axi_araddr;
    assign s1_axi_arvalid = m_axi_arvalid & ar_slave_sel[1];

    assign s2_axi_araddr  = m_axi_araddr;
    assign s2_axi_arvalid = m_axi_arvalid & ar_slave_sel[2];

    assign s3_axi_araddr  = m_axi_araddr;
    assign s3_axi_arvalid = m_axi_arvalid & ar_slave_sel[3];

    assign s4_axi_araddr  = m_axi_araddr;
    assign s4_axi_arvalid = m_axi_arvalid & ar_slave_sel[4];

    assign s5_axi_araddr  = m_axi_araddr;
    assign s5_axi_arvalid = m_axi_arvalid & ar_slave_sel[5];

    assign s6_axi_araddr  = m_axi_araddr;
    assign s6_axi_arvalid = m_axi_arvalid & ar_slave_sel[6];

    assign s7_axi_araddr  = m_axi_araddr;
    assign s7_axi_arvalid = m_axi_arvalid & ar_slave_sel[7];

    assign s8_axi_araddr  = m_axi_araddr;
    assign s8_axi_arvalid = m_axi_arvalid & ar_slave_sel[8];

    assign m_axi_arready = (s0_axi_arready & ar_slave_sel[0]) |
                           (s1_axi_arready & ar_slave_sel[1]) |
                           (s2_axi_arready & ar_slave_sel[2]) |
                           (s3_axi_arready & ar_slave_sel[3]) |
                           (s4_axi_arready & ar_slave_sel[4]) |
                           (s5_axi_arready & ar_slave_sel[5]) |
                           (s6_axi_arready & ar_slave_sel[6]) |
                           (s7_axi_arready & ar_slave_sel[7]) |
                           (s8_axi_arready & ar_slave_sel[8]);

    // =====================================================
    // Read data channel routing
    // =====================================================
    assign s0_axi_rready = m_axi_rready;
    assign s1_axi_rready = m_axi_rready;
    assign s2_axi_rready = m_axi_rready;
    assign s3_axi_rready = m_axi_rready;
    assign s4_axi_rready = m_axi_rready;
    assign s5_axi_rready = m_axi_rready;
    assign s6_axi_rready = m_axi_rready;
    assign s7_axi_rready = m_axi_rready;
    assign s8_axi_rready = m_axi_rready;

    assign m_axi_rdata = s0_axi_rvalid ? s0_axi_rdata :
                         s1_axi_rvalid ? s1_axi_rdata :
                         s2_axi_rvalid ? s2_axi_rdata :
                         s3_axi_rvalid ? s3_axi_rdata :
                         s4_axi_rvalid ? s4_axi_rdata :
                         s5_axi_rvalid ? s5_axi_rdata :
                         s6_axi_rvalid ? s6_axi_rdata :
                         s7_axi_rvalid ? s7_axi_rdata :
                         s8_axi_rvalid ? s8_axi_rdata :
                         32'h0;

    assign m_axi_rresp = s0_axi_rvalid ? s0_axi_rresp :
                         s1_axi_rvalid ? s1_axi_rresp :
                         s2_axi_rvalid ? s2_axi_rresp :
                         s3_axi_rvalid ? s3_axi_rresp :
                         s4_axi_rvalid ? s4_axi_rresp :
                         s5_axi_rvalid ? s5_axi_rresp :
                         s6_axi_rvalid ? s6_axi_rresp :
                         s7_axi_rvalid ? s7_axi_rresp :
                         s8_axi_rvalid ? s8_axi_rresp :
                         2'b00;

    assign m_axi_rvalid = s0_axi_rvalid |
                          s1_axi_rvalid |
                          s2_axi_rvalid |
                          s3_axi_rvalid |
                          s4_axi_rvalid |
                          s5_axi_rvalid |
                          s6_axi_rvalid |
                          s7_axi_rvalid |
                          s8_axi_rvalid;

endmodule