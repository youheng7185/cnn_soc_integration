module instr_rom_8kB #(
    parameter  C_AXI_ADDR_WIDTH = 13,
    localparam C_AXI_DATA_WIDTH = 32,
    parameter [0:0] OPT_LOWPOWER = 0
) (
    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,

    input  wire                          S_AXI_AWVALID,
    output wire                          S_AXI_AWREADY,
    input  wire [C_AXI_ADDR_WIDTH-1:0]   S_AXI_AWADDR,
    input  wire [2:0]                    S_AXI_AWPROT,

    input  wire                          S_AXI_WVALID,
    output wire                          S_AXI_WREADY,
    input  wire [C_AXI_DATA_WIDTH-1:0]   S_AXI_WDATA,
    input  wire [C_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,

    output wire                          S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,
    output wire [1:0]                    S_AXI_BRESP,

    // Read channels: tied off (write-only slave)
    input  wire                          S_AXI_ARVALID,
    output wire                          S_AXI_ARREADY,
    input  wire [C_AXI_ADDR_WIDTH-1:0]   S_AXI_ARADDR,
    input  wire [2:0]                    S_AXI_ARPROT,
    output wire                          S_AXI_RVALID,
    input  wire                          S_AXI_RREADY,
    output wire [C_AXI_DATA_WIDTH-1:0]   S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,

    // CPU instruction fetch (clk_i domain, read-only)
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        instr_req_i,
    output wire        instr_gnt_o,
    output reg         instr_rvalid_o,
    input  wire [31:0] instr_addr_i,
    output reg  [31:0] instr_rdata_o
);

    localparam ADDRLSB = 2;

    wire i_reset = !S_AXI_ARESETN;

    // ────────────────────────────────────────────────────────────────
    // Read channels: tied off
    // ────────────────────────────────────────────────────────────────
    assign S_AXI_ARREADY = 1'b0;
    assign S_AXI_RVALID  = 1'b0;
    assign S_AXI_RDATA   = '0;
    assign S_AXI_RRESP   = 2'b10;

    // ────────────────────────────────────────────────────────────────
    // 1.  AXI-Lite write signaling  (S_AXI_ACLK domain)
    // ────────────────────────────────────────────────────────────────
    wire [C_AXI_ADDR_WIDTH-ADDRLSB-1:0] awskd_addr;
    wire [C_AXI_DATA_WIDTH-1:0]         wskd_data;
    wire [C_AXI_DATA_WIDTH/8-1:0]       wskd_strb;
    wire                                 axil_write_ready;

    assign awskd_addr       = S_AXI_AWADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB];
    assign wskd_data        = S_AXI_WDATA;
    assign wskd_strb        = S_AXI_WSTRB;
    assign axil_write_ready = axil_awready;

    reg axil_awready;

    initial axil_awready = 1'b0;
    always @(posedge S_AXI_ACLK)
        if (!S_AXI_ARESETN)
            axil_awready <= 1'b0;
        else
            axil_awready <= !axil_awready
                && (S_AXI_AWVALID && S_AXI_WVALID)
                && (!S_AXI_BVALID || S_AXI_BREADY);

    assign S_AXI_AWREADY = axil_awready;
    assign S_AXI_WREADY  = axil_awready;

    reg axil_bvalid;

    initial axil_bvalid = 1'b0;
    always @(posedge S_AXI_ACLK)
        if (i_reset)
            axil_bvalid <= 1'b0;
        else if (axil_write_ready)
            axil_bvalid <= 1'b1;
        else if (S_AXI_BREADY)
            axil_bvalid <= 1'b0;

    assign S_AXI_BVALID = axil_bvalid;
    assign S_AXI_BRESP  = 2'b00;

    // ────────────────────────────────────────────────────────────────
    // 2.  Memory
    //     Written on S_AXI_ACLK (bootloader, CPU in reset).
    //     Read    on clk_i      (runtime, AXI idle).
    // ────────────────────────────────────────────────────────────────
    (* ram_style = "block" *)
    reg [31:0] mem [0:2047];

    // uncomment this to boot without copying from qpsi flash
    // initial $readmemh("cnn_soc_c_project/build/firmware_clean.hex", mem);

    // Port A: AXI write
    always @(posedge S_AXI_ACLK) begin
        if (axil_write_ready) begin
            mem[awskd_addr] <= apply_wstrb(mem[awskd_addr], wskd_data, wskd_strb);
            $display("axi write to instr rom at 0x%x with value 0x%x", awskd_addr, wskd_data);
        end
    end

    // ────────────────────────────────────────────────────────────────
    // 3.  CPU read — single register stage, 1-cycle latency
    // ────────────────────────────────────────────────────────────────
    assign instr_gnt_o = instr_req_i;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            instr_rvalid_o <= 1'b0;
            instr_rdata_o  <= 32'b0;
        end else begin
            instr_rvalid_o <= instr_req_i;
            if (instr_req_i)
                instr_rdata_o <= mem[instr_addr_i[12:2]];
        end
    end

    // ────────────────────────────────────────────────────────────────
    // apply_wstrb
    // ────────────────────────────────────────────────────────────────
    function [C_AXI_DATA_WIDTH-1:0] apply_wstrb;
        input [C_AXI_DATA_WIDTH-1:0]   prior_data;
        input [C_AXI_DATA_WIDTH-1:0]   new_data;
        input [C_AXI_DATA_WIDTH/8-1:0] wstrb;
        integer k;
        for (k = 0; k < C_AXI_DATA_WIDTH/8; k = k+1)
            apply_wstrb[k*8 +: 8] = wstrb[k] ? new_data[k*8 +: 8]
                                               : prior_data[k*8 +: 8];
    endfunction

    // Unused signals
    wire unused;
    assign unused = &{ 1'b0, S_AXI_AWPROT, S_AXI_ARPROT,
                       S_AXI_AWADDR[ADDRLSB-1:0],
                       S_AXI_ARADDR, S_AXI_ARVALID,
                       S_AXI_RREADY };

endmodule