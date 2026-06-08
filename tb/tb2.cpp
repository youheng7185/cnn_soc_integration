#include "Vteknotest_wrapper.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <iostream>
#include <cstdint>
#include <string>

// ------------------------------------------------------------
// Globals
// ------------------------------------------------------------
vluint64_t sim_time = 0;

// Clock period: 50 MHz → 20 ns → 10 ns half-period
// Each tick() call = 1 full clock cycle
// Timescale is 1ns/1ps, so 1 tick = 20 sim_time units

// UART config — match SV TB defaults
// 50 MHz clock = 20 ns/cycle
// 115200 baud → bit time = 1,000,000,000 ns / 115200 = 8680 ns
// 8680 ns / 20 ns per cycle = 434 cycles per bit
#ifndef UART_BAUD
#define UART_BAUD 115200
#endif
#ifndef UART_STOP_BITS
#define UART_STOP_BITS 1
#endif

const int CLK_PERIOD_NS  = 20;
const int BIT_TIME_NS    = 1000000000 / UART_BAUD;
const int BIT_CYCLES     = BIT_TIME_NS / CLK_PERIOD_NS;  // cycles per bit
const int STOP_CYCLES    = UART_STOP_BITS * BIT_CYCLES;

// ------------------------------------------------------------
// Forward declarations
// ------------------------------------------------------------
void tick(int32_t n, Vteknotest_wrapper *dut, VerilatedFstC *tfp);
void uart_write(Vteknotest_wrapper *dut, VerilatedFstC *tfp, uint8_t data);
bool uart_read(Vteknotest_wrapper *dut, VerilatedFstC *tfp,
               uint8_t &data, uint64_t timeout_cycles = 10000000ULL);

// ------------------------------------------------------------
// tick — one full clock cycle
// ------------------------------------------------------------
void tick(int32_t n, Vteknotest_wrapper *dut, VerilatedFstC *tfp) {
    for (int i = 0; i < n; i++) {
        dut->clk_i = 0;
        dut->eval();
        tfp->dump(sim_time++);

        dut->clk_i = 1;
        dut->eval();
        tfp->dump(sim_time++);
    }
}

// ------------------------------------------------------------
// uart_write — TB → DUT (drives uart_rx_i)
// Mirrors SV uart_write task exactly:
//   1 start bit, 8 data bits LSB first, N stop bits
// ------------------------------------------------------------
void uart_write(Vteknotest_wrapper *dut, VerilatedFstC *tfp, uint8_t data) {
    // Start bit
    dut->uart_rx_i = 0;
    tick(BIT_CYCLES, dut, tfp);

    // Data bits, LSB first
    for (int i = 0; i < 8; i++) {
        dut->uart_rx_i = (data >> i) & 1;
        tick(BIT_CYCLES, dut, tfp);
    }

    // Stop bits
    dut->uart_rx_i = 1;
    tick(STOP_CYCLES, dut, tfp);
}

// ------------------------------------------------------------
// uart_read — DUT → TB (samples uart_tx_o)
// Mirrors SV uart_read task:
//   Wait for negedge on uart_tx_o (start bit),
//   skip 1.5 bit times to center of bit[0],
//   sample 8 bits LSB first,
//   consume remainder of stop bit
// Returns false on timeout (never saw start bit)
// ------------------------------------------------------------
bool uart_read(Vteknotest_wrapper *dut, VerilatedFstC *tfp,
               uint8_t &data, uint64_t timeout_cycles) {
    data = 0;

    // Wait for negedge on uart_tx_o (start bit)
    // Poll every cycle
    uint64_t waited = 0;
    uint8_t prev = dut->uart_tx_o;
    while (true) {
        tick(1, dut, tfp);
        waited++;
        if (waited > timeout_cycles) {
            std::cout << "[" << sim_time << "] TIMEOUT waiting for start bit" << std::endl;
            return false;
        }
        uint8_t cur = dut->uart_tx_o;
        if (prev == 1 && cur == 0) break;  // negedge detected
        prev = cur;
    }

    // Move to center of bit[0]:
    // SV does: #(BIT_TIME_NS + BIT_TIME_NS/2)
    // = 1.5 bit periods from the negedge
    // We already consumed 1 cycle in the negedge detection tick above,
    // so wait (1.5 * BIT_CYCLES - 1) more cycles
    int center_offset = (BIT_CYCLES + BIT_CYCLES / 2) - 1;
    tick(center_offset, dut, tfp);

    // Sample 8 data bits, LSB first
    for (int i = 0; i < 8; i++) {
        data |= (dut->uart_tx_o & 1) << i;
        tick(BIT_CYCLES, dut, tfp);
    }

    // Consume remainder of stop bit
    // SV does: #(STOP_BITS * BIT_TIME - BIT_TIME/2)
    // because the for loop above already consumed an extra half bit
    int stop_remainder = STOP_CYCLES - BIT_CYCLES / 2;
    tick(stop_remainder, dut, tfp);

    std::cout << "[" << sim_time << "] INFO: Read byte 0x"
              << std::hex << (int)data << " ('" << (char)data << "')" << std::dec
              << std::endl;
    return true;
}

