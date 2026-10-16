#!/bin/bash
# tests/test_grep.sh
# Запуск: ./tests/test_grep.sh [путь_к_s21_grep]

GREP=${1:-./grep/s21_grep}
PASS=0
FAIL=0
N=0

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# ---------- генерация тестовых файлов ----------
printf 'hello world\nHELLO\nfoo\nbar hello\n'      > "$T/a.txt"
printf 'one\ntwo\nthree\n'                         > "$T/b.txt"
printf 'hello\n'                                   > "$T/single.txt"
printf 'no match here\n'                           > "$T/empty.txt"
printf 'aaa\nbbb\naaa\nccc\n'                      > "$T/repeat.txt"
printf -- '-dash\nnormal\n'                        > "$T/dash.txt"
printf 'foo123\nbar456\nfoo789\n'                  > "$T/nums.txt"
printf 'x\ny\nz\n'                                 > "$T/small.txt"
printf 'hello world\n'                             > "$T/one_line.txt"
: > "$T/empty_file.txt"
printf 'привет мир\nfoo\n'                         > "$T/utf8.txt"
printf 'line1\nline2\n' > "$T/multi1.txt"
printf 'line2\nline3\n' > "$T/multi2.txt"
printf 'pattern1\npattern2\n' > "$T/patterns.txt"
printf 'hello\nworld\nfoo\n' > "$T/simple.txt"

# ---------- функция запуска одного теста ----------
run() {
  local desc="$1"
  local flags="$2"
  shift 2
  N=$((N+1))

  local ref_out our_out ref_err our_err ref_rc our_rc
  
  # Раздельно захватываем stdout и stderr
  ref_out=$(grep $flags "$@" 2>"$T/ref_err")
  ref_rc=$?
  ref_err=$(cat "$T/ref_err")
  
  our_out=$("$GREP" $flags "$@" 2>"$T/our_err")
  our_rc=$?
  our_err=$(cat "$T/our_err")

  echo "================================================="
  echo "Тест #$N: $desc"
  echo "Аргументы: [$flags $*]"
  
  # Сравниваем stdout и код возврата (stderr может отличаться в формате сообщений)
  if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
    echo "[SUCCESS]"
    PASS=$((PASS+1))
  else
    echo "[FAIL] rc: ref=$ref_rc our=$our_rc"
    echo "--- ref stdout ---"
    printf '%s\n' "$ref_out"
    echo "--- our stdout ---"
    printf '%s\n' "$our_out"
    echo "--- ref stderr ---"
    printf '%s\n' "$ref_err"
    echo "--- our stderr ---"
    printf '%s\n' "$our_err"
    FAIL=$((FAIL+1))
  fi
}

run_stdin() {
  local desc="$1"
  local input="$2"
  local flags="$3"
  N=$((N+1))

  local ref_out our_out ref_rc our_rc
  
  ref_out=$(printf '%b' "$input" | grep $flags 2>/dev/null)
  ref_rc=$?
  
  our_out=$(printf '%b' "$input" | "$GREP" $flags 2>/dev/null)
  our_rc=$?

  echo "================================================="
  echo "Тест #$N: $desc"
  echo "stdin [$flags] input='$input'"
  
  if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
    echo "[SUCCESS]"
    PASS=$((PASS+1))
  else
    echo "[FAIL] rc: ref=$ref_rc our=$our_rc"
    echo "--- ref ---"
    printf '%s\n' "$ref_out"
    echo "--- our ---"
    printf '%s\n' "$our_out"
    FAIL=$((FAIL+1))
  fi
}

# ================= базовые (без флагов) =================
run "basic match"              ""      hello "$T/a.txt"
run "basic no match"           ""      zzz "$T/a.txt"
run "basic multi file"         ""      hello "$T/a.txt" "$T/single.txt"
run "basic 3 files"            ""      hello "$T/a.txt" "$T/b.txt" "$T/single.txt"

