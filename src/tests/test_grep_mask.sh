#!/bin/bash
# tests/test_grep_mask.sh
# Запуск: ./tests/test_grep_mask.sh [путь_к_s21_grep]
#
# Переменные окружения:
#   FAST=1 — маска только по -i -v -c -n (15 комбинаций, быстро)
#   FAST=0 — маска по -i -v -c -l -n -h -o (127 комбинаций, полно)
#   По умолчанию FAST=0.
#
# Флаги -e, -f, -s тестируются точечно (требуют аргумента/контекста).

GREP=${1:-./grep/s21_grep}
FAST=${FAST:-0}

PASS=0
FAIL=0
N=0

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# ---------- генерация тестовых файлов ----------
printf 'hello world\nHELLO\nfoo\nbar hello\n'      > "$T/a.txt"
printf 'one\ntwo\nthree\n'                         > "$T/b.txt"
printf 'hello\n'                                   > "$T/single.txt"
printf 'no match here\n'                           > "$T/nomatch.txt"
printf 'aaa\nbbb\naaa\nccc\n'                      > "$T/repeat.txt"
printf -- '-dash\nnormal\n'                        > "$T/dash.txt"
printf 'foo123\nbar456\nfoo789\n'                  > "$T/nums.txt"
printf 'x\ny\nz\n'                                 > "$T/small.txt"
: > "$T/empty_file.txt"
printf 'line1\nline2\n' > "$T/multi1.txt"
printf 'line2\nline3\n' > "$T/multi2.txt"
printf 'pattern1\npattern2\n' > "$T/patterns.txt"

run() {
  local desc="$1"
  local flags="$2"
  shift 2
  N=$((N+1))

  local ref_out our_out ref_err our_err ref_rc our_rc
  ref_out=$(grep $flags "$@" 2>"$T/ref_err"); ref_rc=$?
  ref_err=$(cat "$T/ref_err")
  our_out=$("$GREP" $flags "$@" 2>"$T/our_err"); our_rc=$?
  our_err=$(cat "$T/our_err")

  echo "================================================="
  echo "Тест #$N: $desc"
  echo "Аргументы: [$flags $*]"

  if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
    echo "[SUCCESS]"
    PASS=$((PASS+1))
  else
    echo "[FAIL] rc: ref=$ref_rc our=$our_rc"
    echo "--- ref stdout ---"; printf '%s\n' "$ref_out"
    echo "--- our stdout ---"; printf '%s\n' "$our_out"
    echo "--- ref stderr ---"; printf '%s\n' "$ref_err"
    echo "--- our stderr ---"; printf '%s\n' "$our_err"
    FAIL=$((FAIL+1))
  fi
}

run_stdin() {
  local desc="$1"
  local input="$2"
  local flags="$3"
  N=$((N+1))

  local ref_out our_out ref_rc our_rc
  ref_out=$(printf '%b' "$input" | grep $flags 2>/dev/null); ref_rc=$?
  our_out=$(printf '%b' "$input" | "$GREP" $flags 2>/dev/null); our_rc=$?

  echo "================================================="
  echo "Тест #$N: $desc"
  echo "stdin [$flags] input='$input'"

  if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
    echo "[SUCCESS]"
    PASS=$((PASS+1))
  else
    echo "[FAIL] rc: ref=$ref_rc our=$our_rc"
    echo "--- ref ---"; printf '%s\n' "$ref_out"
    echo "--- our ---"; printf '%s\n' "$our_out"
    FAIL=$((FAIL+1))
  fi
}

# ==========================================================================
# ЧАСТЬ 1. Точечные тесты (флаги с аргументами и особый контекст)
# ==========================================================================

# ---------- базовые (без флагов) ----------
run "basic match"              ""      hello "$T/a.txt"
run "basic no match"           ""      zzz "$T/a.txt"
run "basic multi file"         ""      hello "$T/a.txt" "$T/single.txt"
run "basic 3 files"            ""      hello "$T/a.txt" "$T/b.txt" "$T/single.txt"

# ---------- -e ----------
run "-e single pattern"        "-e"    hello "$T/a.txt"
run "-e anchor start"          "-e"    "^h" "$T/a.txt"
run "-e dash pattern"          "-e"    "-dash" "$T/dash.txt"
run "-e quantifier"            "-e"    "o\{2\}" "$T/a.txt"
run "-e multiple patterns"     "-e hello -e foo" "$T/a.txt"
run "-e empty pattern"         "-e"    "" "$T/a.txt"

