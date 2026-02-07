module data_bus_decoder (
    // cpu inferface
    input logic data_req_i,
    output logic data_gnt_o,
    output logic data_rvalid_o,
    input logic data_we_i,
    input logic [3:0] data_be_i,
    input logic [31:0] data_addr_i,
    input logic [31:0] data_wdata_i,
    output logic [31:0] data_rdata_o

    // data memory interface
    output logic mem_req_o,
    input logic mem_gnt_i,
    input logic mem_rvalid_i,
    output logic mem_we_o,
    output logic [3:0] mem_be_o,
    output logic [31:0] mem_addr_o,
    output logic [31:0] mem_wdata_o,
    input logic [31:0] mem_rdata_i,

    // core2axi interface
    output logic axi_req_o,
    input logic axi_gnt_i,
    input logic axi_rvalid_i,
    output logic axi_we_o,
    output logic [3:0] axi_be_o,
    output logic [31:0] axi_addr_o,
    output logic [31:0] axi_wdata_o,
    input logic [31:0] axi_rdata_i,
);

    // 0x0000 0000 to 0x7fff ffff is allocated to data memory
    wire target_native = ~data_addr_i[31];
    // 0x8000 0000 to 0xffff ffff is allocated for axi lite
    wire target_axi = data_addr_i[31];

    assign mem_req_o = data_req_i & target_native;
    assign mem_we_o = data_we_i & target_native;
    assign mem_addr_o = data_addr_i;
    assign mem_wdata_o = data_wdata_i;
    assign mem_be = data_be_i;

    assign axi_req_o = data_req_i & target_axi;
    assign axi_we_o = data_we_i & target_axi;
    assign axi_addr_o = data_addr_i;
    assign axi_wdata_o = data_wdata_i;
    assign axi_be = data_be_i;    

    assign data_gnt_o = target_native ? mem_gnt_i : axi_gnt_i;
    assign data_rvalid_o = target_native ? mem_rvalid_i : axi_rvalid_i;
    assign data_rdata_o = target_native ? mem_rdata_i : axi_rdata_i;

endmodule