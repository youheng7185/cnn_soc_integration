#ifndef SPIKE_TEST_H
#define SPIKE_TEST_H

#define PASS() do { \
    volatile int *_gpio = (volatile int *)0x80000000; \
    *_gpio = 0x0001; \
    while (1); \
} while (0)

#define FAIL(code) do { \
    volatile int *_gpio = (volatile int *)0x80000000; \
    *_gpio = ((code) << 1) | 0x0002; \
    while (1); \
} while (0)

#define TEST_ASSERT(cond) do { \
    if (!(cond)) { FAIL(1); } \
} while (0)

#define TEST_ASSERT_EQ(actual, expected) do { \
    if ((actual) != (expected)) { FAIL(2); } \
} while (0)

#define TEST_ASSERT_NE(actual, not_expected) do { \
    if ((actual) == (not_expected)) { FAIL(3); } \
} while (0)

#endif