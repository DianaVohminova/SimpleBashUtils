#!/bin/bash
# tests/test_cat.sh
# Запуск: ./tests/test_cat.sh [путь_к_s21_cat]

CAT=${1:-./cat/s21_cat}
PASS=0
FAIL=0
N=0

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# ---------- генерация тестовых файлов ----------
printf 'Hello, World!\nThis is a test file.\nMultiple lines here.\n' > "$T/normal.txt"
printf 'line1\n\nline2\n\n\nline3\n'                                 > "$T/blanks.txt"
printf '\n\n\n\n\n'                                                  > "$T/only_blanks.txt"
printf 'no newline at end'                                           > "$T/no_nl.txt"
printf 'x'                                                           > "$T/one_char.txt"
: > "$T/empty.txt"
printf 'col1\tcol2\tcol3\nval1\tval2\tval3\n'                        > "$T/tabs.txt"
printf 'a\001\002\003b\004\005\006c\177d\n'                          > "$T/nonprint.txt"
printf 'x\177y\n'                                                    > "$T/del.txt"
printf 'hi\200\201\377there\n'                                       > "$T/high.txt"
printf 'mix\there\001and\002there\nnext\tline\n'                     > "$T/mix.txt"
printf '\nfirst\nsecond\n'                                           > "$T/start_blank.txt"
printf 'last\n\n\n\n'                                                > "$T/end_blanks.txt"
printf 'line1\r\nline2\r\n'                                          > "$T/crlf.txt"
printf 'a\rb\rc\n'                                                   > "$T/cr_only.txt"
printf 'short\na_very_long_line_that_goes_on_and_on_and_on\nx\n'     > "$T/mixed_len.txt"
printf 'Привет, мир!\n日本語\n'                                       > "$T/utf8.txt"
printf '12345\n!@#$%%^&*()\n[]{}<>\n'                                > "$T/punct.txt"
printf '\n'                                                          > "$T/one_nl.txt"
printf 'a\tb\tc\n'                                                   > "$T/edge.txt"
printf 'abc\ndef\n'                                                  > "$T/abc.txt"
printf '1\n2\n3\n'                                                   > "$T/num.txt"

# Нормализация имени программы в stderr (cat: ... -> PROG: ...)
normalize_err() {
    sed -E "s/^(cat|s21_cat|.*cat):/PROG:/"
}

# ---------- функция запуска одного теста ----------
run() {
  local desc="$1"
  local flags="$2"
  shift 2
  N=$((N+1))

  local ref_out our_out ref_err our_err ref_rc our_rc

  ref_out=$(cat $flags "$@" 2>"$T/ref_err")
  ref_rc=$?
  ref_err=$(normalize_err < "$T/ref_err")

  our_out=$("$CAT" $flags "$@" 2>"$T/our_err")
  our_rc=$?
  our_err=$(normalize_err < "$T/our_err")

  echo "================================================="
  echo "Тест #$N: $desc"
  echo "Аргументы: [$flags $*]"

  if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ] && [ "$ref_err" == "$our_err" ]; then
    echo "[SUCCESS]"
    PASS=$((PASS+1))
  else
    echo "[FAIL] rc: ref=$ref_rc our=$our_rc"
    if [ "$ref_out" != "$our_out" ]; then
      echo "--- ref stdout ---"
      printf '%s' "$ref_out" | LC_ALL=C od -An -c
      echo "--- our stdout ---"
      printf '%s' "$our_out" | LC_ALL=C od -An -c
    fi
    if [ "$ref_err" != "$our_err" ]; then
      echo "--- ref stderr ---"; printf '%s\n' "$ref_err"
      echo "--- our stderr ---"; printf '%s\n' "$our_err"
    fi
    FAIL=$((FAIL+1))
  fi
}

