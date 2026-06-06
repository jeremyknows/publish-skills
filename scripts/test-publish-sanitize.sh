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

# --- Local-override mechanism test (deny-list.local.tsv) ---
# Proves a fleet-private local rule file is merged on top of the committed deny-list.
# Uses a generic placeholder name + an env-pointed temp file so no real fleet name enters
# this (public) test corpus and the real rules/deny-list.local.tsv is never touched.
LOCAL_TMP=$(mktemp)
printf 'BLOCK\t\\bAcmeSecretAgent\\b\tfleet-name-test\tlocal-override regression rule\n' > "$LOCAL_TMP"
IN_TMP=$(mktemp)
echo "This skill mentions AcmeSecretAgent in passing." > "$IN_TMP"

PUBLISH_SKILLS_DENY_LOCAL="$LOCAL_TMP" bash "$SCAN" "$IN_TMP" > /dev/null 2>&1
if [ "$?" -eq 2 ]; then
  echo "PASS  local-override  (deny-list.local.tsv rule blocks)"
  PASS=$((PASS + 1))
else
  echo "FAIL  local-override  (expected exit 2 with local rule)"
  FAIL=$((FAIL + 1)); FAILED_NAMES+=("local-override")
fi

# Negative: same input with NO local override must not block (proves the rule came from .local).
PUBLISH_SKILLS_DENY_LOCAL=/nonexistent-deny-local bash "$SCAN" "$IN_TMP" > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
  echo "PASS  local-override  (clean when no local rule present)"
  PASS=$((PASS + 1))
else
  echo "FAIL  local-override  (negative case should be clean)"
  FAIL=$((FAIL + 1)); FAILED_NAMES+=("local-override-negative")
fi
rm -f "$LOCAL_TMP" "$IN_TMP"

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
