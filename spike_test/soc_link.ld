OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    imem (rx)   : ORIGIN = 0x80000000, LENGTH = 0x2000
    dmem (rwx)  : ORIGIN = 0x10000000, LENGTH = 0x4000
}

SECTIONS
{
    . = 0x80000000;

    .text : {
        *(.text.start)
        *(.text .text.*)
    } >imem

    .rodata : {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    } >imem

    .data : {
        __DATA_BEGIN__ = .;
        *(.data .data.*)
        __SDATA_BEGIN__ = .;
        *(.sdata .sdata.*)
        PROVIDE(__global_pointer$ = . + 0x800);
    } >dmem AT>imem

    _sidata = LOADADDR(.data);

    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        __bss_end = .;
    } >dmem

    PROVIDE(_edata = __bss_end);

    __stack_top = ORIGIN(dmem) + LENGTH(dmem);
}