#!/bin/bash
# tests/test_cat_75.sh
# Запуск: ./tests/test_cat_75.sh [путь_к_s21_cat]

CAT=${1:-./cat/s21_cat}
REF=cat
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

# ---------- функция запуска одного теста ----------
run() {
  local desc="$1"
  local flags="$2"
  shift 2
  N=$((N+1))

  local ref_out our_out
  # shellcheck disable=SC2086
  ref_out=$(cat $flags "$@" 2>&1 | od -An -c)
  # shellcheck disable=SC2086
  our_out=$("$CAT" $flags "$@" 2>&1 | od -An -c)

  echo "================================================="
  echo "Тест #$N: Аргументы [$flags $*]"
  if [ "$ref_out" == "$our_out" ]; then
    echo "[SUCCESS] Результаты полностью идентичны."
    PASS=$((PASS+1))
  else
    echo "[FAIL] Расхождение:"
    echo "--- ref ---"
    cat $flags "$@" 2>&1 | od -An -c
    echo "--- our ---"
    "$CAT" $flags "$@" 2>&1 | od -An -c
    FAIL=$((FAIL+1))
  fi
}

run_stdin() {
  local desc="$1"
  local input="$2"
  local flags="$3"
  N=$((N+1))

  local ref_out our_out
  # shellcheck disable=SC2086
  ref_out=$(printf '%b' "$input" | cat $flags 2>&1 | od -An -c)
  # shellcheck disable=SC2086
  our_out=$(printf '%b' "$input" | "$CAT" $flags 2>&1 | od -An -c)

  echo "================================================="
  echo "Тест #$N: stdin [$flags] input='$input'"
  if [ "$ref_out" == "$our_out" ]; then
    echo "[SUCCESS] Результаты полностью идентичны."
    PASS=$((PASS+1))
  else
    echo "[FAIL] Расхождение:"
    echo "--- ref ---"; printf '%b' "$input" | cat $flags 2>&1 | od -An -c
    echo "--- our ---"; printf '%b' "$input" | "$CAT" $flags 2>&1 | od -An -c
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

# ================= -A (55-60) =================
run "-A tabs"                "-A"  "$T/tabs.txt"
run "-A nonprint"            "-A"  "$T/nonprint.txt"
run "-A blanks"              "-A"  "$T/blanks.txt"
run "-A high"                "-A"  "$T/high.txt"
run "-A normal"              "-A"  "$T/normal.txt"
run "-A mix"                 "-A"  "$T/mix.txt"

# ================= -e -t (61-64) =================
run "-e nonprint"            "-e"  "$T/nonprint.txt"
run "-e tabs"                "-e"  "$T/tabs.txt"
run "-t tabs"                "-t"  "$T/tabs.txt"
run "-t nonprint"            "-t"  "$T/nonprint.txt"

# ================= комбинации (65-72) =================
run "-n -s blanks"           "-n -s"  "$T/blanks.txt"
run "-b -s blanks"           "-b -s"  "$T/blanks.txt"
run "-n -E normal"           "-n -E"  "$T/normal.txt"
run "-b -E blanks"           "-b -E"  "$T/blanks.txt"
run "-A -n tabs"             "-A -n"  "$T/tabs.txt"
run "-A -b blanks"           "-A -b"  "$T/blanks.txt"
run "-A -s blanks"           "-A -s"  "$T/blanks.txt"
run "-benst edge"            "-benst" "$T/edge.txt"

# ================= мультифайл (73-75) =================
run "multi 2 files"          ""      "$T/normal.txt" "$T/abc.txt"
run "multi -n"               "-n"    "$T/abc.txt"    "$T/num.txt"
run "multi -b"               "-b"    "$T/blanks.txt" "$T/normal.txt"

# ================= длинные флаги (76-82) =================
run "--number"                     "--number"               "$T/normal.txt"
run "--number-nonblank"            "--number-nonblank"      "$T/normal.txt"
run "--squeeze-blank"              "--squeeze-blank"        "$T/blanks.txt"
run "--show-ends"                  "--show-ends"            "$T/normal.txt"
run "--show-tabs"                  "--show-tabs"            "$T/tabs.txt"
run "--show-nonprinting"           "--show-nonprinting"     "$T/nonprint.txt"
run "--show-all"                   "--show-all"             "$T/mix.txt"

# ================= комбинации длинных (83-87) =================
run "--number --squeeze-blank"     "--number --squeeze-blank"            "$T/blanks.txt"
run "--number-nonblank --show-ends" "--number-nonblank --show-ends"      "$T/blanks.txt"
run "--show-tabs --show-ends"      "--show-tabs --show-ends"             "$T/tabs.txt"
run "--show-all --number"          "--show-all --number"                 "$T/normal.txt"
run "--show-all --squeeze-blank"   "--show-all --squeeze-blank"          "$T/blanks.txt"

# ================= смешанные (88-91) =================
run "-n --squeeze-blank"           "-n --squeeze-blank"      "$T/blanks.txt"
run "-b --show-ends"               "-b --show-ends"          "$T/blanks.txt"
run "-A --number"                  "-A --number"             "$T/normal.txt"
run "-s --show-all"                "-s --show-all"           "$T/blanks.txt"

# ================= склеенные (92-95) =================
run "-nET"                         "-nET"                   "$T/normal.txt"
run "-vET"                         "-vET"                   "$T/nonprint.txt"
run "-bs"                          "-bs"                    "$T/blanks.txt"
run "-nbs"                         "-nbs"                   "$T/blanks.txt"

# Кое-что пропустила
# ================= мультифайл (104-111) =================
run "multi 3 files"      ""      "$T/abc.txt" "$T/num.txt" "$T/normal.txt"
run "multi -n 3"         "-n"    "$T/abc.txt" "$T/num.txt" "$T/normal.txt"
run "multi -A 2"         "-A"    "$T/tabs.txt" "$T/nonprint.txt"
run "multi -s 2 blanks"  "-s"    "$T/blanks.txt" "$T/end_blanks.txt"
run "multi with empty"   ""      "$T/normal.txt" "$T/empty.txt" "$T/abc.txt"
run "multi -b blanks"    "-b"    "$T/blanks.txt" "$T/start_blank.txt"
run "multi -E"           "-E"    "$T/crlf.txt" "$T/normal.txt"
run "multi -T tabs"      "-T"    "$T/tabs.txt" "$T/mix.txt"

# ================= итог =================
echo
echo "================================================="
echo "Итог: успешно пройдено $PASS из $N тестов."
echo "Провалено: $FAIL"
echo "================================================="
[ "$FAIL" -eq 0 ]