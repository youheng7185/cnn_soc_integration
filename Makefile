# ============================================================
# Verilator Makefile – CV32E40P SoC
# ============================================================
TOP            := cv32e40p_verilator_top
BUILD_DIR      := obj_dir
SIM            := $(BUILD_DIR)/V$(TOP)
SIM_GDB        := $(BUILD_DIR)/V$(TOP)_gdb
VERILATOR      := verilator
CXXFLAGS       := -O2 -std=c++17

RBS_DIR        := riscv-dbg/tb/remote_bitbang
RBS_LIB        := $(RBS_DIR)/librbs_veri.so

VERILATOR_FLAGS := \
    --cc \
    --exe \
    --no-timing \
    --trace-fst \
    --trace-structs \
    --trace-depth 99 \
    --Wall \
    -Wno-fatal \
    --top-module $(TOP) \
    -Mdir $(BUILD_DIR) \
    -CFLAGS "$(CXXFLAGS)" \
    -LDFLAGS "-L$(abspath $(RBS_DIR)) \
              -Wl,--enable-new-dtags \
              -Wl,-rpath,$(abspath $(RBS_DIR)) \
              -lrbs_veri"

# ------------------------------------------------------------
# Testbench
# ------------------------------------------------------------
TB_CPP     := tb/tb.cpp
TB_GDB_CPP := tb/tb_gdb.cpp

# ------------------------------------------------------------
# RTL sources
# ------------------------------------------------------------
VERILATOR_DEFS :=

CV32_PKG := \
    cv32e40p/rtl/include/cv32e40p_pkg.sv \
    cv32e40p/rtl/include/cv32e40p_apu_core_pkg.sv \
    cv32e40p/rtl/include/cv32e40p_fpu_pkg.sv

CV32_CORE := $(shell find cv32e40p/rtl -name "*.sv" \
    ! -path "*vendor*" \
    ! -name "*fp*" \
    ! -name "*fpu*" )

RTL_SRC := \
    common_cells/src/cdc_reset_ctrlr_pkg.sv \
    riscv-dbg/src/dm_pkg.sv \
    tech_cells_generic/src/rtl/tc_clk.sv \
    common_cells/src/cdc_2phase_clearable.sv \
    common_cells/src/cdc_reset_ctrlr.sv \
    common_cells/src/fifo_v3.sv \
    common_cells/src/sync.sv \
    common_cells/src/cdc_4phase.sv \
    $(CV32_PKG) \
    $(CV32_CORE) \
    cv32e40p/bhv/cv32e40p_sim_clock_gate.sv \
    core2axi/rtl/core2axi.sv \
    axi_cnn/axi_cnn.sv \
    axi_cnn/cnn_controller.sv \
    axi_cnn/conv.sv \
    axi_cnn/fc.sv \
    axi_cnn/final_weights_seperate_class.sv \
    axi_cnn/first_weights_seperate_filter.sv \
    axi_cnn/mac.sv \
    axi_cnn/prepare_data.sv \
    axi_gpio/axi_gpio.sv \
    axi_timer/timer.sv \
    axi_timer/axi_timer.sv \
    axi_uart/axi_uart.sv \
    axi_uart/uart.sv \
    axi_uart/uart_rx.sv \
    axi_uart/uart_tx.sv \
    axi_data_mem/axi_data_mem.sv \
    rtl/axi_interconnect.sv \
    rtl/instr_bus_decoder.sv \
    rtl/instr_rom_8kB.sv \
    rtl/boot_rom_1kB.sv \
    riscv-dbg/src/dm_csrs.sv \
    riscv-dbg/src/dmi_cdc.sv \
    riscv-dbg/src/dmi_jtag_tap.sv \
    riscv-dbg/src/dmi_jtag.sv \
    riscv-dbg/src/dm_mem.sv \
    riscv-dbg/src/dm_sba.sv \
    riscv-dbg/src/dm_top.sv \
    riscv-dbg/debug_rom/debug_rom.sv \
    rtl/cv32e40p_verilator_top.sv \
    riscv-dbg/tb/SimJTAG.sv

INCLUDES := \
    -Icv32e40p/rtl/include \
    -Icommon_cells/include

# ------------------------------------------------------------
# remote_bitbang library
# ------------------------------------------------------------
$(RBS_LIB):
	$(MAKE) -C $(RBS_DIR) sv-lib INCLUDE_DIRS="./"
	mv $(RBS_DIR)/librbs.so $(RBS_LIB)

# ------------------------------------------------------------
# Normal tb build
# ------------------------------------------------------------
all: $(SIM)

$(SIM): $(RTL_SRC) $(TB_CPP) $(RBS_LIB)
	$(VERILATOR) $(VERILATOR_FLAGS) $(INCLUDES) \
	$(VERILATOR_DEFS) \
	$(RTL_SRC) \
	$(TB_CPP)
	$(MAKE) -C $(BUILD_DIR) -f V$(TOP).mk

# ------------------------------------------------------------
# GDB tb build
# ------------------------------------------------------------
$(SIM_GDB): $(RTL_SRC) $(TB_GDB_CPP) $(RBS_LIB)
	$(VERILATOR) $(VERILATOR_FLAGS) $(INCLUDES) \
	$(VERILATOR_DEFS) \
	$(RTL_SRC) \
	$(TB_GDB_CPP)
	$(MAKE) -C $(BUILD_DIR) -f V$(TOP).mk
	cp $(SIM) $(SIM_GDB)

# ------------------------------------------------------------
# Run rules
# ------------------------------------------------------------
run: $(SIM)
	./$(SIM)

run-gdb: $(SIM_GDB)
	./$(SIM_GDB)

debug: $(SIM_GDB)
	python3 run_openocd.py

wave:
	gtkwave waveform.fst &

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------
clean:
	rm -rf $(BUILD_DIR) waveform.fst waveform.vcd
	$(MAKE) -C $(RBS_DIR) clean
	rm -f $(RBS_LIB)

.PHONY: all run run-gdb debug wave clean