.section .text.start
.global _start
.type _start, @function

_start:
    csrw mie, zero
    csrw mip, zero

    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    la sp, __stack_top

    la a0, __bss_start
    la a1, __bss_end
    bgeu a0, a1, 2f
1:
    sw zero, 0(a0)
    addi a0, a0, 4
    bltu a0, a1, 1b
2:

    call main

    li a0, 1
    lui t0, 0x80000
    sw a0, 0(t0)
3:
    j 3b

.size _start, .-_start