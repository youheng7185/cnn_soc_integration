# ============================================================
# Verilator Makefile – CV32E40P SoC
# ============================================================
TOP            := cv32e40p_verilator_top
BUILD_DIR      := obj_dir
SIM            := $(BUILD_DIR)/V$(TOP)
VERILATOR      := verilator
CXXFLAGS       := -O2 -std=c++17

VERILATOR_FLAGS := \
    --cc \
    --exe \
    --Wall \
    -Wno-fatal \
    --top-module $(TOP) \
    -Mdir $(BUILD_DIR) \
    -CFLAGS "$(CXXFLAGS)" \
    --timing \
    -DCV32E40P_TRACE_EXECUTION

# ------------------------------------------------------------
# Testbench
# ------------------------------------------------------------
TB_CPP := tb/tb.cpp

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

# CV32_BHV := $(shell find cv32e40p/bhv -name "*.sv")
CV32_BHV := \
    cv32e40p/bhv/cv32e40p_sim_clock_gate.sv \
    cv32e40p/bhv/cv32e40p_tracer.sv

RTL_SRC := \
    rtl/include/uvm_pkg.sv \
    $(CV32_PKG) \
    $(CV32_CORE) \
    $(CV32_BHV) \
    core2axi/rtl/core2axi.sv \
    axi_cnn/axi_cnn.sv \
    axi_cnn/cnn_controller.sv \
    axi_cnn/conv.sv \
    axi_cnn/fc.sv \
    axi_cnn/final_weights_seperate_class.sv \
    axi_cnn/first_weights_seperate_filter.sv \
    axi_cnn/mac.sv \
    axi_cnn/prepare_data.sv \
    axi_cnn/softmax.sv \
    axi_gpio/axi_gpio.sv \
    axi_timer/timer.sv \
    axi_timer/axi_timer.sv \
    axi_uart/axi_uart.sv \
    axi_uart/uart.sv \
    axi_uart/uart_rx.sv \
    axi_uart/uart_tx.sv \
    axi_data_mem/axi_data_mem.sv \
    axi_i2c/axi_i2cm.sv \
    axi_i2c/i2cm_controller.sv \
    axi_i2c/lli2cm.sv \
    axi_qspi/axi_qspi_verilator.sv \
    axi_qspi/axi_qspi_controller.sv \
    axi_qspi/qspi_driver.sv \
    axi_qspi/qspi_flash_model.sv \
    axi_qspi/qspi_controller.sv \
    axi_qspi/clk_divider.sv \
    rtl/axi_interconnect.sv \
    rtl/instr_bus_decoder.sv \
    rtl/instr_rom_8kB.sv \
    rtl/boot_rom_1kB.sv \
    rtl/cv32e40p_verilator_top.sv

# Include paths (SystemVerilog packages)
INCLUDES := \
    -Icv32e40p/rtl/include \
    -Icv32e40p/bhv/include \
    -Icv32e40p/bhv \
    -Irtl/include


# ------------------------------------------------------------
# Build rules
# ------------------------------------------------------------
all: $(SIM)

$(SIM): $(RTL_SRC) $(TB_CPP)
	$(VERILATOR) $(VERILATOR_FLAGS) $(INCLUDES) \
		$(VERILATOR_DEFS) \
		$(RTL_SRC) \
		$(TB_CPP)
	$(MAKE) -C $(BUILD_DIR) -f V$(TOP).mk

run: $(SIM)
	@if [ -d cnn_soc_c_project ]; then \
		echo "[INFO] Entering cnn_soc_c_project submodule..."; \
		$(MAKE) -C cnn_soc_c_project clean && $(MAKE) -C cnn_soc_c_project all; \
		echo "[INFO] Returning to top-level simulation..."; \
	fi
	./$(SIM)

wave: run
	gtkwave waveform.fst &

clean:
	rm -rf $(BUILD_DIR) waveform.fst waveform.vcd

.PHONY: all run wave clean