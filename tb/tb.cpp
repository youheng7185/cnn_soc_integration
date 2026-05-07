#include "Vcv32e40p_verilator_top.h"
#include "verilated.h"
#include "Vcv32e40p_verilator_top___024root.h"
#include "verilated_fst_c.h"
#include "conv_input_data.h"
#include <iostream>
#include <cstdint>

void tick(int32_t tick_val, Vcv32e40p_verilator_top *dut, VerilatedFstC* tfp);
void uart_send_byte(Vcv32e40p_verilator_top *dut, VerilatedFstC* tfp, uint8_t data);

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vcv32e40p_verilator_top *dut = new Vcv32e40p_verilator_top;
    
    // FST waveform dump
    VerilatedFstC* tfp = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(tfp, 99);
    tfp->open("waveform.fst");
    
    dut->rst_ni = 0;
    tick(5, dut, tfp);
    
    dut->rst_ni = 1;
    dut->uart0_rx_i = 1; // not active
    dut->gpio_in = 0xABAB;

    tick(100000, dut, tfp);

    for (uint32_t i = 0; i < 1960; i++) {
        uart_send_byte(dut, tfp, conv2d_input_no[i]);

        // if (i == 10) {
        //     dut->final();
        //     tfp->close();
        //     delete tfp;
        //     delete dut;
            
        //     return 0;
        // }
    }  

    tick(500000, dut, tfp); // let it process
    
    // Access internal signal through rootp
    //std::cout << "mem_req = " << (int)dut->rootp->cv32e40p_verilator_top__DOT__mem_req << std::endl;
    //std::cout << "gpio_in from axi = " << dut->rootp->cv32e40p_verilator_top__DOT__u_core__DOT__core_i__DOT__load_store_unit_i__DOT__data_rdata_ext << std::endl;
    std::cout << "gpio_out = " << dut->gpio_out << std::endl; // test pattern 0x5A5A

    dut->final();
    tfp->close();
    delete tfp;
    delete dut;
    
    return 0;
}

vluint64_t sim_time = 0;

void tick(int32_t tick_val, Vcv32e40p_verilator_top *dut, VerilatedFstC* tfp) {
    for (int i = 0; i < tick_val; i++) {
        dut->clk_i = 0;
        dut->eval();
        tfp->dump(sim_time++);
        
        dut->clk_i = 1;
        dut->eval();
        tfp->dump(sim_time++);
    }
}

void uart_send_byte(Vcv32e40p_verilator_top *dut, VerilatedFstC* tfp, uint8_t data) {
    const int BIT_CYCLES = 217;

    auto drive = [&](int val) {
        dut->uart0_rx_i = val;
        tick(BIT_CYCLES, dut, tfp);
    };

    // Idle (ensure line is high before start)
    drive(1);

    // Start bit
    drive(0);

    // Data bits (LSB first)
    for (int i = 0; i < 8; i++) {
        drive((data >> i) & 1);
    }

    // Stop bit (assuming 1 stop bit)
    drive(1);
}