# ---------- -f ----------
run "-f from file"             "-f"    "$T/patterns.txt" "$T/a.txt"
run "-f empty file"            "-f"    "$T/empty_file.txt" "$T/a.txt"
run "-f nonexistent"           "-f"    "$T/nonexistent.txt" "$T/a.txt"

# ---------- -s ----------
run "-s suppress error"        "-s"    hello "$T/nonexistent.txt"
run "-s with valid file"       "-s"    hello "$T/a.txt"
run "-s mixed files"           "-s"    hello "$T/a.txt" "$T/nonexistent.txt"
run "-s rc=2 nonexistent"      "-s"    hello "$T/nonexistent.txt"

# ---------- -e + -f ----------
run "-e -f combination"        "-e hello -f" "$T/patterns.txt" "$T/a.txt"

# ---------- регулярные выражения ----------
run "regex dot"                ""      "h.llo" "$T/a.txt"
run "regex anchor start"       ""      "^hello" "$T/a.txt"
run "regex anchor end"         ""      "world$" "$T/a.txt"
run "regex BRE alternation"    ""      "foo\|bar" "$T/nums.txt"
run "regex character class"    ""      "[0-9]\+" "$T/nums.txt"
run "regex empty pattern"      ""      "" "$T/a.txt"

# ---------- краевые случаи ----------
run "empty file"               ""      zzz "$T/empty_file.txt"
run "-c empty file"            "-c"    zzz "$T/empty_file.txt"
run "utf8 content"             ""      "привет" "$T/a.txt"  # не найдёт, но проверит кодировку

# ---------- коды возврата ----------
run "rc=0 match found"         ""      hello "$T/a.txt"
run "rc=1 no match"            ""      zzz "$T/a.txt"
run "rc=2 nonexistent file"    ""      hello "$T/nonexistent.txt"
run "rc=2 invalid regex"       ""      "[" "$T/a.txt"
run "rc=2 invalid regex -s"    "-s"    "[" "$T/a.txt"

# ---------- мультифайл ----------
run "multi basic"              ""      line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -n"                 "-n"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -c"                 "-c"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -l"                 "-l"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -h"                 "-h"    line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -o"                 "-o"    line2 "$T/multi1.txt" "$T/multi2.txt"

# ---------- stdin ----------
run_stdin "stdin basic"        "hello\nworld\n"         "hello"
run_stdin "stdin -n"           "hello\nworld\n"         "-n hello"
run_stdin "stdin -c"           "hello\nhello\n"         "-c hello"
run_stdin "stdin -v"           "hello\nworld\n"         "-v hello"
run_stdin "stdin -i"           "HELLO\nhello\n"         "-i hello"
run_stdin "stdin -o"           "hello world\n"          "-o hello"

# ==========================================================================
# ЧАСТЬ 2. Битовая маска по простым булевым флагам
# ==========================================================================
if [ "$FAST" = "1" ]; then
    FLAGS=(-i -v -c -n)                     # 15 комбинаций
    MODE_DESC="FAST: {-i -v -c -n}"
else
    FLAGS=(-i -v -c -l -n -h -o)            # 127 комбинаций
    MODE_DESC="FULL: {-i -v -c -l -n -h -o}"
fi

NFLAGS=${#FLAGS[@]}
TOTAL=$(( (1 << NFLAGS) - 1 ))

echo "#################################################"
echo "# Побитовый перебор комбинаций"
echo "# Режим: $MODE_DESC"
echo "# Флагов: $NFLAGS, комбинаций: $TOTAL"
echo "#################################################"

for ((mask=1; mask <= TOTAL; mask++)); do
    combo=()
    for ((i=0; i<NFLAGS; i++)); do
        if (( mask & (1 << i) )); then
            combo+=("${FLAGS[i]}")
        fi
    done
    flags_str="${combo[*]}"

    # 1) один файл, паттерн hello
    run "mask($mask): $flags_str" "$flags_str" hello "$T/a.txt"

    # 2) два файла, паттерн hello (проверяет -h, -l, -c на мультифайле)
    run "mask($mask) multi: $flags_str" "$flags_str" hello "$T/a.txt" "$T/single.txt"
done

# ==========================================================================
# Итог
# ==========================================================================
echo
echo "================================================="
echo "Режим: $MODE_DESC"
echo "Итог: PASS=$PASS  FAIL=$FAIL  (всего $N тестов)"
echo "================================================="
[ "$FAIL" -eq 0 ]