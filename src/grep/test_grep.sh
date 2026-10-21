#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
GREP="${1:-$SCRIPT_DIR/s21_grep}"

if [ ! -x "$GREP" ]; then
    echo "error: '$GREP' not found or not executable" >&2
    exit 1
fi

PASS=0
FAIL=0
N=0
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

printf 'hello world\nHELLO\nfoo\nbar hello\n' > "$T/a.txt"
printf 'one\ntwo\nthree\n'                    > "$T/b.txt"
printf 'hello\n'                              > "$T/single.txt"
printf 'aaa\nbbb\naaa\nccc\n'                 > "$T/repeat.txt"
printf 'foo123\nbar456\nfoo789\n'             > "$T/nums.txt"
printf 'line1\nline2\n'                       > "$T/multi1.txt"
printf 'line2\nline3\n'                       > "$T/multi2.txt"
printf 'pattern1\npattern2\n'                 > "$T/patterns.txt"
: > "$T/empty_file.txt"

run() {
    local desc="$1"; shift
    local flags="$1"; shift
    N=$((N+1))

    local ref_out our_out ref_rc our_rc
    ref_out=$(grep $flags "$@" 2>/dev/null); ref_rc=$?
    our_out=$("$GREP" $flags "$@" 2>/dev/null); our_rc=$?

    if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
        printf '[OK]   #%d %s\n' "$N" "$desc"
        PASS=$((PASS+1))
    else
        printf '[FAIL] #%d %s (rc ref=%d our=%d)\n' "$N" "$desc" "$ref_rc" "$our_rc"
        printf '  --- ref ---\n'; printf '%s\n' "$ref_out"
        printf '  --- our ---\n'; printf '%s\n' "$our_out"
        FAIL=$((FAIL+1))
    fi
}

run_stdin() {
    local desc="$1"; local input="$2"; local flags="$3"
    N=$((N+1))
    local ref_out our_out ref_rc our_rc
    ref_out=$(printf '%b' "$input" | grep $flags 2>/dev/null); ref_rc=$?
    our_out=$(printf '%b' "$input" | "$GREP" $flags 2>/dev/null); our_rc=$?
    if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
        printf '[OK]   #%d %s\n' "$N" "$desc"; PASS=$((PASS+1))
    else
        printf '[FAIL] #%d %s (rc ref=%d our=%d)\n' "$N" "$desc" "$ref_rc" "$our_rc"
        FAIL=$((FAIL+1))
    fi
}

# ================= базовые =================
run "basic match"        ""   hello "$T/a.txt"
run "basic no match"     ""   zzz   "$T/a.txt"
run "basic multi file"   ""   hello "$T/a.txt" "$T/single.txt"

# ================= по одному флагу =================
run "-i case-insensitive" "-i" hello "$T/a.txt"
run "-v invert"           "-v" hello "$T/a.txt"
run "-n line numbers"     "-n" hello "$T/a.txt"
run "-c count"            "-c" hello "$T/a.txt"
run "-l list files"       "-l" hello "$T/a.txt" "$T/single.txt"
run "-o only matching"    "-o" hello "$T/a.txt"
run "-h hide filename"    "-h" hello "$T/a.txt" "$T/single.txt"
run "-s suppress error"   "-s" hello "$T/nonexistent.txt"

# ================= -e / -f =================
run "-e single"           "-e" hello      "$T/a.txt"
run "-e multiple"         "-e hello -e foo" "$T/a.txt"
run "-f patterns file"    "-f" "$T/patterns.txt" "$T/a.txt"

# ================= регулярные выражения =================
run "regex dot"           ""   "h.llo"   "$T/a.txt"
run "regex anchor start"  ""   "^hello"  "$T/a.txt"
run "regex anchor end"    ""   "world$"  "$T/a.txt"
run "regex BRE alternation" "" "foo\|bar" "$T/nums.txt"
run "regex class"         ""   "[0-9]\+" "$T/nums.txt"

# ================= комбинации =================
run "-i -n"               "-i -n" hello "$T/a.txt"
run "-i -v"               "-i -v" hello "$T/a.txt"
run "-n -c"               "-n -c" hello "$T/a.txt"
run "-l -n"               "-l -n" hello "$T/a.txt" "$T/single.txt"
run "-c -n"               "-c -n" hello "$T/a.txt"
run "-o -n"               "-o -n" hello "$T/a.txt"
run "-in glued"           "-in"   hello "$T/a.txt"
run "-ic glued"           "-ic"   hello "$T/a.txt"

# ================= мультифайл =================
run "multi basic"         ""   line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -n"            "-n" line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -c"            "-c" line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -l"            "-l" line2 "$T/multi1.txt" "$T/multi2.txt"
run "multi -h"            "-h" line2 "$T/multi1.txt" "$T/multi2.txt"

# ================= коды возврата =================
run "rc=0 match"          ""   hello "$T/a.txt"
run "rc=1 no match"       ""   zzz   "$T/a.txt"
run "rc=2 nonexistent"    ""   hello "$T/nonexistent.txt"
run "rc=1 -s suppress"    "-s" hello "$T/nonexistent.txt"
run "rc=2 invalid regex"  ""   "["   "$T/a.txt"

# ================= краевые случаи =================
run "empty file"          ""   zzz   "$T/empty_file.txt"
run "-c empty file"       "-c" zzz   "$T/empty_file.txt"

# ================= stdin =================
run_stdin "stdin basic"   'hello\nworld\n'  'hello'
run_stdin "stdin -n"      'hello\nworld\n'  '-n hello'
run_stdin "stdin -c"      'hello\nhello\n'  '-c hello'
run_stdin "stdin -v"      'hello\nworld\n'  '-v hello'
run_stdin "stdin -i"      'HELLO\nhello\n'  '-i hello'
run_stdin "stdin -o"      'hello world\n'   '-o hello'

echo "-------------------------------------------"
echo "Пройдено: $PASS из $N. Провалено: $FAIL."
[ "$FAIL" -eq 0 ]