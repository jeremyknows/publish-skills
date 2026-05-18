#!/usr/bin/env bash
# test-publish-sanitize.sh — Regression test for publish-sanitize.sh + post-scan.sh.
#
# For each test-fixtures/input/NN-name.md:
#   - If test-fixtures/expected/NN-name.md exists  → TRANSFORM TEST
#       Run sanitizer; diff against expected; PASS if byte-equal.
#   - Else if sanitizer exits non-zero            → SANITIZE-ERROR TEST
#       PASS — sanitizer correctly rejected malformed input (e.g., nested markers).
#   - Else → SCAN-BLOCK TEST
#       Run scanner; PASS if BLOCK matches found (exit 2).
#
# Exit code: 0 if all PASS, 1 if any FAIL.
#
# Usage: bash test-publish-sanitize.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES="$SCRIPT_DIR/test-fixtures"
SANITIZE="$SCRIPT_DIR/publish-sanitize.sh"
SCAN="$SCRIPT_DIR/post-scan.sh"

PASS=0
FAIL=0
FAILED_NAMES=()

for INPUT in "$FIXTURES/input"/*.md; do
  [ -e "$INPUT" ] || continue
  NAME=$(basename "$INPUT")
  EXPECTED="$FIXTURES/expected/$NAME"

  if [ -f "$EXPECTED" ]; then
    # TRANSFORM TEST: sanitize + diff
    ACTUAL=$(mktemp)
    bash "$SANITIZE" "$INPUT" "$ACTUAL" 2>/dev/null
    if diff -u "$EXPECTED" "$ACTUAL" > /dev/null 2>&1; then
      echo "PASS  transform   $NAME"
      PASS=$((PASS + 1))
    else
      echo "FAIL  transform   $NAME"
      echo "  --- expected vs actual ---"
      diff -u "$EXPECTED" "$ACTUAL" | head -20 | sed 's/^/  /'
      FAIL=$((FAIL + 1))
      FAILED_NAMES+=("$NAME (transform)")
    fi
    rm -f "$ACTUAL"
  else
    # No expected file. Try sanitizer first — if it errors, this is a sanitize-error test.
    SANI_TMP=$(mktemp)
    bash "$SANITIZE" "$INPUT" "$SANI_TMP" > /dev/null 2>&1
    SANI_EXIT=$?
    if [ "$SANI_EXIT" -ne 0 ]; then
      echo "PASS  sanitize-error  $NAME (sanitizer exit $SANI_EXIT — correctly rejected)"
      PASS=$((PASS + 1))
      rm -f "$SANI_TMP"
      continue
    fi

    # SCAN-BLOCK TEST: scanner must report BLOCK (exit 2)
    bash "$SCAN" "$INPUT" > /dev/null 2>&1
    EXIT=$?
    if [ "$EXIT" -eq 2 ]; then
      echo "PASS  scan-block  $NAME (exit 2)"
      PASS=$((PASS + 1))
    else
      echo "FAIL  scan-block  $NAME (expected exit 2, got $EXIT)"
      FAIL=$((FAIL + 1))
      FAILED_NAMES+=("$NAME (scan-block; expected exit 2, got $EXIT)")
    fi
    rm -f "$SANI_TMP"
  fi
done

echo ""
echo "================================================"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed tests:"
  for N in "${FAILED_NAMES[@]}"; do
    echo "  - $N"
  done
  exit 1
fi
exit 0
