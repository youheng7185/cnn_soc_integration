set cv32e40p_path "cv32e40p"

# ============================================================
# Add specific files here
# ============================================================

set rtl_files [list \
    "axi_cnn/axi_cnn.sv" \
    "axi_cnn/cnn_controller.sv" \
    "axi_cnn/conv.sv" \
    "axi_cnn/exp_last.sv" \
    "axi_cnn/exp.sv" \
    "axi_cnn/fc.sv" \
    "axi_cnn/final_weights_seperate_class.sv" \
    "axi_cnn/first_weights_seperate_filter.sv" \
    "axi_cnn/mac.sv" \
    "axi_cnn/prepare_data.sv" \
    "axi_cnn/softmax.sv" \
    "axi_data_mem/axi_data_mem.sv" \
    "axi_gpio/axi_gpio.sv" \
    "axi_i2c/axi_i2cm.sv" \
    "axi_i2c/i2cm_controller.sv" \
    "axi_i2c/lli2cm.sv" \
    "axi_qspi/axi_qspi_controller.sv" \
    "axi_qspi/clk_divider.sv" \
    "axi_qspi/qspi_controller.sv" \
    "axi_qspi/qspi_driver.sv" \
    "axi_timer/axi_timer.sv" \
    "axi_timer/timer.sv" \
    "axi_uart/axi_uart.sv" \
    "axi_uart/uart.sv" \
    "axi_uart/uart_rx.sv" \
    "axi_uart/uart_tx.sv" \
    "core2axi/rtl/core2axi.sv" \
    "rtl/axi_interconnect.sv" \
    "rtl/boot_rom_1kB.sv" \
    "rtl/cv32e40p_clock_gate.sv" \
    "rtl/cv32e40p_vivado_top.sv" \
    "rtl/instr_bus_decoder.sv" \
    "rtl/instr_rom_8kB.sv"
]

# ============================================================
# Add files
# ============================================================

foreach file $rtl_files {
    add_files $file
}

# ============================================================
# Add CV32E40P core
# ============================================================

add_files [glob $cv32e40p_path/rtl/*.sv]
add_files [glob $cv32e40p_path/rtl/include/*.sv]
remove_files $cv32e40p_path/rtl/cv32e40p_fp_wrapper.sv

set_property include_dirs [list \
    $cv32e40p_path/rtl/include \
] [current_fileset]