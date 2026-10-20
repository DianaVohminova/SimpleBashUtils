#include "s21_cat.h"

#include <stdio.h>
#include <unistd.h>

int main(int argc, char* argv[]) {
  CatFlags flags = {0};
  int error_status = 0;
  int line_number = 1;

  error_status = CatParsingFlags(argc, argv, &flags);

  if (error_status == 0) {
    if (optind == argc) {
      ConcatenateFiles("-", &flags, &error_status, &line_number);
    } else {
      for (int i = optind; i < argc; ++i) {
        ConcatenateFiles(argv[i], &flags, &error_status, &line_number);
      }
    }
  }
  return error_status;
}

int CatParsingFlags(int argc, char** argv, CatFlags* flags) {
  int opt;
  int error = 0;

  const char* short_options = "benstvET";

  static const struct option long_options[] = {
      {"number-nonblank", no_argument, NULL, 'b'},
      {"number", no_argument, NULL, 'n'},
      {"squeeze-blank", no_argument, NULL, 's'},
      {NULL, 0, NULL, 0}};

  while ((opt = getopt_long(argc, argv, short_options, long_options, NULL)) !=
         -1) {
    switch (opt) {
      case 'b':
        flags->b = 1;
        break;
      case 'e':
        flags->e = 1;
        flags->v = 1;
        flags->E = 1;
        break;
      case 'n':
        flags->n = 1;
        break;
      case 's':
        flags->s = 1;
        break;
      case 't':
        flags->t = 1;
        flags->v = 1;
        flags->T = 1;
        break;
      case 'v':
        flags->v = 1;
        break;
      case 'E':
        flags->E = 1;
        break;
      case 'T':
        flags->T = 1;
        break;
      default:
        error = 1;
        break;
    }
  }
  return error;
}

void ProcessChar(int c, CatFlags* flags, int* line_number, int* is_new_line,
                 int* prev_is_empty) {
  int cur_is_nl = (c == '\n');
  int was_empty_line = *is_new_line;
  int skip = (flags->s && cur_is_nl && *prev_is_empty);

  if (cur_is_nl) {
    *prev_is_empty = was_empty_line;
  } else {
    *prev_is_empty = 0;
  }

  if (!skip) {
    if (*is_new_line) {
      if (flags->n && !flags->b) {
        printf("%6d\t", (*line_number)++);
      } else if (flags->b && !cur_is_nl) {
        printf("%6d\t", (*line_number)++);
      }
      *is_new_line = 0;
    }

    PrintEscapedChar((unsigned char)c, flags->v, flags->T, flags->E);

    if (cur_is_nl) {
      *is_new_line = 1;
    }
  }
}

void ConcatenateFiles(const char* filename, CatFlags* flags, int* error_status,
                      int* line_number) {
  FILE* file = OpenFile(filename, "s21_cat");

  if (file != NULL) {
    int c;
    int is_new_line = 1;
    int prev_is_empty = 0;

    while ((c = fgetc(file)) != EOF) {
      ProcessChar(c, flags, line_number, &is_new_line, &prev_is_empty);
    }

    if (file != stdin) {
      fclose(file);
    }
  } else {
    *error_status = 1;
  }
}