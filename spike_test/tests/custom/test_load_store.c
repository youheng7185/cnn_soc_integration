#include "spike_test.h"

int main(void) {
    volatile int data[16];
    volatile int val;
    volatile char *cdata = (volatile char *)data;
    volatile short *sdata = (volatile short *)data;

    data[0] = 0x12345678;
    data[1] = 0xABCDEF01;
    data[2] = 0;
    data[3] = -1;

    val = data[0];
    TEST_ASSERT_EQ(val, 0x12345678);

    val = data[1];
    TEST_ASSERT_EQ(val, (int)0xABCDEF01u);

    data[4] = 0x11223344;
    val = data[4];
    TEST_ASSERT_EQ(val, 0x11223344);

    val = cdata[0];
    TEST_ASSERT_EQ((unsigned char)val, 0x78);

    val = cdata[1];
    TEST_ASSERT_EQ((unsigned char)val, 0x56);

    val = cdata[4];
    TEST_ASSERT_EQ((unsigned char)val, 0x01);

    sdata[0] = 0x5678;
    val = sdata[0];
    TEST_ASSERT_EQ(val, 0x5678);

    sdata[1] = (short)-1;
    val = sdata[1];
    TEST_ASSERT_EQ(val, -1);

    cdata[0] = (char)0xAB;
    val = (signed char)cdata[0];
    TEST_ASSERT_EQ(val, (signed char)0xAB);

    cdata[0] = 0x42;
    val = cdata[0];
    TEST_ASSERT_EQ((unsigned char)val, 0x42);

    data[5] = 0;
    data[5] = data[5] + 1;
    TEST_ASSERT_EQ(data[5], 1);

    data[5] = 0;
    for (int i = 0; i < 100; i++) {
        data[5] = data[5] + 1;
    }
    TEST_ASSERT_EQ(data[5], 100);

    data[6] = 0xDEADBEEF;
    val = data[6];
    TEST_ASSERT_EQ(val, (int)0xDEADBEEFu);

    data[7] = 0;
    data[7] |= 0xFF00FF00;
    TEST_ASSERT_EQ(data[7], (int)0xFF00FF00u);

    PASS();
    return 0;
}