run_stdin() {
  local desc="$1"
  local input="$2"
  local flags="$3"
  N=$((N+1))

  local ref_out our_out ref_err our_err ref_rc our_rc

  ref_out=$(printf '%b' "$input" | cat $flags 2>"$T/ref_err")
  ref_rc=$?
  ref_err=$(normalize_err < "$T/ref_err")

  our_out=$(printf '%b' "$input" | "$CAT" $flags 2>"$T/our_err")
  our_rc=$?
  our_err=$(normalize_err < "$T/our_err")

  echo "================================================="
  echo "Тест #$N: $desc"
  echo "stdin [$flags] input='$input'"

  if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ] && [ "$ref_err" == "$our_err" ]; then
    echo "[SUCCESS]"
    PASS=$((PASS+1))
  else
    echo "[FAIL] rc: ref=$ref_rc our=$our_rc"
    if [ "$ref_out" != "$our_out" ]; then
      echo "--- ref stdout ---"
      printf '%s' "$ref_out" | LC_ALL=C od -An -c
      echo "--- our stdout ---"
      printf '%s' "$our_out" | LC_ALL=C od -An -c
    fi
    if [ "$ref_err" != "$our_err" ]; then
      echo "--- ref stderr ---"; printf '%s\n' "$ref_err"
      echo "--- our stderr ---"; printf '%s\n' "$our_err"
    fi
    FAIL=$((FAIL+1))
  fi
}

# ================= БАЗОВЫЕ (1-10) =================
run "no flags normal"        ""    "$T/normal.txt"
run "no flags blanks"        ""    "$T/blanks.txt"
run "no flags empty"         ""    "$T/empty.txt"
run "no flags no_nl"         ""    "$T/no_nl.txt"
run "no flags tabs"          ""    "$T/tabs.txt"
run "no flags nonprint"      ""    "$T/nonprint.txt"
run "no flags crlf"          ""    "$T/crlf.txt"
run "no flags utf8"          ""    "$T/utf8.txt"
run "no flags punct"         ""    "$T/punct.txt"
run "no flags one_char"      ""    "$T/one_char.txt"

# ================= -n (11-20) =================
run "-n normal"              "-n"  "$T/normal.txt"
run "-n blanks"              "-n"  "$T/blanks.txt"
run "-n empty"               "-n"  "$T/empty.txt"
run "-n no_nl"               "-n"  "$T/no_nl.txt"
run "-n tabs"                "-n"  "$T/tabs.txt"
run "-n one_nl"              "-n"  "$T/one_nl.txt"
run "-n start_blank"         "-n"  "$T/start_blank.txt"
run "-n end_blanks"          "-n"  "$T/end_blanks.txt"
run "-n nonprint"            "-n"  "$T/nonprint.txt"
run "-n high"                "-n"  "$T/high.txt"

# ================= -b (21-28) =================
run "-b normal"              "-b"  "$T/normal.txt"
run "-b blanks"              "-b"  "$T/blanks.txt"
run "-b only_blanks"         "-b"  "$T/only_blanks.txt"
run "-b no_nl"               "-b"  "$T/no_nl.txt"
run "-b empty"               "-b"  "$T/empty.txt"
run "-b start_blank"         "-b"  "$T/start_blank.txt"
run "-b end_blanks"          "-b"  "$T/end_blanks.txt"
run "-b tabs"                "-b"  "$T/tabs.txt"

# ================= -s (29-36) =================
run "-s blanks"              "-s"  "$T/blanks.txt"
run "-s only_blanks"         "-s"  "$T/only_blanks.txt"
run "-s start_blank"         "-s"  "$T/start_blank.txt"
run "-s end_blanks"          "-s"  "$T/end_blanks.txt"
run "-s normal"              "-s"  "$T/normal.txt"
run "-s empty"               "-s"  "$T/empty.txt"
run "-s one_nl"              "-s"  "$T/one_nl.txt"
run "-s nonprint"            "-s"  "$T/nonprint.txt"

