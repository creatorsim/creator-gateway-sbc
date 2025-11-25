#include <stdio.h>
#include <stdint.h>
#include <string.h>


int __attribute__((noinline))print_int(int value)
{
    printf("%d\n", value);
    return 0;
}

int __attribute__((noinline))print_float(float value)
{
    printf("%f\n", value);
    return 0;
}

int __attribute__((noinline))print_double(double value)
{
    printf("%lf\n", value);
    return 0;
}
int __attribute__((noinline))print_string(char *value)
{
    printf("%s\n", value);
    return 0;
}