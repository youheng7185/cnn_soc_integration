.section .init
    .globl _start
# ===========================================================
# UART
# ===========================================================
    .equ UART_BASE, 0x80000200
    .equ UART_PRE,  0x00
    .equ UART_STP,  0x04
    .equ UART_RDR,  0x08
    .equ UART_TDR,  0x0C
    .equ UART_CFG,  0x10
# ===========================================================
# QSPI
# ===========================================================
    .equ QSPI_BASE, 0x80000500
    .equ QSPI_CCR,  0x00
    .equ QSPI_ADR,  0x04
    .equ QSPI_DR,   0x08
    .equ QSPI_STA,  0x0C
    .equ QSPI_FCR,  0x10
# ===========================================================
# RAM DEST
# ===========================================================
    .equ RAM_BASE, 0x20000000
# ===========================================================
# ENTRY
# ===========================================================
_start:
# -----------------------------------------------------------
# UART INIT
# -----------------------------------------------------------
    li      t0, UART_BASE
    li      t1, 217
    sw      t1, UART_PRE(t0)
    li      t1, 0
    sw      t1, UART_STP(t0)

# -----------------------------------------------------------
# REGISTER SETUP
#   s0 = QSPI_BASE
#   s1 = RAM write pointer
#   s2 = outer block counter (32 blocks)
#   s3 = flash address
# -----------------------------------------------------------
    li      s0, QSPI_BASE
    li      s1, RAM_BASE
    li      s2, 32
    li      s3, 0x00000000

# ===========================================================
# OUTER LOOP
# ===========================================================
qspi_block_loop:

    # -------------------------------------------------------
    # 1. Clear DONE status from previous transaction
    #    Write CCR with bit31=1 (clr_status), then wait
    #    until DONE deasserts
    # -------------------------------------------------------
    li      t0, (1 << 31)          # clr_status bit only
    sw      t0, QSPI_CCR(s0)

wait_clr:
    lw      t0, QSPI_STA(s0)
    andi    t0, t0, 1              # check DONE bit
    bnez    t0, wait_clr           # loop until DONE=0

    # -------------------------------------------------------
    # 2. Flush FIFOs
    # -------------------------------------------------------
    li      t0, 0x3
    sw      t0, QSPI_FCR(s0)

    # -------------------------------------------------------
    # 3. Write flash address
    # -------------------------------------------------------
    sw      s3, QSPI_ADR(s0)

    # -------------------------------------------------------
    # 4. Build CCR and trigger
    #    cmd=0x6C, data_mode=3(quad), dir=0(read),
    #    dummy=8, dsize_m1=255, prescaler=1
    # -------------------------------------------------------
    li      t0, 0x6C
    li      t1, (3 << 8)
    or      t0, t0, t1
    li      t1, (8 << 11)
    or      t0, t0, t1
    li      t1, (255 << 16)
    or      t0, t0, t1
    li      t1, (1 << 25)
    or      t0, t0, t1
    sw      t0, QSPI_CCR(s0)       # triggers the transfer

    # -------------------------------------------------------
    # 5. Wait for DONE
    # -------------------------------------------------------
wait_done:
    lw      t0, QSPI_STA(s0)
    andi    t0, t0, 1
    beqz    t0, wait_done

    # -------------------------------------------------------
    # 6. Drain 64 words (256 bytes) into RAM
    # -------------------------------------------------------
    li      t3, 64

drain_loop:
    lw      t0, QSPI_DR(s0)
    sw      t0, 0(s1)
    addi    s1, s1, 4
    addi    t3, t3, -1
    bnez    t3, drain_loop

    # -------------------------------------------------------
    # 7. Advance flash address, decrement block counter
    # -------------------------------------------------------
    addi    s3, s3, 0x100
    addi    s2, s2, -1
    bnez    s2, qspi_block_loop

# ===========================================================
# DONE — send "OK\n"
# ===========================================================
    li      t2, 0x4F
    jal     ra, uart_send
    li      t2, 0x4B
    jal     ra, uart_send
    li      t2, 0x0A
    jal     ra, uart_send

# ===========================================================
# JUMP TO LOADED IMAGE
# ===========================================================
    li      t0, 0x80000000
    jr      t0

# ===========================================================
# UART SEND
# ===========================================================
uart_send:
    li      t0, UART_BASE
    sw      t2, UART_TDR(t0)
    li      t1, 1
    sw      t1, UART_CFG(t0)
    li      t1, 0
    sw      t1, UART_CFG(t0)
wait_tx:
    lw      t1, UART_CFG(t0)
    andi    t1, t1, 4
    beqz    t1, wait_tx
    ret

.section .stack
.align 4
.globl _stack_top
_stack_top:
.space 256