#ifndef S21_CAT_H_
#define S21_CAT_H_

#include <getopt.h>

#include "../common/s21_common.h"

typedef struct {
  int b;
  int e;
  int n;
  int s;
  int t;
  int v;
  int E;
  int T;
} CatFlags;

int CatParsingFlags(int argc, char** argv, CatFlags* flags);
void ConcatenateFiles(const char* filename, CatFlags* flags, int* error_status,
                      int* line_number);
void ProcessChar(int c, CatFlags* flags, int* line_number, int* is_new_line,
                 int* prev_is_empty);

#endif