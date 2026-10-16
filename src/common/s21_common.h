#ifndef S21_COMMON_H
#define S21_COMMON_H

#include <stdio.h>
#include <stdlib.h>

int isNoPrinting(unsigned char c);
void PrintEscapedChar(unsigned char c, int flag_v, int flag_T, int flag_E);
FILE* OpenFile(const char* filename, const char* prog_name);

#endif