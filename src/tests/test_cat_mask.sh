#!/bin/bash
# tests/test_cat_mask.sh
# Запуск: ./tests/test_cat_mask.sh [путь_к_s21_cat]
#
# Переменные окружения:
#   FAST=1  — комбинировать только -n -b -s (7 сочетаний)
#   FAST=0  — комбинировать все 8 флагов (255 сочетаний)
#   По умолчанию FAST=0.

CAT=${1:-./cat/s21_cat}
FAST=${FAST:-0}

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
    sed -E "s/^(cat|s21_cat|[^:]*cat):/PROG:/"
}

# ---------- run: файл ----------
run() {
  local desc="$1"
  local flags="$2"
  shift 2
  N=$((N+1))

  local ref_out our_out ref_err our_err ref_rc our_rc

  ref_out=$(cat $flags "$@" 2>"$T/ref_err"); ref_rc=$?
  ref_err=$(normalize_err < "$T/ref_err")
  our_out=$("$CAT" $flags "$@" 2>"$T/our_err"); our_rc=$?
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
      echo "--- ref stdout ---"; printf '%s' "$ref_out" | LC_ALL=C od -An -c
      echo "--- our stdout ---"; printf '%s' "$our_out" | LC_ALL=C od -An -c
    fi
    if [ "$ref_err" != "$our_err" ]; then
      echo "--- ref stderr ---"; printf '%s\n' "$ref_err"
      echo "--- our stderr ---"; printf '%s\n' "$our_err"
    fi
    FAIL=$((FAIL+1))
  fi
}

# ---------- run_stdin: stdin ----------
run_stdin() {
  local desc="$1"
  local input="$2"
  local flags="$3"
  N=$((N+1))

  local ref_out our_out ref_err our_err ref_rc our_rc

  ref_out=$(printf '%b' "$input" | cat $flags 2>"$T/ref_err"); ref_rc=$?
  ref_err=$(normalize_err < "$T/ref_err")
  our_out=$(printf '%b' "$input" | "$CAT" $flags 2>"$T/our_err"); our_rc=$?
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
      echo "--- ref stdout ---"; printf '%s' "$ref_out" | LC_ALL=C od -An -c
      echo "--- our stdout ---"; printf '%s' "$our_out" | LC_ALL=C od -An -c
    fi
    if [ "$ref_err" != "$our_err" ]; then
      echo "--- ref stderr ---"; printf '%s\n' "$ref_err"
      echo "--- our stderr ---"; printf '%s\n' "$our_err"
    fi
    FAIL=$((FAIL+1))
  fi
}

# ==========================================================================
# Набор атомарных флагов для побитового перебора
# ==========================================================================
if [ "$FAST" = "1" ]; then
    FLAGS=(-n -b -s)                 # 2^3 - 1 = 7 комбинаций
    MODE_DESC="FAST: {-n -b -s}"
else
    FLAGS=(-n -b -s -E -T -e -t -v)  # 2^8 - 1 = 255 комбинаций
    MODE_DESC="FULL: {-n -b -s -E -T -e -t -v}"
fi

NFLAGS=${#FLAGS[@]}
TOTAL=$(( (1 << NFLAGS) - 1 ))

echo "#################################################"
echo "# Побитовый перебор комбинаций флагов"
echo "# Режим: $MODE_DESC"
echo "# Флагов: $NFLAGS, комбинаций: $TOTAL"
echo "#################################################"

# Для каждой битовой маски от 1 до 2^N - 1:
#   бит i установлен => флаг FLAGS[i] включён в комбинацию.
for ((mask=1; mask <= TOTAL; mask++)); do
    combo=()
    for ((i=0; i<NFLAGS; i++)); do
        if (( mask & (1 << i) )); then
            combo+=("${FLAGS[i]}")
        fi
    done
    flags_str="${combo[*]}"

    # 1) файл с пустыми строками и табами
    run "mask($mask): $flags_str" "$flags_str" "$T/blanks.txt"

    # 2) stdin: пустая строка + таб + непечатаемый символ
    run_stdin "mask($mask) stdin: $flags_str" "a\n\nb\tc\001\n" "$flags_str"

    # 3) файл без завершающего перевода строки
    run "mask($mask) no_nl: $flags_str" "$flags_str" "$T/no_nl.txt"
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