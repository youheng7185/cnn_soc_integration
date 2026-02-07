#include "Vcv32e40p_verilator_top.h"
#include "verilated.h"
#include "Vcv32e40p_verilator_top___024root.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <cstdint>

void tick(int32_t tick_val, Vcv32e40p_verilator_top *dut, VerilatedFstC* tfp);

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
    dut->gpio_in = 0xABAB;
    tick(200, dut, tfp);
    
    // Access internal signal through rootp
    std::cout << "mem_req = " << (int)dut->rootp->cv32e40p_verilator_top__DOT__mem_req << std::endl;
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