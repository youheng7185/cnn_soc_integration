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
    // top->fetch_enable_i = 1;
    top->clk_i  = 0;
    top->rst_ni = 0;
    top->eval();

    vluint64_t last_print = 0;

    while (!Verilated::gotFinish()) {
        // release reset after 40 time units
        if (t > 1000)
            top->rst_ni = 1;
        else
            top->rst_ni = 0;

        top->clk_i = !top->clk_i;
        top->eval();
        tfp->dump(t);

        // print debug signals every 1000 ticks on rising edge
        if (top->clk_i == 1 && t > 1000 && (t - last_print) >= 1000) {
            last_print = t;
            printf("t=%lu rst_ni=%d ndmreset=%d "
                   "havereset=%d running=%d halted=%d "
                   "debug_req=%d\n",
                t,
                (int)top->rst_ni,
                (int)top->ndmreset_dbg,        // expose if possible
                (int)top->debug_havereset_o,
                (int)top->debug_running_o,
                (int)top->debug_halted_o,
                (int)top->debug_req_dbg
            );
        }

        t += 5;

        // safety timeout — 100M cycles
        if (t > 100000000ULL) {
            std::cout << "timeout \n";
            break;
        }
    }

    tfp->close();
    delete top;
    exit(0);
}

double sc_time_stamp()
{
    return t;
}