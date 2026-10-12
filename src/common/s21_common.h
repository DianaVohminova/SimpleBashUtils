#ifndef S21_COMMON_H
#define S21_COMMON_H

#include <stdio.h>
#include <stdlib.h>

int is_no_printing(unsigned char c);
void print_escaped_char(unsigned char c, int flag_v, int flag_T, int flag_E);
FILE *open_file(const char *filename, int *error_status);

#endif // S21_COMMON_H