# ================= -E (37-42) =================
run "-E normal"              "-E"  "$T/normal.txt"
run "-E no_nl"               "-E"  "$T/no_nl.txt"
run "-E empty"               "-E"  "$T/empty.txt"
run "-E blanks"              "-E"  "$T/blanks.txt"
run "-E crlf"                "-E"  "$T/crlf.txt"
run "-E nonprint"            "-E"  "$T/nonprint.txt"

# ================= -T (43-48) =================
run "-T tabs"                "-T"  "$T/tabs.txt"
run "-T mix"                 "-T"  "$T/mix.txt"
run "-T no_nl"               "-T"  "$T/no_nl.txt"
run "-T normal"              "-T"  "$T/normal.txt"
run "-T edge"                "-T"  "$T/edge.txt"
run "-T crlf"                "-T"  "$T/crlf.txt"

# ================= -v (49-54) =================
run "-v nonprint"            "-v"  "$T/nonprint.txt"
run "-v del"                 "-v"  "$T/del.txt"
run "-v high"                "-v"  "$T/high.txt"
run "-v normal"              "-v"  "$T/normal.txt"
run "-v mix"                 "-v"  "$T/mix.txt"
run "-v tabs"                "-v"  "$T/tabs.txt"

# ================= -e -t (55-58) =================
run "-e nonprint"            "-e"  "$T/nonprint.txt"
run "-e tabs"                "-e"  "$T/tabs.txt"
run "-t tabs"                "-t"  "$T/tabs.txt"
run "-t nonprint"            "-t"  "$T/nonprint.txt"

# ================= комбинации (59-66) =================
run "-n -s blanks"           "-n -s"  "$T/blanks.txt"
run "-b -s blanks"           "-b -s"  "$T/blanks.txt"
run "-n -E normal"           "-n -E"  "$T/normal.txt"
run "-b -E blanks"           "-b -E"  "$T/blanks.txt"
run "-n -T tabs"             "-n -T"  "$T/tabs.txt"
run "-b -T blanks"           "-b -T"  "$T/blanks.txt"
run "-s -T blanks"           "-s -T"  "$T/blanks.txt"
run "-benst edge"            "-benst" "$T/edge.txt"

# ================= мультифайл (67-74) =================
run "multi 2 files"          ""      "$T/normal.txt" "$T/abc.txt"
run "multi -n"               "-n"    "$T/abc.txt"    "$T/num.txt"
run "multi -b"               "-b"    "$T/blanks.txt" "$T/normal.txt"
run "multi 3 files"          ""      "$T/abc.txt" "$T/num.txt" "$T/normal.txt"
run "multi -n 3"             "-n"    "$T/abc.txt" "$T/num.txt" "$T/normal.txt"
run "multi -T 2"             "-T"    "$T/tabs.txt" "$T/nonprint.txt"
run "multi -s 2 blanks"      "-s"    "$T/blanks.txt" "$T/end_blanks.txt"
run "multi with empty"       ""      "$T/normal.txt" "$T/empty.txt" "$T/abc.txt"

# ================= длинные флаги (75-77) — строго три =================
run "--number"                     "--number"               "$T/normal.txt"
run "--number-nonblank"            "--number-nonblank"      "$T/normal.txt"
run "--squeeze-blank"              "--squeeze-blank"        "$T/blanks.txt"

# ================= комбинации длинных (78-80) =================
run "--number --squeeze-blank"     "--number --squeeze-blank"            "$T/blanks.txt"
run "--number-nonblank --squeeze-blank" "--number-nonblank --squeeze-blank" "$T/blanks.txt"
run "--number --number-nonblank"   "--number --number-nonblank"          "$T/blanks.txt"

# ================= смешанные короткие + длинные (81-83) =================
run "-n --squeeze-blank"           "-n --squeeze-blank"      "$T/blanks.txt"
run "-b --squeeze-blank"           "-b --squeeze-blank"      "$T/blanks.txt"
run "-s --number"                  "-s --number"             "$T/blanks.txt"

