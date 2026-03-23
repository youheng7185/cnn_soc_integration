////////////////////////////////////////////////////////////////////////////////
//
// Filename:	rtl/easyaxil.v
// {{{
// Project:	WB2AXIPSP: bus bridges and other odds and ends
//
// Purpose:	Demonstrates a simple AXI-Lite interface.
//
//	This was written in light of my last demonstrator, for which others
//	declared that it was much too complicated to understand.  The goal of
//	this demonstrator is to have logic that's easier to understand, use,
//	and copy as needed.
//
//	Since there are two basic approaches to AXI-lite signaling, both with
//	and without skidbuffers, this example demonstrates both so that the
//	differences can be compared and contrasted.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2019-2025, Gisselquist Technology, LLC
// {{{
// This file is part of the WB2AXIP project.
//
// The WB2AXIP project contains free software and gateware, licensed under the
// Apache License, Version 2.0 (the "License").  You may not use this project,
// or this file, except in compliance with the License.  You may obtain a copy
// of the License at
// }}}
//	http://www.apache.org/licenses/LICENSE-2.0
// {{{
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//
////////////////////////////////////////////////////////////////////////////////
//
`default_nettype none
// }}}
module	axi_to_obi_dm #(
		// {{{
		//
		// Size of the AXI-lite bus.  These are fixed, since 1) AXI-lite
		// is fixed at a width of 32-bits by Xilinx def'n, and 2) since
		// we only ever have 4 configuration words.
		parameter	C_AXI_ADDR_WIDTH = 32,
		localparam	C_AXI_DATA_WIDTH = 32,
        parameter [0:0]	OPT_LOWPOWER = 0
		// }}}
	) (
		// {{{
		input	wire					S_AXI_ACLK,
		input	wire					S_AXI_ARESETN,
		//
		input	wire					S_AXI_AWVALID,
		output	wire					S_AXI_AWREADY,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]		S_AXI_AWADDR,
		input	wire	[2:0]				S_AXI_AWPROT,
		//
		input	wire					S_AXI_WVALID,
		output	wire					S_AXI_WREADY,
		input	wire	[C_AXI_DATA_WIDTH-1:0]		S_AXI_WDATA,
		input	wire	[C_AXI_DATA_WIDTH/8-1:0]	S_AXI_WSTRB,
		//
		output	wire					S_AXI_BVALID,
		input	wire					S_AXI_BREADY,
		output	wire	[1:0]				S_AXI_BRESP,
		//
		input	wire					S_AXI_ARVALID,
		output	wire					S_AXI_ARREADY,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]		S_AXI_ARADDR,
		input	wire	[2:0]				S_AXI_ARPROT,
		//
		output	wire					S_AXI_RVALID,
		input	wire					S_AXI_RREADY,
		output	wire	[C_AXI_DATA_WIDTH-1:0]		S_AXI_RDATA,
		output	wire	[1:0]				S_AXI_RRESP,
		// }}}

		// OBI master — connect to dm_top slave port
		output logic        dm_req_o,
		output logic        dm_we_o,
		output logic [31:0] dm_addr_o,
		output logic [3:0]  dm_be_o,
		output logic [31:0] dm_wdata_o,
		input  logic [31:0] dm_rdata_i,
		input  logic        dm_gnt_i,
		input  logic        dm_rvalid_i
	);

	////////////////////////////////////////////////////////////////////////
	//
	// Register/wire signal declarations
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	localparam	ADDRLSB = 2; // last two least significant bit not used
    reg                          aw_latched;
    reg  [C_AXI_ADDR_WIDTH-1:0] aw_addr_lat;
    reg                          axil_awready;
	logic i_reset = !S_AXI_ARESETN;
	wire				axil_write_ready;
	
    always @(posedge S_AXI_ACLK) begin
        if (i_reset) begin
            aw_latched  <= 0;
            aw_addr_lat <= 0;
        end else if (S_AXI_AWVALID && S_AXI_AWREADY) begin
            aw_addr_lat <= S_AXI_AWADDR;
            aw_latched  <= 1;
        end else if (axil_write_ready) begin
            aw_latched  <= 0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (i_reset) axil_awready <= 0;
        else         axil_awready <= !aw_latched && !S_AXI_AWREADY;
    end

	// write data latch
    reg                              w_latched;
    reg  [C_AXI_DATA_WIDTH-1:0]     w_data_lat;
    reg  [C_AXI_DATA_WIDTH/8-1:0]   w_strb_lat;
    reg                              axil_wready_r;

    always @(posedge S_AXI_ACLK) begin
        if (i_reset) begin
            w_latched  <= 0;
            w_data_lat <= 0;
            w_strb_lat <= 0;
        end else if (S_AXI_WVALID && S_AXI_WREADY) begin
            w_data_lat <= S_AXI_WDATA;
            w_strb_lat <= S_AXI_WSTRB;
            w_latched  <= 1;
        end else if (axil_write_ready) begin
            w_latched  <= 0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (i_reset) axil_wready_r <= 0;
        else         axil_wready_r <= !w_latched && !S_AXI_WREADY;
    end

    assign S_AXI_AWREADY  = axil_awready;
    assign S_AXI_WREADY   = axil_wready_r;
    assign axil_write_ready = aw_latched && w_latched;

    // read address latch
    reg                          ar_latched;
    reg  [C_AXI_ADDR_WIDTH-1:0] ar_addr_lat;
    reg                          axil_arready;

    always @(posedge S_AXI_ACLK) begin
        if (i_reset) begin
            ar_latched  <= 0;
            ar_addr_lat <= 0;
        end else if (S_AXI_ARVALID && S_AXI_ARREADY) begin
            ar_addr_lat <= S_AXI_ARADDR;
            ar_latched  <= 1;
        end else if (axil_read_fire) begin
            ar_latched  <= 0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (i_reset) axil_arready <= 1;
        else         axil_arready <= !ar_latched && !S_AXI_ARREADY;
    end

    assign S_AXI_ARREADY = axil_arready;

	// debug
	typedef enum logic [1:0] {
        IDLE       = 2'd0,
        WAIT_GNT   = 2'd1,
        WAIT_RVAL  = 2'd2,
        RESP       = 2'd3
    } state_t;

    state_t state_q;

    logic        obi_we_q;
    logic [31:0] obi_addr_q;
    logic [3:0]  obi_be_q;
    logic [31:0] obi_wdata_q;
    logic [31:0] obi_rdata_q;

    wire axil_read_fire = ar_latched && (state_q == IDLE);

    always_comb begin
        dm_req_o   = 1'b0;
        dm_we_o    = 1'b0;
        dm_addr_o  = obi_addr_q;
        dm_be_o    = obi_be_q;
        dm_wdata_o = obi_wdata_q;

        case (state_q)
            IDLE: begin
                // write has priority over read (matches mm_ram sb > data)
                if (axil_write_ready) begin
                    dm_req_o   = 1'b1;
                    dm_we_o    = 1'b1;
                    dm_addr_o  = aw_addr_lat;
                    dm_be_o    = w_strb_lat;
                    dm_wdata_o = w_data_lat;
                end else if (ar_latched) begin
                    dm_req_o   = 1'b1;
                    dm_we_o    = 1'b0;
                    dm_addr_o  = ar_addr_lat;
                    dm_be_o    = 4'hF;
                    dm_wdata_o = 32'h0;
                end
            end
            WAIT_GNT: begin
                // keep driving request until granted
                dm_req_o   = 1'b1;
                dm_we_o    = obi_we_q;
                dm_addr_o  = obi_addr_q;
                dm_be_o    = obi_be_q;
                dm_wdata_o = obi_wdata_q;
            end
            default: begin
                dm_req_o = 1'b0;
            end
        endcase
    end

	always_ff @(posedge S_AXI_ACLK or posedge i_reset) begin
        if (i_reset) begin
            state_q     <= IDLE;
            obi_we_q    <= 1'b0;
            obi_addr_q  <= '0;
            obi_be_q    <= '0;
            obi_wdata_q <= '0;
            obi_rdata_q <= '0;
        end else begin
            case (state_q)
                IDLE: begin
                    if (axil_write_ready || ar_latched) begin
                        // latch transaction
                        obi_we_q    <= axil_write_ready;
                        obi_addr_q  <= axil_write_ready ? aw_addr_lat : ar_addr_lat;
                        obi_be_q    <= axil_write_ready ? w_strb_lat  : 4'hF;
                        obi_wdata_q <= w_data_lat;

                        if (dm_gnt_i)
                            state_q <= WAIT_RVAL;  // granted immediately
                        else
                            state_q <= WAIT_GNT;   // wait for grant
                    end
                end

                WAIT_GNT: begin
                    if (dm_gnt_i)
                        state_q <= WAIT_RVAL;
                end

                WAIT_RVAL: begin
                    if (dm_rvalid_i) begin
                        obi_rdata_q <= dm_rdata_i;
                        state_q     <= RESP;
                    end
                end

                RESP: begin
                    // stay until AXI response accepted
                    if (obi_we_q && S_AXI_BREADY)
                        state_q <= IDLE;
                    else if (!obi_we_q && S_AXI_RREADY)
                        state_q <= IDLE;
                end
            endcase
        end
    end

    assign S_AXI_BVALID = (state_q == RESP) && obi_we_q;
    assign S_AXI_BRESP  = 2'b00;  // OKAY

    assign S_AXI_RVALID = (state_q == RESP) && !obi_we_q;
    assign S_AXI_RDATA  = obi_rdata_q;
    assign S_AXI_RRESP  = 2'b00;  // OKAY

    // unused
    wire unused = &{S_AXI_AWPROT, S_AXI_ARPROT};

endmodule