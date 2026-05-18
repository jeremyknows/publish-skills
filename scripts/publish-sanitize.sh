#!/usr/bin/env bash
# publish-sanitize.sh — Transform a fleet-internal SKILL.md into a publishable form.
#
# Pipeline:
#   1. Strip <!-- <fleet>-private:start -->...<!-- /<fleet>-private:end --> blocks
#      (author opt-in marking for fleet-only context)
#   2. Apply path/token transforms from rules/transforms.tsv
#   3. (Caller invokes post-scan.sh separately to BLOCK on residual leaks)
#
# Usage:
#   bash publish-sanitize.sh <input-file>           # writes to stdout
#   bash publish-sanitize.sh <input-file> <output>  # writes to file
#
# Configuration:
#   FLEET_MARKER — marker prefix (default: atlas-private)
#   Override: FLEET_MARKER=myfleet-private bash publish-sanitize.sh ...
#   Or edit the default below to match your fleet's naming convention.
#
# Exit codes:
#   0 = sanitization complete (caller MUST run post-scan.sh before publishing)
#   1 = input file missing or unreadable
#   2 = unmatched marker (start without end or vice versa)
#
# Trust model: this script transforms KNOWN patterns. It does NOT detect
# unknown leak classes — that is post-scan.sh's job. Always pipeline both.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"
TRANSFORMS="$RULES_DIR/transforms.tsv"

# Fleet marker prefix — change to match your naming convention, or override via env.
FLEET_MARKER="${FLEET_MARKER:-atlas-private}"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "usage: $0 <input-file> [output-file]" >&2
  exit 1
fi

INPUT="$1"
OUTPUT="${2:-/dev/stdout}"

[ -r "$INPUT" ] || { echo "error: cannot read $INPUT" >&2; exit 1; }
[ -r "$TRANSFORMS" ] || { echo "error: rules file missing: $TRANSFORMS" >&2; exit 1; }

# --- Output==input guard ------------------------------------------------
# Prevent overwriting the canonical fleet copy with the sanitized version.
if [ "$OUTPUT" != "/dev/stdout" ]; then
  INPUT_REAL=$(cd "$(dirname "$INPUT")" && pwd -P)/$(basename "$INPUT")
  OUTPUT_REAL=$(cd "$(dirname "$OUTPUT" 2>/dev/null)" 2>/dev/null && pwd -P)/$(basename "$OUTPUT") || OUTPUT_REAL="$OUTPUT"
  if [ "$INPUT_REAL" = "$OUTPUT_REAL" ]; then
    echo "error: output path equals input path; refusing to overwrite source: $INPUT" >&2
    echo "       sanitizer destroys private context — write to a different path or use stdout." >&2
    exit 1
  fi
fi

# --- Marker validation (case + whitespace tolerant; nested rejected) ----
python3 - "$INPUT" "$FLEET_MARKER" <<'PY' || exit 2
import re, sys
src = open(sys.argv[1]).read()
prefix = re.escape(sys.argv[2])
START_RE = re.compile(rf"<!--\s*{prefix}\s*:\s*start\s*-->", re.IGNORECASE)
END_RE   = re.compile(rf"<!--\s*/?\s*{prefix}\s*:\s*end\s*-->", re.IGNORECASE)
markers = []
for m in START_RE.finditer(src):
    markers.append(("S", m.start()))
for m in END_RE.finditer(src):
    markers.append(("E", m.start()))
markers.sort(key=lambda x: x[1])
depth = 0
for kind, pos in markers:
    if kind == "S":
        depth += 1
        if depth > 1:
            sys.stderr.write(f"error: nested marker at byte {pos}; nesting is not allowed\n")
            sys.exit(2)
    else:
        depth -= 1
        if depth < 0:
            sys.stderr.write(f"error: unmatched :end marker at byte {pos} (no preceding :start)\n")
            sys.exit(2)
if depth != 0:
    sys.stderr.write(f"error: unbalanced markers ({depth} unclosed :start); fix the source file\n")
    sys.exit(2)
PY

# --- Step 1: Strip private blocks ---------------------------------------
STRIPPED_TMP=$(mktemp)
trap 'rm -f "$STRIPPED_TMP"' EXIT
python3 - "$INPUT" "$FLEET_MARKER" > "$STRIPPED_TMP" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
prefix = re.escape(sys.argv[2])
PATTERN = re.compile(
    rf"\n?<!--\s*{prefix}\s*:\s*start\s*-->.*?<!--\s*/?\s*{prefix}\s*:\s*end\s*-->\n?",
    re.DOTALL | re.IGNORECASE,
)
out = PATTERN.sub("", src)
sys.stdout.write(out)
PY

# --- Step 2: Apply transforms -------------------------------------------
SED_ARGS=()
while IFS=$'\t' read -r pattern replacement _comment; do
  pattern="${pattern%$'\r'}"
  replacement="${replacement%$'\r'}"
  [[ -z "$pattern" || "$pattern" == \#* ]] && continue
  SED_ARGS+=( -e "s|${pattern}|${replacement}|g" )
done < "$TRANSFORMS"

if [ "${#SED_ARGS[@]}" -eq 0 ]; then
  echo "warn: no transforms loaded from $TRANSFORMS" >&2
  cat "$STRIPPED_TMP" > "$OUTPUT"
else
  sed "${SED_ARGS[@]}" "$STRIPPED_TMP" > "$OUTPUT"
fi

if [ "$OUTPUT" != "/dev/stdout" ]; then
  echo "✓ sanitized → $OUTPUT" >&2
  echo "  next: bash $SCRIPT_DIR/post-scan.sh $OUTPUT" >&2
fi
