#ifndef S21_GREP_P2_H_
#define S21_GREP_P2_H_

#include <getopt.h>

#include "../common/s21_common.h"

typedef struct {
  int e;
  int i;
  int v;
  int c;
  int l;
  int n;
} GrepFlags;


int GrepParsingFlags(int argc, char **argv, GrepFlags *flags);
void ConcatenateFiles(const char *filename, GrepFlags *flags, int *error_status);
void ProcessChar(int c, CatFlags *flags, int *line_number, int *is_new_line, int *prev_is_empty);



#endif