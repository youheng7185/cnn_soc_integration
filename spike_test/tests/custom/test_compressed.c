#include "spike_test.h"

int main(void) {
    volatile int a, b, c;
    volatile int arr[4];

    a = 5;
    b = 10;
    TEST_ASSERT(a < b);
    TEST_ASSERT(!(a > b));
    TEST_ASSERT(a == a);
    TEST_ASSERT(a != b);

    a = 3;
    b = a;
    TEST_ASSERT_EQ(a, b);

    c = a + b;
    TEST_ASSERT_EQ(c, 6);

    c = a - b;
    TEST_ASSERT_EQ(c, 0);

    c = a & b;
    TEST_ASSERT_EQ(c, 3);

    c = a | b;
    TEST_ASSERT_EQ(c, 3);

    c = a ^ b;
    TEST_ASSERT_EQ(c, 0);

    a = 1;
    c = a;
    TEST_ASSERT_EQ(c, 1);

    a = 0;
    c = a;
    TEST_ASSERT_EQ(c, 0);

    c = -a;
    TEST_ASSERT_EQ(c, 0);

    a = 1;
    c = -a;
    TEST_ASSERT_EQ(c, -1);

    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;

    a = arr[0];
    TEST_ASSERT_EQ(a, 10);

    a = arr[1] + arr[2];
    TEST_ASSERT_EQ(a, 50);

    a = 0;
    for (int i = 0; i < 4; i++) {
        a += arr[i];
    }
    TEST_ASSERT_EQ(a, 100);

    for (int i = 0; i < 4; i++) {
        arr[i] = arr[i] * 2;
    }
    TEST_ASSERT_EQ(arr[0], 20);
    TEST_ASSERT_EQ(arr[1], 40);
    TEST_ASSERT_EQ(arr[2], 60);
    TEST_ASSERT_EQ(arr[3], 80);

    a = 0xAA;
    b = 0x55;
    c = a & b;
    TEST_ASSERT_EQ(c, 0);

    c = a | b;
    TEST_ASSERT_EQ(c, 0xFF);

    c = a ^ b;
    TEST_ASSERT_EQ(c, 0xFF);

    a = 1;
    c = ~a;
    TEST_ASSERT_EQ(c, -2);

    PASS();
    return 0;
}