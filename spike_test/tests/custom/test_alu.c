#include "spike_test.h"

int main(void) {
    volatile int results[32];

    results[0] = 1 + 2;
    TEST_ASSERT_EQ(results[0], 3);

    results[1] = 100 + 200;
    TEST_ASSERT_EQ(results[1], 300);

    results[2] = 50 - 30;
    TEST_ASSERT_EQ(results[2], 20);

    results[3] = 10 - 100;
    TEST_ASSERT_EQ(results[3], -90);

    results[4] = 6 & 3;
    TEST_ASSERT_EQ(results[4], 2);

    results[5] = 0xFF & 0x0F;
    TEST_ASSERT_EQ(results[5], 0x0F);

    results[6] = 0xF0 | 0x0F;
    TEST_ASSERT_EQ(results[6], 0xFF);

    results[7] = 0xFF ^ 0x0F;
    TEST_ASSERT_EQ(results[7], 0xF0);

    results[8] = 1 << 4;
    TEST_ASSERT_EQ(results[8], 16);

    results[9] = 0x80 >> 4;
    TEST_ASSERT_EQ(results[9], 0x08);

    results[10] = (int)(0x80000000u) >> 4;
    TEST_ASSERT_EQ(results[10], (int)0xF8000000);

    results[11] = (int)(0x80000000u) >> 31;
    TEST_ASSERT_EQ(results[11], -1);

    results[12] = 5 < 10;
    TEST_ASSERT(results[12] != 0);

    results[13] = 10 < 5;
    TEST_ASSERT_EQ(results[13], 0);

    results[14] = (int)(0x80000000u) < 5;
    TEST_ASSERT(results[14] != 0);

    results[15] = (int)(0x80000000u);
    results[16] = (results[15] < 0) ? 1 : 0;
    TEST_ASSERT_EQ(results[16], 1);

    results[17] = 5;
    results[18] = 10;
    TEST_ASSERT(results[17] < results[18]);

    results[19] = 0xFFFFFFFFu;
    TEST_ASSERT((unsigned)results[19] > 5);

    results[20] = ~(0);
    TEST_ASSERT_EQ(results[20], -1);

    results[21] = 0;
    TEST_ASSERT_EQ(results[21], 0);

    results[22] = -1;
    TEST_ASSERT(results[22] < 0);

    results[23] = 1;
    TEST_ASSERT(results[23] > 0);

    results[24] = 7;
    results[25] = 3;
    results[26] = results[24] % results[25];
    TEST_ASSERT_EQ(results[26], 1);

    results[27] = 100;
    results[28] = 7;
    results[29] = results[27] / results[28];
    TEST_ASSERT_EQ(results[29], 14);

    results[30] = -7;
    results[31] = 2;
    results[0] = results[30] % results[31];
    TEST_ASSERT_EQ(results[0], -1);

    PASS();
    return 0;
}