#define _POSIX_C_SOURCE 200809L
#include "s21_grep.h"

#include <stdlib.h>
#include <string.h>

static int LineMatches(const char* line, const GrepFlags* flags,
                       regex_t* regexes, int regex_count);
static void PrintMatchedLine(const char* line, int line_no,
                             const char* filename, const GrepFlags* flags,
                             int many_files, ssize_t len);
static void CompileAllPatterns(const GrepFlags* flags, regex_t* regexes,
                               int* compiled, int* error_status);
static void PrintPrefix(const char* filename, int line_no,
                        const GrepFlags* flags, int many_files);
static void ProcessLine(const char* line, ssize_t len, int line_no,
                        const char* filename, GrepFlags* flags,
                        regex_t* regexes, int regex_count, int many_files,
                        int* any_match, int* match_count, int* should_break);
static void PrintMatchedContent(const char* line, ssize_t len, int line_no,
                                const char* filename, const GrepFlags* flags,
                                regex_t* regexes, int regex_count,
                                int many_files);
static void PrintMatchCount(const char* filename, const GrepFlags* flags,
                            int many_files, int match_count);

int main(int argc, char* argv[]) {
  GrepFlags flags = {0};
  int error_status = 0;
  int any_match = 0;

  if (ParsingFlags(argc, argv, &flags) != 0 || flags.pattern_count == 0) {
    fprintf(stderr, "Usage: s21_grep [-eivclnhsfo] pattern [file...]\n");
    error_status = 2;
  } else {
    regex_t* regexes = calloc(flags.pattern_count, sizeof(regex_t));
    if (regexes == NULL) {
      fprintf(stderr, "s21_grep: out of memory\n");
      error_status = 2;
    } else {
      int compiled = 0;
      CompileAllPatterns(&flags, regexes, &compiled, &error_status);
      if (error_status == 0) {
        int file_count = argc - optind;
        int many_files = file_count > 1;
        if (file_count == 0) {
          ProcessFile("-", &flags, regexes, flags.pattern_count, &error_status,
                      &any_match, 0);
        } else {
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

  for (int i = 0; i < flags.pattern_count; i++) {
    free(flags.patterns[i]);
  }
  free(flags.patterns);

  if (error_status == 2) return 2;
  return any_match ? 0 : 1;
}

static void CompileAllPatterns(const GrepFlags* flags, regex_t* regexes,
                               int* compiled, int* error_status) {
  int reg_flags = REG_NEWLINE;
  if (flags->i) reg_flags |= REG_ICASE;

  for (int i = 0; i < flags->pattern_count && *error_status == 0; i++) {
    int rc = regcomp(&regexes[i], flags->patterns[i], reg_flags);
    if (rc != 0) {
      char errbuf[256];
      regerror(rc, &regexes[i], errbuf, sizeof(errbuf));
      fprintf(stderr, "s21_grep: %s\n", errbuf);
      *error_status = 2;
    } else {
      (*compiled)++;
    }
  }
}

int ParsingFlags(int argc, char** argv, GrepFlags* flags) {
  int opt;
  int error = 0;
  flags->pattern_capacity = 16;
  flags->patterns = calloc(flags->pattern_capacity, sizeof(char*));

  if (flags->patterns == NULL) {
    error = 1;
  } else {
    while ((opt = getopt(argc, argv, "e:f:hivclnso")) != -1 && !error) {
      switch (opt) {
        case 'e':
          flags->e = 1;
          error = AddPattern(flags, optarg);
          break;
        case 'f':
          flags->f = 1;
          error = LoadPatternsFromFile(optarg, flags);
          break;
        case 'h':
          flags->h = 1;
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
        case 's':
          flags->s = 1;
          break;
        case 'o':
          flags->o = 1;
          break;
        default:
          error = 1;
          break;
      }
    }
    if (!error && !flags->e && !flags->f) {
      if (optind < argc) {
        error = AddPattern(flags, argv[optind++]);
      } else {
        error = 1;
      }
    }
  }
  return error;
}

int AddPattern(GrepFlags* flags, const char* pattern) {
  int result = 0;
  if (flags->pattern_count >= flags->pattern_capacity) {
    int new_cap = flags->pattern_capacity * 2;
    char** new_p = realloc(flags->patterns, new_cap * sizeof(char*));
    if (new_p == NULL) {
      result = 1;
    } else {
      flags->patterns = new_p;
      flags->pattern_capacity = new_cap;
    }
  }
  if (result == 0) {
    char* copy = strdup(pattern);
    if (copy == NULL) {
      result = 1;
    } else {
      flags->patterns[flags->pattern_count++] = copy;
    }
  }
  return result;
}

int LoadPatternsFromFile(const char* filename, GrepFlags* flags) {
  int result = 0;
  const char* prog_name = flags->s ? NULL : "s21_grep";
  FILE* f = OpenFile(filename, prog_name);

  if (f == NULL) {
    result = 1;
  } else {
    char* line = NULL;
    size_t cap = 0;
    ssize_t len;
    while ((len = getline(&line, &cap, f)) != -1 && result == 0) {
      if (len > 0 && line[len - 1] == '\n') line[len - 1] = '\0';
      result = AddPattern(flags, line);
    }
    free(line);
    if (f != stdin) fclose(f);
  }
  return result;
}
void ProcessFile(const char* filename, GrepFlags* flags, regex_t* regexes,
                 int regex_count, int* error_status, int* any_match,
                 int many_files) {
  const char* prog_name = flags->s ? NULL : "s21_grep";
  FILE* f = OpenFile(filename, prog_name);

  if (f != NULL) {
    char* line = NULL;
    size_t cap = 0;
    ssize_t len;
    int line_no = 0;
    int match_count = 0;
    int should_break = 0;

    while ((len = getline(&line, &cap, f)) != -1 && !should_break) {
      line_no++;
      ProcessLine(line, len, line_no, filename, flags, regexes, regex_count,
                  many_files, any_match, &match_count, &should_break);
    }

    PrintMatchCount(filename, flags, many_files, match_count);
    free(line);
    if (f != stdin) fclose(f);
  } else {
    *error_status = 2;
  }
}

static void ProcessLine(const char* line, ssize_t len, int line_no,
                        const char* filename, GrepFlags* flags,
                        regex_t* regexes, int regex_count, int many_files,
                        int* any_match, int* match_count, int* should_break) {
  int matched = LineMatches(line, flags, regexes, regex_count);
  if (!matched) return;

  *any_match = 1;
  (*match_count)++;

  if (flags->l) {
    printf("%s\n", filename);
    *should_break = 1;
  } else if (!flags->c) {
    PrintMatchedContent(line, len, line_no, filename, flags, regexes,
                        regex_count, many_files);
  }
}

static void PrintMatchedContent(const char* line, ssize_t len, int line_no,
                                const char* filename, const GrepFlags* flags,
                                regex_t* regexes, int regex_count,
                                int many_files) {
  if (flags->o && !flags->v) {
    PrintMatchedParts(line, line_no, filename, flags, regexes, regex_count,
                      many_files);
  } else {
    PrintMatchedLine(line, line_no, filename, flags, many_files, len);
  }
}

static void PrintMatchCount(const char* filename, const GrepFlags* flags,
                            int many_files, int match_count) {
  if (flags->c && !flags->l) {
    if (many_files && !flags->h) printf("%s:", filename);
    printf("%d\n", match_count);
  }
}

static int LineMatches(const char* line, const GrepFlags* flags,
                       regex_t* regexes, int regex_count) {
  int matched = 0;
  for (int i = 0; i < regex_count && !matched; i++) {
    if (regexec(&regexes[i], line, 0, NULL, 0) == 0) {
      matched = 1;
    }
  }
  if (flags->v) matched = !matched;
  return matched;
}

static void PrintPrefix(const char* filename, int line_no,
                        const GrepFlags* flags, int many_files) {
  if (many_files && !flags->h) {
    printf("%s:", filename);
  }
  if (flags->n) {
    printf("%d:", line_no);
  }
}

static void PrintMatchedLine(const char* line, int line_no,
                             const char* filename, const GrepFlags* flags,
                             int many_files, ssize_t len) {
  PrintPrefix(filename, line_no, flags, many_files);
  fputs(line, stdout);
  if (len > 0 && line[len - 1] != '\n') {
    putchar('\n');
  }
}

void PrintMatchedParts(const char* line, int line_no, const char* filename,
                       const GrepFlags* flags, regex_t* regexes,
                       int regex_count, int many_files) {
  for (int i = 0; i < regex_count; i++) {
    const char* search_start = line;
    regmatch_t pmatch[1];

    while (regexec(&regexes[i], search_start, 1, pmatch, 0) == 0) {
      int match_len = (int)(pmatch[0].rm_eo - pmatch[0].rm_so);
      PrintPrefix(filename, line_no, flags, many_files);
      printf("%.*s\n", match_len, search_start + pmatch[0].rm_so);

      search_start += pmatch[0].rm_eo;
      if (pmatch[0].rm_so == pmatch[0].rm_eo) {
        if (*search_start == '\0') break;
        search_start++;
      }
    }
  }
}