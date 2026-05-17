OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    imem (rx) : ORIGIN = 0x00000000, LENGTH = 0x00000400
}

SECTIONS
{
    .text :
    {
        *(.init)
        *(.text*)
    } > imem

    .stack :
    {
        . = . + 0x100;
        _stack_top = .;
    } > imem
}