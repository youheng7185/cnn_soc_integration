#include "spike_test.h"

int main(void) {
    unsigned int mscratch_val;

    __asm__ volatile("csrw mscratch, %0" : : "r"(0x12345678));
    __asm__ volatile("csrr %0, mscratch" : "=r"(mscratch_val));
    TEST_ASSERT_EQ(mscratch_val, 0x12345678);

    __asm__ volatile("csrw mscratch, zero");
    __asm__ volatile("csrr %0, mscratch" : "=r"(mscratch_val));
    TEST_ASSERT_EQ(mscratch_val, 0);

    __asm__ volatile("csrw mscratch, zero");
    __asm__ volatile("csrs mscratch, %0" : : "r"(0x00000001));
    __asm__ volatile("csrr %0, mscratch" : "=r"(mscratch_val));
    TEST_ASSERT_EQ(mscratch_val, 0x00000001);

    __asm__ volatile("csrw mscratch, %0" : : "r"(0xFFFFFFFFu));
    __asm__ volatile("csrc mscratch, %0" : : "r"(0x00000001));
    __asm__ volatile("csrr %0, mscratch" : "=r"(mscratch_val));
    TEST_ASSERT_EQ(mscratch_val, 0xFFFFFFFEu);

    __asm__ volatile("csrw mscratch, %0" : : "r"(0xAAAAAAAAu));
    __asm__ volatile("csrs mscratch, %0" : : "r"(0x55555555u));
    __asm__ volatile("csrr %0, mscratch" : "=r"(mscratch_val));
    TEST_ASSERT_EQ(mscratch_val, 0xFFFFFFFFu);

    PASS();
    return 0;
}