# ================= -i =================
run "-i lowercase"             "-i"    hello "$T/a.txt"
run "-i uppercase"             "-i"    HELLO "$T/a.txt"
run "-i mixed case"            "-i"    HeLLo "$T/a.txt"

# ================= -v =================
run "-v invert match"          "-v"    hello "$T/a.txt"
run "-v invert no match"       "-v"    zzz "$T/a.txt"
run "-v invert foo"            "-v"    foo "$T/a.txt"

# ================= -n =================
run "-n line numbers"          "-n"    hello "$T/a.txt"
run "-n with numbers"          "-n"    foo "$T/nums.txt"
run "-n multi file"            "-n"    hello "$T/a.txt" "$T/single.txt"

# ================= -c =================
run "-c count match"           "-c"    hello "$T/a.txt"
run "-c count no match"        "-c"    zzz "$T/a.txt"
run "-c count multi"           "-c"    hello "$T/a.txt" "$T/single.txt"
run "-c count numbers"         "-c"    foo "$T/nums.txt"

# ================= -l =================
run "-l list files"            "-l"    hello "$T/a.txt" "$T/single.txt" "$T/empty.txt"
run "-l no match"              "-l"    zzz "$T/a.txt" "$T/single.txt"
run "-l multi file"            "-l"    hello "$T/multi1.txt" "$T/multi2.txt"

# ================= -e =================
run "-e single pattern"        "-e"    hello "$T/a.txt"
run "-e anchor start"          "-e"    "^h" "$T/a.txt"
run "file with dash (with -e)" "-e" "-dash" "$T/dash.txt"
run "-e quantifier"            "-e"    "o\{2\}" "$T/a.txt"
run "-e multiple patterns"     "-e hello -e foo" "$T/a.txt"

# ================= -h (дополнительный) =================
run "-h hide filename"         "-h"    hello "$T/a.txt" "$T/single.txt"
run "-h single file"           "-h"    hello "$T/a.txt"

# ================= -s (дополнительный) =================
run "-s suppress error"        "-s"    hello "$T/nonexistent.txt"
run "-s with valid file"       "-s"    hello "$T/a.txt"
run "-s mixed files"           "-s"    hello "$T/a.txt" "$T/nonexistent.txt"

# ================= -f (дополнительный) =================
run "-f from file"             "-f"    "$T/patterns.txt" "$T/a.txt"
run "-f empty patterns"        "-f"    "$T/empty.txt" "$T/a.txt"

# ================= -o (дополнительный) =================
run "-o only matching"         "-o"    hello "$T/a.txt"
run "-o with numbers"          "-o"    foo "$T/nums.txt"
run "-o multi pattern"         "-o"    "hello\|foo" "$T/a.txt"

# ================= регулярные выражения =================
run "regex dot"                ""      "h.llo" "$T/a.txt"
run "regex anchor start"       ""      "^hello" "$T/a.txt"
run "regex anchor end"         ""      "world$" "$T/a.txt"
run "regex BRE alternation"    ""      "foo\|bar" "$T/nums.txt"
run "regex character class"    ""      "[0-9]\+" "$T/nums.txt"
run "regex quantifier"         ""      "o\{2\}" "$T/a.txt"
run "regex empty pattern"      ""      "" "$T/a.txt"

