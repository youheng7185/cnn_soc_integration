#include "spike_test.h"

int main(void) {
    volatile int a, b, c;

    a = 6;
    b = 7;
    c = a * b;
    TEST_ASSERT_EQ(c, 42);

    a = 100;
    b = 200;
    c = a * b;
    TEST_ASSERT_EQ(c, 20000);

    a = -6;
    b = 7;
    c = a * b;
    TEST_ASSERT_EQ(c, -42);

    a = -6;
    b = -7;
    c = a * b;
    TEST_ASSERT_EQ(c, 42);

    a = 42;
    b = 0;
    c = a * b;
    TEST_ASSERT_EQ(c, 0);

    a = 0;
    b = 42;
    c = a * b;
    TEST_ASSERT_EQ(c, 0);

    a = 100;
    b = 7;
    c = a / b;
    TEST_ASSERT_EQ(c, 14);

    a = 100;
    b = 7;
    c = a % b;
    TEST_ASSERT_EQ(c, 2);

    a = -42;
    b = 7;
    c = a / b;
    TEST_ASSERT_EQ(c, -6);

    a = -42;
    b = 7;
    c = a % b;
    TEST_ASSERT_EQ(c, 0);

    a = 7;
    b = 3;
    c = a / b;
    TEST_ASSERT_EQ(c, 2);

    a = 7;
    b = 3;
    c = a % b;
    TEST_ASSERT_EQ(c, 1);

    a = (int)0x7FFFFFFF;
    b = 2;
    c = a * b;
    c = c / 2;
    TEST_ASSERT_EQ(c, a);

    PASS();
    return 0;
}