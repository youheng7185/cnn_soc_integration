`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2026 07:53:05 AM
// Design Name: 
// Module Name: cv32e40p_fpga_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cv32e40p_fpga_wrapper(
    input wire clk,
    input wire rst_n,
    output wire [7:0] led,
    output wire [7:0] switch
    );
    
    logic clk_core;
    logic rst_core_n;
    
    logic [2:0] rst_sync;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rst_sync <= 3'b000;
        else
            rst_sync <= {rst_sync[1:0], 1'b1};
    end
    
    assign rst_core_n = rst_sync[2];
    assign clk_core = clk;
    
    logic instr_req;
    logic instr_gnt;
    logic instr_rvalid;
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;
    
    logic data_req;
    logic data_gnt;
    logic data_rvalid;
    logic data_we;
    logic [3:0] data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    
    logic [31:0] irq;
    logic irq_ack;
    logic [4:0] irq_id;
    logic debug_req;
    logic core_sleep;
    
    cv32e40p_top #(
        .COREV_PULP(0),
        .COREV_CLUSTER(0),
        .FPU(0),
        .ZFINX(0),
        .NUM_MHPMCOUNTERS(1)        
    ) u_core (
        .clk_i(clk_core),
        .rst_ni(rst_core_n),
        .pulp_clock_en_i(1'b1),
        .scan_cg_en_i(1'b0),
        
        .boot_addr_i(32'h0000_0000),
        .mtvec_addr_i(32'h0000_0100),
        .dm_halt_addr_i(32'h0000_0800),
        .hart_id_i(32'h0000_0000),
        .dm_exception_addr_i(32'h0000_0808),
        
        .instr_req_o(instr_req),
        .instr_gnt_i(instr_gnt),
        .instr_rvalid_i(instr_rvalid),
        .instr_addr_o(instr_addr),
        .instr_rdata_i(instr_rdata),
        
        .data_req_o(data_req),
        .data_gnt_i(data_gnt),
        .data_rvalid_i(data_rvalid),
        .data_we_o(data_we),
        .data_be_o(data_be),
        .data_addr_o(data_addr),
        .data_wdata_o(data_wdata),
        .data_rdata_i(data_rdata),
        
        .irq_i(irq),
        .irq_ack_o(irq_ack),
        .irq_id_o(irq_id),
        
        .debug_req_i(debug_req),
        .debug_havereset_o(),
        .debug_running_o(),
        .debug_halted_o(),
        
        .fetch_enable_i(1'b1),
        .core_sleep_o(core_sleep)
    );
    
    // Simple instruction memory (ROM)
    // This is a minimal test program that writes to data memory
    logic [31:0] instr_mem [0:255];
    initial begin
        // Simple test program
        // addi x1, x0, 0x55   // Load immediate
        instr_mem[0] = 32'h05500093;
        // sw x1, 0(x0)        // Store to address 0
        instr_mem[1] = 32'h00102023;
        // addi x2, x0, 0xAA   // Load another immediate
        instr_mem[2] = 32'h0AA00113;
        // sw x2, 4(x0)        // Store to address 4
        instr_mem[3] = 32'h00202223;
        // Loop: j Loop        // Infinite loop
        instr_mem[4] = 32'h0000006F;
        
        // Initialize rest to NOP (addi x0, x0, 0)
        for (int i = 5; i < 256; i++) begin
            instr_mem[i] = 32'h00000013;
        end
    end
    
    // Instruction memory logic
    logic [7:0] instr_addr_reg; // aka program counter
    always_ff @(posedge clk_core or negedge rst_core_n) begin
        if (!rst_core_n) begin
            instr_addr_reg <= 8'h0;
            instr_rvalid <= 1'b0;
        end else begin
            if (instr_req && instr_gnt) begin
                instr_addr_reg <= instr_addr[9:2];
                instr_rvalid <= 1'b1;
            end else begin
                instr_rvalid <= 1'b0;
            end
        end
    end
    
    assign instr_rdata = instr_mem[instr_addr_reg];
    assign instr_gnt = 1'b1; // Always ready
    
    // Simple data memory (RAM)
    logic [31:0] data_mem [0:255];
    logic [7:0] data_addr_reg;
    logic data_we_reg;
    logic [3:0] data_be_reg;
    logic [31:0] data_wdata_reg;
    
    always_ff @(posedge clk_core or negedge rst_core_n) begin
        if (!rst_core_n) begin
            data_addr_reg <= 8'h0;
            data_we_reg <= 1'b0;
            data_be_reg <= 4'h0;
            data_wdata_reg <= 32'h0;
            data_rvalid <= 1'b0;
        end else begin
            if (data_req && data_gnt) begin
                data_addr_reg <= data_addr[9:2];
                data_we_reg <= data_we;
                data_be_reg <= data_be;
                data_wdata_reg <= data_wdata;
                data_rvalid <= 1'b1;
                
                // Write logic
                if (data_we) begin
                    if (data_be[0]) data_mem[data_addr[9:2]][7:0]   <= data_wdata[7:0];
                    if (data_be[1]) data_mem[data_addr[9:2]][15:8]  <= data_wdata[15:8];
                    if (data_be[2]) data_mem[data_addr[9:2]][23:16] <= data_wdata[23:16];
                    if (data_be[3]) data_mem[data_addr[9:2]][31:24] <= data_wdata[31:24];
                end
            end else begin
                data_rvalid <= 1'b0;
            end
        end
    end
    
    assign data_rdata = data_mem[data_addr_reg];
    assign data_gnt = 1'b1; // Always ready
    
    // No interrupts or debug for basic test
    assign irq = 32'h0;
    assign debug_req = 1'b0;
    
    // LED outputs - show data from first two memory locations
    assign led = data_mem[0][7:0] ^ data_mem[1][7:0];
        
endmodule
