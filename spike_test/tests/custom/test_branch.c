#include "spike_test.h"

int main(void) {
    volatile int a, b, c;
    volatile int arr[4];

    if (1) {
        a = 1;
    } else {
        a = 0;
    }
    TEST_ASSERT_EQ(a, 1);

    if (0) {
        a = 0;
    } else {
        a = 2;
    }
    TEST_ASSERT_EQ(a, 2);

    b = 10;
    if (b > 5) {
        a = 100;
    } else {
        a = 0;
    }
    TEST_ASSERT_EQ(a, 100);

    a = 5;
    b = 10;
    if (a == b) {
        c = 0;
    } else if (a < b) {
        c = 1;
    } else {
        c = 2;
    }
    TEST_ASSERT_EQ(c, 1);

    a = 0;
    b = 0;
    for (int i = 0; i < 10; i++) {
        a += i;
    }
    TEST_ASSERT_EQ(a, 45);

    a = 1;
    b = 1;
    while (a < 100) {
        a = a + a;
        b++;
    }
    TEST_ASSERT(a >= 100);
    TEST_ASSERT(b > 1);

    a = 0x12345678;
    b = 0x12345678;
    TEST_ASSERT(a == b);

    a = 0x12345678;
    b = 0x87654321;
    TEST_ASSERT(a != b);

    a = 0;
    for (int i = 0; i < 4; i++) {
        arr[i] = i * 10;
    }
    TEST_ASSERT_EQ(arr[0], 0);
    TEST_ASSERT_EQ(arr[1], 10);
    TEST_ASSERT_EQ(arr[2], 20);
    TEST_ASSERT_EQ(arr[3], 30);

    a = -1;
    if (a < 0) {
        b = 42;
    } else {
        b = 0;
    }
    TEST_ASSERT_EQ(b, 42);

    a = 100;
    if (a > 50) {
        if (a > 200) {
            b = 1;
        } else {
            b = 2;
        }
    } else {
        b = 3;
    }
    TEST_ASSERT_EQ(b, 2);

    PASS();
    return 0;
}