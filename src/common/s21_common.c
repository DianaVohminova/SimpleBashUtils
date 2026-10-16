#include "s21_common.h"

int isNoPrinting(unsigned char c) {
  return (c < 32 && c != '\t' && c != '\n') || c == 127 || c > 127;
}

void PrintEscapedChar(unsigned char c, int flag_v, int flag_T, int flag_E) {
  if (c == '\t' && flag_T) {
    printf("^I");
  } else if (c == '\n') {
    if (flag_E) putchar('$');
    putchar('\n');
  } else if (c == '\r' && (flag_v || flag_E)) {
    printf("^M");
  } else if (flag_v && isNoPrinting(c)) {
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

FILE* OpenFile(const char* filename, const char* prog_name) {
  FILE* file = NULL;

  if (filename[0] == '-' && filename[1] == '\0') {
    file = stdin;
  } else {
    file = fopen(filename, "r");
    if (file == NULL && prog_name != NULL) {
      fprintf(stderr, "%s: %s: No such file or directory\n", prog_name,
              filename);
    }
  }

  return file;
}
