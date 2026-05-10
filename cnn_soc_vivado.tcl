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
    "axi_cnn/final_weights_seperate_filter.sv" \
    "axi_cnn/mac.sv" \
    "axi_cnn/prepare_data.sv" \
    "axi_cnn/softmax.sv" \
    "axi_data_mem/axi_data_mem.sv" \
    "axi_gpio/axi_gpio.sv" \
    "axi_i2c/axi_i2cm.sv" \
    "axi_i2c/i2cm_controller.sv" \
    "axi_i2c/lli2cm.sv" \
    "axi_qspi_controller/axi_qspi_controller.sv" \
    "axi_qspi_controller/clk_divider.sv" \
    "axi_qspi_controller/qspi_controller.sv" \
    "axi_qspi_controller/qspi_driver.sv" \
    "axi_timer/axi_timer.sv" \
    "axi_timer/timer.sv" \
    "axi_uart/axi_uart.sv" \
    "axi_uart/uart.sv" \
    "axi_uart/uart_rx.sv" \
    "axi_uart/uart_tx.sv" 
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

set_property include_dirs [list \
    $cv32e40p_path/rtl/include \
] [current_fileset]