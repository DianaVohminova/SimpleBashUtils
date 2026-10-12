#include "s21_common.h"

int is_no_printing(unsigned char c) {
  return (c < 32 && c != '\t' && c != '\n') || c == 127 || c > 127;
}

void print_escaped_char(unsigned char c, int flag_v, int flag_T, int flag_E) {
  if (c == '\t' && flag_T) {
    printf("^I");
  } else if (c == '\n') {
    if (flag_E) putchar('$');
    putchar('\n');
  } else if (c == '\r' && (flag_v || flag_E)) {
    printf("^M");
  } else if (flag_v && is_no_printing(c)) {
    unsigned char uc = c;
    if (uc >= 128) {
      printf("M-");
      uc -= 128;
    }
    if (uc < 32)
      printf("^%c", uc + 64);
    else if (uc == 127)
      printf("^?");
    else
      putchar(uc);
  } else {
    putchar(c);
  }
}

FILE *open_file(const char *filename, int *error_status) {
  FILE *file = NULL;

  if (filename[0] == '-' && filename[1] == '\0') {
    file = stdin;
  } else {
    file = fopen(filename, "r");

    if (file == NULL) {
      fprintf(stderr, "s21_cat: %s: No such file or directory\n", filename);
      *error_status = 1;
    }
  }
  return file;
}