// ------------------------------------------------------------
// uart_wait_byte — read and compare, mirrors SV uart_wait_byte
// ------------------------------------------------------------
bool uart_wait_byte(Vteknotest_wrapper *dut, VerilatedFstC *tfp, uint8_t expected) {
    uint8_t data;
    if (!uart_read(dut, tfp, data)) return false;

    if (data != expected) {
        std::cout << "[" << sim_time << "] ERROR: Expected 0x"
                  << std::hex << (int)expected << " ('" << (char)expected
                  << "'), got 0x" << (int)data << " ('" << (char)data << "')"
                  << std::dec << std::endl;
        return false;
    }
    std::cout << "[" << sim_time << "] INFO: Received expected byte 0x"
              << std::hex << (int)data << " ('" << (char)data << "')"
              << std::dec << std::endl;
    return true;
}

// ------------------------------------------------------------
// main
// ------------------------------------------------------------
int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);
    Vteknotest_wrapper *dut = new Vteknotest_wrapper;

    VerilatedFstC *tfp = new VerilatedFstC;
    Verilated::traceEverOn(true);
    dut->trace(tfp, 99);
    tfp->open("waveform.fst");

    // Init signals
    dut->clk_i     = 0;
    dut->resetn_i  = 0;
    dut->uart_rx_i = 1;  // idle high

    // ------------------------------------------------------------
    // Reset — SV TB asserts reset for 10 us = 10000 ns = 500 cycles
    // ------------------------------------------------------------
    tick(500, dut, tfp);
    dut->resetn_i = 1;
    std::cout << "[" << sim_time << "] INFO: Reset deasserted" << std::endl;

    // ------------------------------------------------------------
    // Step 1: Wait for DUT to send 'R'
    // ------------------------------------------------------------
    std::cout << "[" << sim_time << "] INFO: Waiting for 'R' from DUT..." << std::endl;
    if (!uart_wait_byte(dut, tfp, 'R')) {
        std::cout << "TEST FAIL: Did not receive 'R'" << std::endl;
        goto done;
    }

    // ------------------------------------------------------------
    // Step 2: Send 'A' to DUT
    // SV TB does send_A and receive_msg in fork-join (parallel).
    // But C code is sequential: finish receiving 'A' first, then
    // send "Hello World!". So we send 'A' first, then listen.
    // ------------------------------------------------------------
    std::cout << "[" << sim_time << "] INFO: Sending 'A' to DUT..." << std::endl;
    uart_write(dut, tfp, 'A');
    std::cout << "[" << sim_time << "] INFO: 'A' sent" << std::endl;

    // ------------------------------------------------------------
    // Step 3: Receive "Hello World!"
    // ------------------------------------------------------------
    {
        const std::string expected = "Hello World!";
        std::string received = "";

        std::cout << "[" << sim_time << "] INFO: Waiting for \"Hello World!\"..." << std::endl;

        for (size_t i = 0; i < expected.size(); i++) {
            uint8_t ch;
            if (!uart_read(dut, tfp, ch)) {
                std::cout << "[" << sim_time << "] TEST FAIL: Timeout on char index "
                          << i << std::endl;
                goto done;
            }
            received += (char)ch;
        }

        if (received == expected) {
            std::cout << "[" << sim_time << "] TEST SUCCESS: Received \""
                      << received << "\"" << std::endl;
        } else {
            std::cout << "[" << sim_time << "] TEST FAIL: Expected \""
                      << expected << "\", got \"" << received << "\"" << std::endl;
        }
    }

done:
    dut->final();
    tfp->close();
    delete dut;
    delete tfp;
    return 0;
}