#define _POSIX_C_SOURCE 200809L
#include "s21_grep.h"

#include <stdlib.h>
#include <string.h>

static int LineMatches(const char *line, const GrepFlags *flags,
                       regex_t *regexes, int regex_count);
static void PrintMatchedLine(const char *line, int line_no,
                             const char *filename, const GrepFlags *flags,
                             int many_files, ssize_t len);
static void CompileAllPatterns(const GrepFlags *flags, regex_t *regexes,
                               int *compiled, int *error_status);

int main(int argc, char *argv[]) {
  GrepFlags flags = {0};
  int error_status = 0;
  int any_match = 0;

  if (ParsingFlags(argc, argv, &flags) != 0 || flags.pattern_count == 0) {
    fprintf(stderr, "Usage: s21_grep [-eivcln] pattern [file...]\n");
    error_status = 2;
  } else {
    regex_t *regexes = calloc(flags.pattern_count, sizeof(regex_t));
    if (regexes == NULL) {
      fprintf(stderr, "s21_grep: out of memory\n");
      error_status = 2;
    } else {
      int compiled = 0;
      CompileAllPatterns(&flags, regexes, &compiled, &error_status);

      if (error_status == 0) {
        int file_count = argc - optind;

        if (file_count == 0) {
          ProcessFile("-", &flags, regexes, flags.pattern_count, &error_status,
                      &any_match, 0);
        } else {
          int many_files = file_count > 1;
          for (int i = optind; i < argc; i++) {
            ProcessFile(argv[i], &flags, regexes, flags.pattern_count,
                        &error_status, &any_match, many_files);
          }
        }
      }

      for (int i = 0; i < compiled; i++) regfree(&regexes[i]);
      free(regexes);
    }
  }

  if (error_status == 2) return 2;
  return any_match ? 0 : 1;
}

static void CompileAllPatterns(const GrepFlags *flags, regex_t *regexes,
                               int *compiled, int *error_status) {
  int reg_flags = 0;
  if (flags->i) reg_flags |= REG_ICASE;

  for (int i = 0; i < flags->pattern_count; i++) {
    int rc = regcomp(&regexes[i], flags->patterns[i], reg_flags);
    if (rc != 0) {
      char errbuf[256];
      regerror(rc, &regexes[i], errbuf, sizeof(errbuf));
      fprintf(stderr, "s21_grep: %s\n", errbuf);
      *error_status = 2;
      return;
    }
    (*compiled)++;
  }
}

int ParsingFlags(int argc, char **argv, GrepFlags *flags) {
  int opt;
  int error = 0;

  flags->patterns = calloc(argc, sizeof(char *));
  if (flags->patterns == NULL) return 1;

  while ((opt = getopt(argc, argv, "e:ivcln")) != -1) {
    switch (opt) {
      case 'e':
        flags->e = 1;
        flags->patterns[flags->pattern_count++] = optarg;
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

  if (!error && !flags->e) {
    if (optind < argc) {
      flags->patterns[flags->pattern_count++] = argv[optind++];
    } else {
      error = 1;
    }
  }

  return error;
}

void ProcessFile(const char *filename, GrepFlags *flags, regex_t *regexes,
                 int regex_count, int *error_status, int *any_match,
                 int many_files) {
  int open_err = 0;
  FILE *f = OpenFile(filename, &open_err);

  if (f != NULL) {
    char *line = NULL;
    size_t cap = 0;
    ssize_t len;
    int line_no = 0;
    int match_count = 0;

    while ((len = getline(&line, &cap, f)) != -1) {
      line_no++;

      if (!LineMatches(line, flags, regexes, regex_count)) continue;

      *any_match = 1;
      match_count++;

      if (flags->l) {
        printf("%s\n", filename);
        break;
      }

      if (!flags->c) {
        PrintMatchedLine(line, line_no, filename, flags, many_files, len);
      }
    }

    if (flags->c && !flags->l) {
      if (many_files) printf("%s:", filename);
      printf("%d\n", match_count);
    }

    free(line);
    if (f != stdin) fclose(f);
  } else {
    *error_status = 2;
  }
}

static int LineMatches(const char *line, const GrepFlags *flags,
                       regex_t *regexes, int regex_count) {
  int matched = 0;
  for (int i = 0; i < regex_count && !matched; i++) {
    if (regexec(&regexes[i], line, 0, NULL, 0) == 0) matched = 1;
  }
  if (flags->v) matched = !matched;
  return matched;
}

static void PrintMatchedLine(const char *line, int line_no,
                             const char *filename, const GrepFlags *flags,
                             int many_files, ssize_t len) {
  if (many_files) printf("%s:", filename);
  if (flags->n) printf("%d:", line_no);
  fputs(line, stdout);
  if (len > 0 && line[len - 1] != '\n') putchar('\n');
}