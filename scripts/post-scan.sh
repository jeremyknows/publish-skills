#!/usr/bin/env bash
# post-scan.sh — Defense-in-depth scanner for sanitized SKILL.md output.
#
# Reads rules/deny-list.tsv. Each rule is <severity>\t<regex>\t<class>\t<remediation>.
# Severity: BLOCK (publish forbidden) | WARN (manual review)
#
# Output: tab-separated table to stderr; exit code reflects worst severity.
#
# Usage:
#   bash post-scan.sh <file>             # scan one file (DEFAULT: strict — WARN BLOCKs)
#   bash post-scan.sh --allow-warn <file>  # opt-out: WARN matches don't block
#   bash post-scan.sh <file1> <file2> ... # scan multiple
#
# Exit codes:
#   0 = clean (no matches)
#   1 = WARN matches found (only with --allow-warn; manual review needed)
#   2 = BLOCK matches found (publish FORBIDDEN until remediated; default treats WARN as BLOCK)
#   3 = usage / file errors / broken regex in deny-list (DA Hidden Cost #1)
#
# Trust model: DENY-list. Anything matching = caller doesn't publish.
# Strict-by-default per Security Vector 10 — operator should never accidentally ship WARN.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"
DENY="$RULES_DIR/deny-list.tsv"

STRICT=1  # default; flipped to 0 by --allow-warn
if [ "${1:-}" = "--allow-warn" ]; then
  STRICT=0
  shift
elif [ "${1:-}" = "--strict" ]; then
  # Backward-compat: --strict was the prior opt-in flag; now it's the default.
  STRICT=1
  shift
fi

if [ $# -lt 1 ]; then
  echo "usage: $0 [--allow-warn] <file> [<file> ...]" >&2
  exit 3
fi

[ -r "$DENY" ] || { echo "error: deny-list missing: $DENY" >&2; exit 3; }

WORST=0  # 0 clean, 1 warn, 2 block
TOTAL_BLOCK=0
TOTAL_WARN=0

for FILE in "$@"; do
  [ -r "$FILE" ] || { echo "error: cannot read $FILE" >&2; exit 3; }

  # Skip LICENSE.txt entirely — it must contain author identity by design.
  case "$(basename "$FILE")" in
    LICENSE.txt|LICENSE|LICENSE.md)
      echo "skip: $FILE (license file — author identity is intentional)" >&2
      continue
      ;;
  esac

  while IFS=$'\t' read -r severity pattern class hint exclude; do
    # Strip CR from CRLF line endings (DA Bypass #5)
    severity="${severity%$'\r'}"
    pattern="${pattern%$'\r'}"
    class="${class%$'\r'}"
    hint="${hint%$'\r'}"
    exclude="${exclude%$'\r'}"
    # Skip blank lines + comments
    [[ -z "${severity:-}" || "$severity" == \#* ]] && continue
    [ -z "${pattern:-}" ] && continue

    # Run grep; collect line:col matches.
    # Distinguish exit 1 (no match — fine) from exit 2+ (broken regex — fail loud).
    # DA Hidden Cost #1: prior `2>/dev/null || true` swallowed broken-regex errors silently.
    MATCHES=$(grep -nE -- "$pattern" "$FILE" 2>/dev/null)
    GREP_RC=$?
    if [ $GREP_RC -gt 1 ]; then
      echo "error: broken regex in deny-list row [$severity / $class]: $pattern" >&2
      echo "       (grep exited $GREP_RC — fix the rule before continuing)" >&2
      exit 3
    fi
    [ -z "$MATCHES" ] && continue

    # Optional 5th column: exclusion pattern. Filter out lines that match it.
    # Allows context-aware false-positive suppression without lookbehind (macOS grep lacks -P).
    if [ -n "${exclude:-}" ]; then
      MATCHES=$(echo "$MATCHES" | grep -vE -- "$exclude" 2>/dev/null || true)
    fi
    [ -z "$MATCHES" ] && continue

    # Print findings
    while IFS= read -r line; do
      echo -e "[$severity]\t$class\t$FILE\t$line\thint: $hint" >&2
    done <<< "$MATCHES"

    case "$severity" in
      BLOCK)
        TOTAL_BLOCK=$((TOTAL_BLOCK + $(echo "$MATCHES" | wc -l | tr -d ' ')))
        WORST=2
        ;;
      WARN)
        TOTAL_WARN=$((TOTAL_WARN + $(echo "$MATCHES" | wc -l | tr -d ' ')))
        if [ $STRICT -eq 1 ] && [ $WORST -lt 2 ]; then
          WORST=2
          TOTAL_BLOCK=$((TOTAL_BLOCK + $(echo "$MATCHES" | wc -l | tr -d ' ')))
        elif [ $WORST -lt 1 ]; then
          WORST=1
        fi
        ;;
    esac
  done < "$DENY"
done

# Summary to stderr
echo "" >&2
echo "post-scan summary: BLOCK=$TOTAL_BLOCK WARN=$TOTAL_WARN strict=$STRICT" >&2
case $WORST in
  0) echo "✓ clean — safe to publish" >&2 ;;
  1) echo "⚠ warnings only — manual review then publish (you used --allow-warn)" >&2 ;;
  2) echo "✗ BLOCKED — remediate findings above before publishing" >&2 ;;
esac

exit $WORST