# ================= склеенные (84-87) =================
run "-nET"                         "-nET"                   "$T/normal.txt"
run "-vET"                         "-vET"                   "$T/nonprint.txt"
run "-bs"                          "-bs"                    "$T/blanks.txt"
run "-nbs"                         "-nbs"                   "$T/blanks.txt"

# ==========================================================================
# ================= БЕЗ ФАЙЛА (stdin) ======================================
# ==========================================================================

# ---------- без флагов ----------
run_stdin "stdin basic (no flags)"        "hello\nworld\n"          ""
run_stdin "stdin empty"                   ""                        ""
run_stdin "stdin no newline"              "abc"                     ""
run_stdin "stdin tabs"                    "a\tb\tc\n"               ""
run_stdin "stdin nonprint"                "a\001b\002c\n"           ""
run_stdin "stdin crlf"                    "line1\r\nline2\r\n"      ""

# ---------- по одному флагу ----------
run_stdin "stdin -n"                      "hello\nworld\n"          "-n"
run_stdin "stdin -b"                      "hello\n\nworld\n"        "-b"
run_stdin "stdin -s"                      "hello\n\n\nworld\n"      "-s"
run_stdin "stdin -E"                      "hello\nworld\n"          "-E"
run_stdin "stdin -T"                      "a\tb\n"                  "-T"
run_stdin "stdin -v"                      "a\001b\n"                "-v"
run_stdin "stdin -e"                      "a\tb\n"                  "-e"
run_stdin "stdin -t"                      "a\tb\n"                  "-t"

# ---------- по одному длинному флагу (строго три) ----------
run_stdin "stdin --number"                "hello\nworld\n"          "--number"
run_stdin "stdin --number-nonblank"       "hello\n\nworld\n"        "--number-nonblank"
run_stdin "stdin --squeeze-blank"         "hello\n\n\nworld\n"      "--squeeze-blank"

# ---------- комбинации ----------
run_stdin "stdin -n -E"                   "hello\nworld\n"          "-n -E"
run_stdin "stdin -b -s"                   "a\n\n\n\nb\n"            "-b -s"
run_stdin "stdin -n -s"                   "a\n\n\n\nb\n"            "-n -s"
run_stdin "stdin -n -T"                   "a\tb\n"                  "-n -T"
run_stdin "stdin -b -T"                   "a\n\nb\tc\n"             "-b -T"
run_stdin "stdin -s -T"                   "a\n\n\n\nb\tc\n"         "-s -T"
run_stdin "stdin -vET"                    "a\tb\001\n"              "-vET"
run_stdin "stdin -benst"                  "a\n\nb\tc\n"             "-benst"
run_stdin "stdin -nbs"                    "a\n\n\n\nb\n"            "-nbs"

# ---------- смешанные короткие + длинные ----------
run_stdin "stdin -n --squeeze-blank"      "a\n\n\n\nb\n"            "-n --squeeze-blank"
run_stdin "stdin -b --squeeze-blank"      "a\n\n\n\nb\n"            "-b --squeeze-blank"
run_stdin "stdin -s --number"             "a\n\n\n\nb\n"            "-s --number"
run_stdin "stdin --number --squeeze-blank" "a\n\n\n\nb\n"           "--number --squeeze-blank"

# ================= ошибки (stderr + rc) =================
run "nonexistent file"             ""      "$T/nonexistent.txt"
run "mixed valid and invalid"      ""      "$T/normal.txt" "$T/nonexistent.txt"
run "nonexistent + flags"          "-nE"   "$T/nonexistent.txt"

# ================= итог =================
echo
echo "================================================="
echo "Итог: успешно пройдено $PASS из $N тестов."
echo "Провалено: $FAIL"
echo "================================================="
[ "$FAIL" -eq 0 ]