#!/usr/bin/env bash
set -e

OUT_JSON="design_config.json"

cat > "$OUT_JSON" <<EOF
{
  "EXTRA_LIBS":    "../../../.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_sram_macros/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib",
  "EXTRA_LEFS":      "../../../.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_sram_macros/lef/sky130_sram_1kbyte_1rw1r_32x256_8.lef",
  "EXTRA_GDS_FILES": "../../../.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_sram_macros/gds/sky130_sram_1kbyte_1rw1r_32x256_8.gds",

  "DESIGN_NAME": "cv32e40p_librelane_top",
  "DESIGN_IS_CORE": true,
  "VDD_NETS": "vccd1",
  "GND_NETS": "vssd1",
  "FP_PDN_MACRO_HOOKS": "u_instr_mem.u_sram.bank0 vccd1 vssd1 vccd1 vssd1, u_instr_mem.u_sram.bank1 vccd1 vssd1 vccd1 vssd1, u_instr_mem.u_sram.bank2 vccd1 vssd1 vccd1 vssd1, u_instr_mem.u_sram.bank3 vccd1 vssd1 vccd1 vssd1, u_instr_mem.u_sram.bank4 vccd1 vssd1 vccd1 vssd1, u_instr_mem.u_sram.bank5 vccd1 vssd1 vccd1 vssd1, u_instr_mem.u_sram.bank6 vccd1 vssd1 vccd1 vssd1, u_instr_mem.u_sram.bank7 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank0 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank1 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank2 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank3 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank4 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank5 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank6 vccd1 vssd1 vccd1 vssd1, u_axi_data_mem.u_sram.bank7 vccd1 vssd1 vccd1 vssd1",
  "VERILOG_FILES": [
    "dir::../../../.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_sram_macros/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v",
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

FILES=(
  axi_timer/axi_timer.sv
  axi_timer/timer.sv
  axi_gpio/axi_gpio.sv
  core2axi/rtl/core2axi.sv
  rtl/axi_interconnect.sv
  rtl/cv32e40p_clock_gate.sv
  rtl/cv32e40p_librelane_top.sv
  rtl/instr_bus_decoder.sv

  librelane_openram_cnn_soc/instr_rom_8kB.v
  librelane_openram_cnn_soc/axi_data_mem.v
  librelane_openram_cnn_soc/sram_8kbyte_1rw1r_32x2048_8.v
  rtl/boot_rom_1kB.sv

  axi_uart/axi_uart.sv
  axi_uart/uart.sv
  axi_uart/uart_rx.sv
  axi_uart/uart_tx.sv
  axi_i2c/axi_i2cm.sv
  axi_i2c/i2cm_controller.sv
  axi_i2c/lli2cm.sv
)

FILES_SV2V=(
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
  write_file "$f"
done

for f in "${FILES_SV2V[@]}"; do
  write_file "sv2v_out/$f"
done

# CV32E40P RTL (sv2v converted, under sv2v_out/cv32e40p/)
for f in "${CV32_FILES[@]}"; do
  write_file "sv2v_out/cv32e40p/$f"
done

cat >> "$OUT_JSON" <<EOF
  ],
  "CLOCK_PERIOD": 25,
  "CLOCK_PORT": "clk_i",
  "FP_CORE_UTIL": 35,
  "PL_TARGET_DENSITY_PCT": 40,
  "FP_PDN_VOFFSET": 5,
  "FP_PDN_HOFFSET": 5,
  "FP_PDN_AUTO_ADJUST": true,

  "FP_SIZING": "absolute",
  "DIE_AREA": "0 0 5800 3200",
  "PL_TARGET_DENSITY": 0.5,

  "MACRO_PLACEMENT_CFG": "dir::macro_placement.cfg",
  "RUN_KLAYOUT_XOR": false,
  "MAGIC_DRC_USE_GDS": false,
  "QUIT_ON_MAGIC_DRC": false
}
EOF

echo "Generated $OUT_JSON"