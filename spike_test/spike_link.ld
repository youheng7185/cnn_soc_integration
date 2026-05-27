OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    . = 0x80000000;

    .text : {
        *(.text.start)
        *(.text .text.*)
    }

    .rodata : {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    }

    .data : {
        __DATA_BEGIN__ = .;
        *(.data .data.*)
        __SDATA_BEGIN__ = .;
        *(.sdata .sdata.*)
        PROVIDE(__global_pointer$ = . + 0x800);
    }

    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        __bss_end = .;
    }

    __stack_top = 0x80010000;
}