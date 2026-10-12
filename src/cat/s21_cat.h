#ifndef S21_CAT_H_
#define S21_CAT_H_

#include <getopt.h>
#include "../common/s21_common.h"

typedef struct {
  int b;  // -b, --number-nonblank
  int e;  // -e (эквивалент -vE)
  int n;  // -n, --number
  int s;  // -s, --squeeze-blank
  int t;  // -t (эквивалент -vT)
  int v;  // -v, --show-nonprinting
  int E;  // -E, --show-ends
  int T;  // -T, --show-tabs
  int A;
} CatFlags;

int parsing_flags(int argc, char **argv, CatFlags *flags);
void print_file(const char *filename, CatFlags *flags, int *error_status, int *line_number);

#endif  // S21_CAT_H_