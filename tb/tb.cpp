#include "Vcv32e40p_verilator_top.h"
#include "verilated.h"
#include "conv_input_data.h"
#include <iostream>
#include <cstdint>

static vluint64_t sim_time = 0;
static Vcv32e40p_verilator_top *dut;

void tick(int32_t tick_val) {
    for (int i = 0; i < tick_val; i++) {
        dut->clk_i = 0;
        dut->eval();
        sim_time += 5;   // half period = 5 time units
        dut->clk_i = 1;
        dut->eval();
        sim_time += 5;   // so #1 delay fits within the half period
    }
}

void uart_send_byte(uint8_t data) {
    const int BIT_CYCLES = 217;
    auto drive = [&](int val) {
        dut->uart0_rx_i = val;
        tick(BIT_CYCLES);
    };
    drive(1);        // idle
    drive(0);        // start bit
    for (int i = 0; i < 8; i++)
        drive((data >> i) & 1);
    drive(1);        // stop bit
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    dut = new Vcv32e40p_verilator_top;

    // Reset
    dut->rst_ni      = 0;
    dut->uart0_rx_i  = 1;   // idle
    dut->gpio_in     = 0xABAB;
    tick(5);

    dut->rst_ni = 1;
    tick(100000);

    // Uncomment to run inference:
    // for (uint32_t i = 0; i < 1960; i++)
    //     uart_send_byte(conv2d_input_no[i]);

    tick(100000);  // let it process

    std::cout << "gpio_out = 0x" << std::hex << dut->gpio_out << std::endl;

    // Clean shutdown
    dut->rst_ni = 0;
    tick(5);
    dut->final();
    delete dut;
    return 0;
}