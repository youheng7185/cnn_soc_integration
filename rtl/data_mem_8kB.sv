module data_mem_8kB (
    input logic clk_core,
    input logic rst_core_n,

    input logic dmem_req_i,
    output logic dmem_gnt_o,
    output logic dmem_rvalid_o,
    input logic dmem_we_i,
    input logic [3:0] dmem_be_i,
    input logic [31:0] dmem_addr_i,
    input logic [31:0] dmem_wdata_i,
    output logic [31:0] dmem_rdata_o

);

    // 8kB of data mem
    logic [31:0] data_mem [0:2047];
    logic [31:0] rdata_q;

    assign dmem_gnt_o = 1'b1; // Always ready
    assign dmem_rdata_o = rdata_q;

    always_ff @(posedge clk_core or negedge rst_core_n) begin
        if (!rst_core_n) begin
            dmem_rvalid_o <= 1'b0;
            rdata_q <= 32'b0;
        end else begin
            dmem_rvalid_o <= 1'b0;

            if (dmem_req_i) begin
                
                rdata_q <= data_mem[dmem_addr_i[12:2]];
                // Write logic
                if (dmem_we_i) begin
                    if (dmem_be_i[0]) data_mem[dmem_addr_i[12:2]][7:0]   <= dmem_wdata_i[7:0];
                    if (dmem_be_i[1]) data_mem[dmem_addr_i[12:2]][15:8]  <= dmem_wdata_i[15:8];
                    if (dmem_be_i[2]) data_mem[dmem_addr_i[12:2]][23:16] <= dmem_wdata_i[23:16];
                    if (dmem_be_i[3]) data_mem[dmem_addr_i[12:2]][31:24] <= dmem_wdata_i[31:24];
                end

                dmem_rvalid_o <= 1'b1;
            end
        end
    end

endmodule