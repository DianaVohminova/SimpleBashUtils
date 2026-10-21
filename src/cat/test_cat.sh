#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CAT="${1:-$SCRIPT_DIR/s21_cat}"

if [ ! -x "$CAT" ]; then
    echo "error: '$CAT' not found or not executable" >&2
    exit 1
fi

PASS=0
FAIL=0
N=0
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

printf 'Hello, World!\nThis is a test file.\n' > "$T/normal.txt"
printf 'line1\n\nline2\n\n\nline3\n'          > "$T/blanks.txt"
printf 'no newline at end'                    > "$T/no_nl.txt"
printf 'a\tb\tc\n'                            > "$T/tabs.txt"
printf 'a\001b\002c\n'                        > "$T/nonprint.txt"
: > "$T/empty.txt"

run() {
    local desc="$1"; shift
    local flags="$1"; shift
    N=$((N+1))

    local ref_out our_out ref_rc our_rc
    ref_out=$(cat $flags "$@" 2>/dev/null); ref_rc=$?
    our_out=$("$CAT" $flags "$@" 2>/dev/null); our_rc=$?

    if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
        printf '[OK]   #%d %s\n' "$N" "$desc"
        PASS=$((PASS+1))
    else
        printf '[FAIL] #%d %s (rc ref=%d our=%d)\n' "$N" "$desc" "$ref_rc" "$our_rc"
        printf '  --- ref ---\n'; printf '%s' "$ref_out" | LC_ALL=C od -An -c
        printf '  --- our ---\n'; printf '%s' "$our_out" | LC_ALL=C od -An -c
        FAIL=$((FAIL+1))
    fi
}

run "no flags normal"   ""     "$T/normal.txt"
run "no flags blanks"   ""     "$T/blanks.txt"
run "no flags no_nl"    ""     "$T/no_nl.txt"
run "no flags empty"    ""     "$T/empty.txt"
run "-n normal"         "-n"   "$T/normal.txt"
run "-b blanks"         "-b"   "$T/blanks.txt"
run "-s blanks"         "-s"   "$T/blanks.txt"
run "-E normal"         "-E"   "$T/normal.txt"
run "-T tabs"           "-T"   "$T/tabs.txt"
run "-v nonprint"       "-v"   "$T/nonprint.txt"
run "-e tabs"           "-e"   "$T/tabs.txt"
run "-t tabs"           "-t"   "$T/tabs.txt"
run "-nET normal"       "-nET" "$T/normal.txt"
run "-bs blanks"        "-bs"  "$T/blanks.txt"
run "--number"          "--number"         "$T/normal.txt"
run "--number-nonblank" "--number-nonblank" "$T/blanks.txt"
run "--squeeze-blank"   "--squeeze-blank"  "$T/blanks.txt"

run_stdin() {
    local desc="$1"; local input="$2"; local flags="$3"
    N=$((N+1))
    local ref_out our_out ref_rc our_rc
    ref_out=$(printf '%b' "$input" | cat $flags 2>/dev/null); ref_rc=$?
    our_out=$(printf '%b' "$input" | "$CAT" $flags 2>/dev/null); our_rc=$?
    if [ "$ref_out" == "$our_out" ] && [ "$ref_rc" == "$our_rc" ]; then
        printf '[OK]   #%d %s\n' "$N" "$desc"; PASS=$((PASS+1))
    else
        printf '[FAIL] #%d %s (rc ref=%d our=%d)\n' "$N" "$desc" "$ref_rc" "$our_rc"
        FAIL=$((FAIL+1))
    fi
}

run_stdin "stdin basic"   'hello\nworld\n'   ''
run_stdin "stdin -n"      'hello\nworld\n'   '-n'
run_stdin "stdin -b"      'hello\n\nworld\n' '-b'
run_stdin "stdin -s"      'a\n\n\n\nb\n'     '-s'
run_stdin "stdin -T"      'a\tb\n'           '-T'
run_stdin "stdin -v"      'a\001b\n'         '-v'

run "nonexistent file"  ""     "$T/nonexistent.txt"

echo "-------------------------------------------"
echo "Пройдено: $PASS из $N. Провалено: $FAIL."
[ "$FAIL" -eq 0 ]