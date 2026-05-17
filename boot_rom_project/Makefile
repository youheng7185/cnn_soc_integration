# ===========================================================
# CV32E40P ROM Bootloader (ASM only)
# ===========================================================

RISCV_PREFIX ?= riscv32-unknown-elf-

CC      := $(RISCV_PREFIX)gcc
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump
SIZE    := $(RISCV_PREFIX)size

BUILD_DIR := build
TARGET := $(BUILD_DIR)/bootrom

# ===========================================================
# Flags (minimal, ROM-safe)
# ===========================================================

ARCH_FLAGS := -march=rv32imc_zicsr -mabi=ilp32

CFLAGS := $(ARCH_FLAGS)
CFLAGS += -Os
CFLAGS += -g
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -nostdlib -nostartfiles
CFLAGS += -fno-builtin
CFLAGS += -fno-unwind-tables -fno-asynchronous-unwind-tables

LDFLAGS := $(ARCH_FLAGS)
LDFLAGS += -T link.ld
LDFLAGS += -nostdlib -nostartfiles
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,-Map=$(BUILD_DIR)/output.map

# ===========================================================
# ONLY ASM SOURCES
# ===========================================================

ASM_SRCS := crt0.S vectors.S

# ===========================================================
# Build
# ===========================================================

all: $(BUILD_DIR) \
     $(TARGET).elf \
     $(TARGET).bin \
	 $(TARGET)_clean.hex \
	 $(TARGET)_clean_byte.hex \
     $(TARGET).dump

	@echo "========================================"
	@echo "Bootloader build complete (ASM only)"
	@echo "========================================"
	@$(SIZE) $(TARGET).elf

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# -----------------------------------------------------------
# ELF
# -----------------------------------------------------------
$(TARGET).elf: $(ASM_SRCS) link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(ASM_SRCS) -o $@
	@echo "ELF: $@"

# -----------------------------------------------------------
# Binary (for QSPI flash)
# -----------------------------------------------------------
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@
	@echo "BIN: $@"

# Generate clean hex for Verilator (without address prefixes)
$(TARGET)_clean.hex: $(TARGET).bin
	od -An -tx4 -w4 -v $< | awk '{print $$1}' > $@
	@echo "Clean hex for Verilator: $@"

# byte hex for loading into qspi flash
$(TARGET)_clean_byte.hex: $(TARGET).bin
	hexdump -v -e '1/1 "%02x\n"' $< > $@
	@echo "LSB-first byte hex generated: $@"

# -----------------------------------------------------------
# Disassembly
# -----------------------------------------------------------
$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -D -S $< > $@
	@echo "DUMP: $@"

# ===========================================================
# Utilities
# ===========================================================

clean:
	rm -rf $(BUILD_DIR)

check: $(TARGET).elf
	@echo "========================================"
	@echo "Size check (IMEM = 1024 bytes)"
	@echo "========================================"
	@$(SIZE) $(TARGET).elf

.PHONY: all clean check