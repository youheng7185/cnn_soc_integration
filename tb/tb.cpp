#include "Vcv32e40p_verilator_top.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    auto *top = new Vcv32e40p_verilator_top;

    for (int i = 0; i < 100; i++) {
        top->clk_i = 0; top->eval();
        top->clk_i = 1; top->eval();
    }

    delete top;
    return 0;
}
