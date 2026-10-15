#!/bin/bash
# tests/test_grep.sh
# Запуск: ./tests/test_grep.sh [путь_к_s21_grep]

GREP=${1:-./grep/s21_grep}
REF=grep
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

# ---------- функция запуска одного теста ----------
run() {
  local flags="$1"
  shift
  N=$((N+1))

  local ref_out our_out ref_rc our_rc
  # shellcheck disable=SC2086
  ref_out=$($REF $flags "$@" 2>/dev/null)
  ref_rc=$?
  # shellcheck disable=SC2086
  our_out=$("$GREP" $flags "$@" 2>/dev/null)
  our_rc=$?

  echo "================================================="
  echo "Тест #$N: [$flags $*]"
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

run_stdin() {
  local input="$1"
  local flags="$2"
  N=$((N+1))

  local ref_out our_out ref_rc our_rc
  # shellcheck disable=SC2086
  ref_out=$(printf '%b' "$input" | $REF $flags 2>/dev/null)
  ref_rc=$?
  # shellcheck disable=SC2086
  our_out=$(printf '%b' "$input" | "$GREP" $flags 2>/dev/null)
  our_rc=$?

  echo "================================================="
  echo "Тест #$N: stdin [$flags] input='$input'"
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

# ================= базовые (без флагов) =================
run "" hello "$T/a.txt"
run "" foo "$T/a.txt"
run "" zzz "$T/a.txt"              # нет совпадений → rc=1
run "" hello "$T/a.txt" "$T/single.txt"
run "" hello "$T/a.txt" "$T/b.txt" "$T/single.txt"

# ================= -i =================
run "-i" hello "$T/a.txt"
run "-i" HELLO "$T/a.txt"
run "-i" HeLLo "$T/a.txt"

# ================= -v =================
run "-v" hello "$T/a.txt"
run "-v" foo "$T/a.txt"
run "-v" zzz "$T/a.txt"

# ================= -n =================
run "-n" hello "$T/a.txt"
run "-n" foo "$T/nums.txt"
run "-n" hello "$T/a.txt" "$T/single.txt"

# ================= -c =================
run "-c" hello "$T/a.txt"
run "-c" foo "$T/nums.txt"
run "-c" zzz "$T/a.txt"
run "-c" hello "$T/a.txt" "$T/single.txt"

# ================= -l =================
run "-l" hello "$T/a.txt" "$T/single.txt" "$T/empty.txt"
run "-l" zzz "$T/a.txt" "$T/single.txt"
run "-l" hello "$T/multi1.txt" "$T/multi2.txt"

# ================= -e =================
run "-e" hello "$T/a.txt"
run "-e" "^h" "$T/a.txt"
run "-e" "^-" "$T/dash.txt"
run "-e" "o\{2\}" "$T/a.txt"

# ================= регулярные выражения =================
run "" "h.llo" "$T/a.txt"
run "" "^hello" "$T/a.txt"
run "" "foo|bar" "$T/nums.txt"
run "" "[0-9]\+" "$T/nums.txt"
run "" "o\{2\}" "$T/a.txt"

# ================= комбинации =================
run "-i -n" hello "$T/a.txt"
run "-i -v" hello "$T/a.txt"
run "-i -c" HELLO "$T/a.txt"
run "-n -c" hello "$T/a.txt"
run "-l -n" hello "$T/a.txt" "$T/single.txt"
run "-l -c" hello "$T/a.txt" "$T/single.txt"
run "-c -n" hello "$T/a.txt"
run "-iv" hello "$T/a.txt"
run "-in" hello "$T/a.txt"
run "-vc" hello "$T/a.txt"

# ================= склеенные флаги =================
run "-in" hello "$T/a.txt"
run "-ic" hello "$T/a.txt"
run "-vn" hello "$T/a.txt"

# ================= мультифайл =================
run "" line2 "$T/multi1.txt" "$T/multi2.txt"
run "-n" line2 "$T/multi1.txt" "$T/multi2.txt"
run "-c" line2 "$T/multi1.txt" "$T/multi2.txt"
run "-l" line2 "$T/multi1.txt" "$T/multi2.txt"

# ================= краевые случаи =================
run "" zzz "$T/empty_file.txt"     # пустой файл
run "-c" zzz "$T/empty_file.txt"   # счётчик = 0

# ================= stdin (если реализован) =================
# Если у тебя ещё нет stdin — закомментируй эти строки.
run_stdin "hello\nworld\n" "hello"
run_stdin "hello\nworld\n" "-n hello"
run_stdin "hello\nhello\n" "-c hello"
run_stdin "hello\nworld\n" "-v hello"
run_stdin "HELLO\nhello\n" "-i hello"

# ================= итог =================
echo
echo "================================================="
echo "Итог: успешно пройдено $PASS из $N тестов."
echo "Провалено: $FAIL"
echo "================================================="
[ "$FAIL" -eq 0 ]