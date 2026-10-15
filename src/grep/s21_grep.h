#ifndef S21_GREP_H_
#define S21_GREP_H_

#include <getopt.h>
#include <regex.h>
#include <stdio.h>
#include <sys/types.h>

#include "../common/s21_common.h"

typedef struct {
  int e;
  int i;
  int v;
  int c;
  int l;
  int n;

  char **patterns;
  int pattern_count;
} GrepFlags;

int ParsingFlags(int argc, char **argv, GrepFlags *flags);

void ProcessFile(const char *filename, GrepFlags *flags, regex_t *regexes,
                 int regex_count, int *error_status, int *any_match,
                 int many_files);

#endif