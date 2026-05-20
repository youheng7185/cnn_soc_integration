#!/usr/bin/env bash
set -e

OUT_JSON="design_config.json"

cat > "$OUT_JSON" <<EOF
{
  "DESIGN_NAME": "cv32e40p_librelane_top",
  "VERILOG_FILES": [
EOF

# FILES=(
# axi_cnn/axi_cnn.v
# axi_cnn/cnn_controller.v
# axi_cnn/conv.v
# axi_cnn/exp_last.v
# axi_cnn/exp.v
# axi_cnn/fc.v
# axi_cnn/final_weights_seperate_class.v
# axi_cnn/first_weights_seperate_filter.v
# axi_cnn/mac.v
# axi_cnn/prepare_data.v
# axi_cnn/softmax.v
#   axi_i2c/axi_i2cm.v
#   axi_i2c/i2cm_controller.v
#   axi_i2c/lli2cm.v

#   axi_qspi/axi_qspi_controller.v
#   axi_qspi/clk_divider.v
#   axi_qspi/qspi_controller.v
#   axi_qspi/qspi_driver.v
#   axi_uart/axi_uart.v
#   axi_uart/uart.v
#   axi_uart/uart_rx.v
#   axi_uart/uart_tx.v
  # axi_data_mem/axi_data_mem.v
  # axi_gpio/axi_gpio.v
  #rtl/instr_rom_8kB.v
    #rtl/boot_rom_1kB.v
FILES=(
  axi_timer/axi_timer.v
  axi_timer/timer.v
  axi_gpio/axi_gpio.v
  core2axi/rtl/core2axi.v
  rtl/axi_interconnect.v

  rtl/cv32e40p_clock_gate.v
  rtl/cv32e40p_librelane_top.v
  rtl/instr_bus_decoder.v
)

# -----------------------------
# CV32E40P RTL (filtered), register latch removed
# -----------------------------
CV32_FILES=(
  cv32e40p_aligner.v
  cv32e40p_alu.v
  cv32e40p_alu_div.v
  cv32e40p_apu_disp.v
  cv32e40p_compressed_decoder.v
  cv32e40p_controller.v
  cv32e40p_core.v
  cv32e40p_cs_registers.v
  cv32e40p_decoder.v
  cv32e40p_ex_stage.v
  cv32e40p_ff_one.v
  cv32e40p_fifo.v
  cv32e40p_hwloop_regs.v
  cv32e40p_id_stage.v
  cv32e40p_if_stage.v
  cv32e40p_int_controller.v
  cv32e40p_load_store_unit.v
  cv32e40p_mult.v
  cv32e40p_obi_interface.v
  cv32e40p_popcnt.v
  cv32e40p_prefetch_buffer.v
  cv32e40p_prefetch_controller.v
  cv32e40p_register_file_ff.v
  cv32e40p_sleep_unit.v
  cv32e40p_top.v
)

# -----------------------------
# CV32E40P include ONLY 3 pkgs
# -----------------------------
CV32_INCLUDE=(
  cv32e40p_apu_core_pkg.sv
  cv32e40p_fpu_pkg.sv
  cv32e40p_pkg.sv
)

first=1

write_file () {
  local f="$1"
  if [ $first -eq 1 ]; then
    first=0
  else
    echo "," >> "$OUT_JSON"
  fi
  echo "    \"dir::$f\"" >> "$OUT_JSON"
}

# CV32E40P includes (ONLY 3 files)
for f in "${CV32_INCLUDE[@]}"; do
  write_file "cv32e40p/rtl/include/$f"
done

# Project RTL
for f in "${FILES[@]}"; do
  write_file "sv2v_out/$f"
done

# CV32E40P RTL (sv2v converted, under sv2v_out/cv32e40p/)
for f in "${CV32_FILES[@]}"; do
  write_file "sv2v_out/cv32e40p/$f"
done

cat >> "$OUT_JSON" <<EOF
  ],
  "CLOCK_PERIOD": 25,
  "CLOCK_PORT": "clk",
  "FP_CORE_UTIL": 35,
  "PL_TARGET_DENSITY_PCT": 40,
  "FP_PDN_VOFFSET": 5,
  "FP_PDN_HOFFSET": 5,
  "FP_PDN_AUTO_ADJUST": true
}
EOF

echo "Generated $OUT_JSON"