# ================= комбинации =================
run "-i -n combination"        "-i -n" hello "$T/a.txt"
run "-i -v combination"        "-i -v" hello "$T/a.txt"
run "-i -c combination"        "-i -c" HELLO "$T/a.txt"
run "-n -c combination"        "-n -c" hello "$T/a.txt"
run "-l -n combination"        "-l -n" hello "$T/a.txt" "$T/single.txt"
run "-l -c combination"        "-l -c" hello "$T/a.txt" "$T/single.txt"
run "-c -n combination"        "-c -n" hello "$T/a.txt"
run "-iv combination"          "-iv"   hello "$T/a.txt"
run "-in combination"          "-in"   hello "$T/a.txt"
run "-vc combination"          "-vc"   hello "$T/a.txt"
run "-o -v combination"        "-o -v" hello "$T/a.txt"
run "-o -v -n combination"     "-o -v -n" hello "$T/a.txt"
run "-c -l combination"        "-c -l" hello "$T/a.txt" "$T/single.txt"
run "-l -v combination"        "-l -v" hello "$T/a.txt" "$T/single.txt"
run "-o -c combination"        "-o -c" hello "$T/a.txt"
run "-e -v combination"        "-e hello -v" "$T/a.txt"
run "-f -v combination"        "-f -v" "$T/patterns.txt" "$T/a.txt"

# ================= комбинации с дополнительными флагами =================
run "-h -n combination"        "-h -n" hello "$T/a.txt" "$T/single.txt"
run "-o -n combination"        "-o -n" hello "$T/a.txt"
run "-o -i combination"        "-o -i" HELLO "$T/a.txt"
run "-f -i combination"        "-f -i" "$T/patterns.txt" "$T/a.txt"
run "-e -f combination"        "-e hello -f" "$T/patterns.txt" "$T/a.txt"
run "-s -c combination"        "-s -c" hello "$T/nonexistent.txt"
run "-h -o combination"        "-h -o" hello "$T/a.txt" "$T/single.txt"

# ================= склеенные флаги =================
run "-in glued"                "-in"   hello "$T/a.txt"
run "-ic glued"                "-ic"   hello "$T/a.txt"
run "-vn glued"                "-vn"   hello "$T/a.txt"
run "-on glued"                "-on"   hello "$T/a.txt"
run "-ho glued"                "-ho"   hello "$T/a.txt" "$T/single.txt"

# ================= мультифайл =================
run "multi basic"              ""      line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -n"                 "-n"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -c"                 "-c"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -l"                 "-l"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -h"                 "-h"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -o"                 "-o"    line2 "$T/multi1.txt" "$T/multi2.txt"

# ================= краевые случаи =================
run "empty file"               ""      zzz "$T/empty_file.txt"
run "-c empty file"            "-c"    zzz "$T/empty_file.txt"
run "utf8 content"             ""      "привет" "$T/utf8.txt"

# ================= коды возврата =================
run "rc=0 match found"         ""      hello "$T/a.txt"
run "rc=1 no match"            ""      zzz "$T/a.txt"
run "rc=2 nonexistent file"    ""      hello "$T/nonexistent.txt"
run "rc=1 with -s"             "-s"    hello "$T/nonexistent.txt"
run "rc=2 invalid regex"       ""      "[" "$T/a.txt"
run "rc=2 invalid regex -s"    "-s"    "[" "$T/a.txt"
run "rc=1 -c no match"         "-c"    zzz "$T/a.txt"
run "rc=0 -l match"            "-l"    hello "$T/a.txt"
run "rc=0 -v invert"           "-v"    hello "$T/a.txt"

# ================= stdin =================
run_stdin "stdin basic"        "hello\nworld\n"         "hello"
run_stdin "stdin -n"           "hello\nworld\n"         "-n hello"
run_stdin "stdin -c"           "hello\nhello\n"         "-c hello"
run_stdin "stdin -v"           "hello\nworld\n"         "-v hello"
run_stdin "stdin -i"           "HELLO\nhello\n"         "-i hello"
run_stdin "stdin -o"           "hello world\n"          "-o hello"

# ================= приоритет флагов =================
run "priority -l over -n"      "-l -n" hello "$T/a.txt" "$T/single.txt"
run "priority -c over -n"      "-c -n" hello "$T/a.txt"

# ================= итог =================
echo
echo "================================================="
echo "Итог: успешно пройдено $PASS из $N тестов."
echo "Провалено: $FAIL"
echo "================================================="
[ "$FAIL" -eq 0 ]