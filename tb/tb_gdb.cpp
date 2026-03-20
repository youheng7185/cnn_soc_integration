#include "svdpi.h"
#include "Vcv32e40p_verilator_top__Dpi.h"
#include "Vcv32e40p_verilator_top.h"
#include "verilated_fst_c.h"
#include "verilated.h"
#include <iostream>
#include <cstdint>

double sc_time_stamp();

static vluint64_t t = 0;
Vcv32e40p_verilator_top *top;

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    top = new Vcv32e40p_verilator_top();

    VerilatedFstC *tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("waveform.fst");

    // init
    top->clk_i  = 0;
    top->rst_ni = 0;
    top->eval();

    while (!Verilated::gotFinish()) {
        // release reset after 40 time units
        if (t > 40)
            top->rst_ni = 1;

        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(t);
        t += 5;

        // safety timeout — 100M cycles
        if (t > 100000000ULL) break;
    }

    tfp->close();
    delete top;
    exit(0);
}

double sc_time_stamp()
{
    return t;
}