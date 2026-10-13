#include "s21_grep_p2.h"
#include <pcre2.h>


int main(int argc, char *argv[]) {
    GrepFlags flags = {0};
    int error_status = 0;



    return error_status;
}


int GrepParsingFlags(int argc, char **argv, GrepFlags *flags) {
    int opt;
    int error = 0;

    const char *short_options = "eivcln";

    static const struct option long_options[] = {
        {"number-nonblank", no_argument, NULL, 'b'},
        {"number", no_argument, NULL, 'n'},
        {"squeeze-blank", no_argument, NULL, 's'},
        {"show-nonprinting", no_argument, NULL, 'v'},
        {"show-ends", no_argument, NULL, 'E'},
        {"show-tabs", no_argument, NULL, 'T'},
        {"show-all", no_argument, NULL, 'A'},
        {NULL, 0, NULL, 0}};

  while ((opt = getopt_long(argc, argv, short_options, long_options, NULL)) != -1) {
    switch (opt) {
      case 'e':
        flags->e = 1;
        break;
      case 'i':
        flags->i = 1;
        break;
      case 'v':
        flags->v = 1;
        break;
      case 'c':
        flags->c = 1;
        break;
      case 'l':
        flags->l = 1;
        break;
      case 'n':
        flags->n = 1;
        break;
      default:
        error = 1;
        break;
    }
  }
  return error;
}

