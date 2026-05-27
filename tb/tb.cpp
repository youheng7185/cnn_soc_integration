#include "Vcv32e40p_verilator_top.h"
#include "verilated.h"
#include <iostream>
#include <fstream>
#include <cstdint>
#include <cstring>
#include <cstdlib>

static vluint64_t sim_time = 0;
static Vcv32e40p_verilator_top *dut;

void tick(int32_t tick_val) {
    for (int i = 0; i < tick_val; i++) {
        dut->clk_i = 0;
        dut->eval();
        sim_time += 5;
        dut->clk_i = 1;
        dut->eval();
        sim_time += 5;
    }
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    uint32_t max_cycles = 500000;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "+maxcycles") == 0 && i + 1 < argc) {
            max_cycles = (uint32_t)atoi(argv[++i]);
        }
    }

    dut = new Vcv32e40p_verilator_top;

    dut->rst_ni      = 0;
    dut->uart0_rx_i  = 1;
    dut->gpio_in     = 0xABAB;
    tick(5);

    dut->rst_ni = 1;

    uint16_t last_gpio_out = 0;
    int result = 2;

    for (uint32_t cycle = 0; cycle < max_cycles; cycle++) {
        dut->clk_i = 0;
        dut->eval();
        sim_time += 5;
        dut->clk_i = 1;
        dut->eval();
        sim_time += 5;

        uint16_t gpio_val = dut->gpio_out & 0xFFFF;
        if (gpio_val != last_gpio_out && cycle > 100) {
            if (gpio_val == 0x0001) {
                std::cerr << "[TB] PASS (gpio_out=0x" << std::hex << gpio_val
                          << std::dec << ") at cycle " << cycle << std::endl;
                result = 0;
                break;
            } else if (gpio_val != 0) {
                std::cerr << "[TB] FAIL (gpio_out=0x" << std::hex << gpio_val
                          << std::dec << ") at cycle " << cycle << std::endl;
                result = 1;
                break;
            }
            last_gpio_out = gpio_val;
        }
    }

    if (result == 2) {
        std::cerr << "[TB] TIMEOUT after " << max_cycles << " cycles" << std::endl;
        std::cerr << "[TB] gpio_out=0x" << std::hex << (dut->gpio_out & 0xFFFF) << std::dec << std::endl;
    }

    tick(10);

    dut->rst_ni = 0;
    tick(5);
    dut->final();
    delete dut;
    return result;
}