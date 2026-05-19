#!/usr/bin/env bash
set -e

CV32E40P_PATH="cv32e40p/rtl"
OUT_DIR="sv2v_out"

mkdir -p "$OUT_DIR"

echo "=== Converting project SV -> Verilog ==="

# -----------------------------
# Project RTL files
# -----------------------------
FILES=(
  axi_cnn/axi_cnn.sv
  axi_cnn/cnn_controller.sv
  axi_cnn/conv.sv
  axi_cnn/exp_last.sv
  axi_cnn/exp.sv
  axi_cnn/fc.sv
  axi_cnn/final_weights_seperate_class.sv
  axi_cnn/first_weights_seperate_filter.sv
  axi_cnn/mac.sv
  axi_cnn/prepare_data.sv
  axi_cnn/softmax.sv
  axi_data_mem/axi_data_mem.sv
  axi_gpio/axi_gpio.sv
  axi_i2c/axi_i2cm.sv
  axi_i2c/i2cm_controller.sv
  axi_i2c/lli2cm.sv
  axi_qspi/axi_qspi_controller.sv
  axi_qspi/clk_divider.sv
  axi_qspi/qspi_controller.sv
  axi_qspi/qspi_driver.sv
  axi_timer/axi_timer.sv
  axi_timer/timer.sv
  axi_uart/axi_uart.sv
  axi_uart/uart.sv
  axi_uart/uart_rx.sv
  axi_uart/uart_tx.sv
  core2axi/rtl/core2axi.sv
  rtl/axi_interconnect.sv
  rtl/boot_rom_1kB.sv
  rtl/cv32e40p_clock_gate.sv
  rtl/cv32e40p_librelane_top.sv
  rtl/instr_bus_decoder.sv
  rtl/instr_rom_8kB.sv
)

# -----------------------------
# CV32E40P core RTL files
# -----------------------------
CORE_FILES=(
  cv32e40p_aligner.sv
  cv32e40p_alu.sv
  cv32e40p_alu_div.sv
  cv32e40p_apu_disp.sv
  cv32e40p_compressed_decoder.sv
  cv32e40p_controller.sv
  cv32e40p_core.sv
  cv32e40p_cs_registers.sv
  cv32e40p_decoder.sv
  cv32e40p_ex_stage.sv
  cv32e40p_ff_one.sv
  cv32e40p_fifo.sv
  cv32e40p_hwloop_regs.sv
  cv32e40p_id_stage.sv
  cv32e40p_if_stage.sv
  cv32e40p_int_controller.sv
  cv32e40p_load_store_unit.sv
  cv32e40p_mult.sv
  cv32e40p_obi_interface.sv
  cv32e40p_popcnt.sv
  cv32e40p_prefetch_buffer.sv
  cv32e40p_prefetch_controller.sv
  cv32e40p_register_file_ff.sv
  cv32e40p_register_file_latch.sv
  cv32e40p_sleep_unit.sv
  cv32e40p_top.sv
)

# -----------------------------
# Include directories
# -----------------------------
INCLUDES=(
  -I"$CV32E40P_PATH/include"
  -I"$CV32E40P_PATH/vendor/pulp_platform_common_cells/include"
  -I"$CV32E40P_PATH/vendor/pulp_platform_fpnew/src"
)

# -----------------------------
# Common package files prepended to every sv2v call
# -----------------------------
PKG_FILES=(
  "$CV32E40P_PATH/include/cv32e40p_pkg.sv"
  "$CV32E40P_PATH/include/cv32e40p_fpu_pkg.sv"
  "$CV32E40P_PATH/include/cv32e40p_apu_core_pkg.sv"
)

# convert_one <relative_file> <source_base_dir> <output_base_dir>
convert_one () {
  local f="$1"
  local in_path="$2"
  local out_base="$3"
  local out="$out_base/${f%.sv}.v"

  mkdir -p "$(dirname "$out")"
  echo "sv2v: $in_path/$f -> $out"

  sv2v \
    "${INCLUDES[@]}" \
    "${PKG_FILES[@]}" \
    "$in_path/$f" \
    -w "$out"
}

# -----------------------------
# Convert project RTL
# -----------------------------
for f in "${FILES[@]}"; do
  convert_one "$f" "." "$OUT_DIR"
done

# -----------------------------
# Convert CV32E40P core (flat filenames, output to sv2v_out/cv32e40p/)
# -----------------------------
CORE_OUT_DIR="$OUT_DIR/cv32e40p"
mkdir -p "$CORE_OUT_DIR"

for f in "${CORE_FILES[@]}"; do
  convert_one "$f" "$CV32E40P_PATH" "$CORE_OUT_DIR"
done

echo "=== Done ==="