RISCV_PREFIX ?= riscv32-unknown-elf-
CC       = $(RISCV_PREFIX)gcc
OBJCOPY  = $(RISCV_PREFIX)objcopy

ARCH_FLAGS = -march=rv32imc_zicsr -mabi=ilp32
CFLAGS  = $(ARCH_FLAGS) -O1 -g -Wall -nostdlib -nostartfiles -static
CFLAGS += -ffunction-sections -fdata-sections -I.

LDFLAGS_SPIKE = $(ARCH_FLAGS) -T spike_link.ld -nostdlib -nostartfiles -static -Wl,--gc-sections
LDFLAGS_SOC   = $(ARCH_FLAGS) -T soc_link.ld -nostdlib -nostartfiles -static -Wl,--gc-sections

BUILD_DIR = build

TESTS = test_alu test_branch test_load_store test_csr test_mul_div test_compressed dhrystone

COMPARE_TOOL = $(BUILD_DIR)/compare_trace

.PHONY: all clean spike soc

all: $(BUILD_DIR) $(COMPARE_TOOL) spike soc

spike: $(foreach t,$(TESTS),$(BUILD_DIR)/$(t)_spike.elf)

soc: $(foreach t,$(TESTS),$(BUILD_DIR)/$(t)_soc.elf) $(foreach t,$(TESTS),$(BUILD_DIR)/$(t)_soc_clean.hex) $(foreach t,$(TESTS),$(BUILD_DIR)/$(t)_soc_clean_byte.hex)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(COMPARE_TOOL): tools/compare_trace.c | $(BUILD_DIR)
	gcc -O2 -o $@ $<

define spike_template
$(BUILD_DIR)/$(1)_spike.elf: $(2) spike_crt0.S spike_link.ld spike_test.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS_SPIKE) spike_crt0.S $(2) -o $$@
endef

define soc_template
$(BUILD_DIR)/$(1)_soc.elf: $(2) soc_crt0.S soc_link.ld spike_test.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS_SOC) soc_crt0.S $(2) -o $$@

$(BUILD_DIR)/$(1)_soc_clean.hex: $(BUILD_DIR)/$(1)_soc.elf
	$(OBJCOPY) -O binary $$< $(BUILD_DIR)/$(1)_soc.bin
	od -An -tx4 -w4 -v $(BUILD_DIR)/$(1)_soc.bin | awk '{print $$$$1}' > $$@
	@echo "Hex: $$@"

$(BUILD_DIR)/$(1)_soc_clean_byte.hex: $(BUILD_DIR)/$(1)_soc.elf
	hexdump -v -e '1/1 "%02x\n"' $(BUILD_DIR)/$(1)_soc.bin > $$@
	@echo "Byte hex: $$@"
endef

$(eval $(call spike_template,test_alu,tests/custom/test_alu.c))
$(eval $(call spike_template,test_branch,tests/custom/test_branch.c))
$(eval $(call spike_template,test_load_store,tests/custom/test_load_store.c))
$(eval $(call spike_template,test_csr,tests/custom/test_csr.c))
$(eval $(call spike_template,test_mul_div,tests/custom/test_mul_div.c))
$(eval $(call spike_template,test_compressed,tests/custom/test_compressed.c))
$(eval $(call spike_template,dhrystone,tests/bench/dhrystone.c))

$(eval $(call soc_template,test_alu,tests/custom/test_alu.c))
$(eval $(call soc_template,test_branch,tests/custom/test_branch.c))
$(eval $(call soc_template,test_load_store,tests/custom/test_load_store.c))
$(eval $(call soc_template,test_csr,tests/custom/test_csr.c))
$(eval $(call soc_template,test_mul_div,tests/custom/test_mul_div.c))
$(eval $(call soc_template,test_compressed,tests/custom/test_compressed.c))
$(eval $(call soc_template,dhrystone,tests/bench/dhrystone.c))

clean:
	rm -rf $(BUILD_DIR)