#!/bin/bash
# Check i18n coverage: validate that all keys in app_en.arb exist in every locale ARB file.
# Usage: ./scripts/check_i18n_coverage.sh
# Returns exit code 1 if any locale has missing keys.

set -euo pipefail

ARB_DIR="lib/l10n"
TEMPLATE="$ARB_DIR/app_en.arb"

if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: Template file $TEMPLATE not found. Run this script from the project root."
  exit 1
fi

# Extract all key names from the template (excluding @@locale and @metadata keys)
TEMPLATE_KEYS=$(grep -oP '^\s{2}"\K[^"]+' "$TEMPLATE" | grep -v '^@\|^@@' || true)

HAD_ERROR=false

for locale_file in "$ARB_DIR"/app_*.arb; do
  [ "$locale_file" = "$TEMPLATE" ] && continue
  if [ ! -f "$locale_file" ]; then
    echo "WARNING: No locale files found besides template."
    exit 0
  fi

  BASENAME=$(basename "$locale_file")
  LOCALE_KEYS=$(grep -oP '^\s{2}"\K[^"]+' "$locale_file" | grep -v '^@\|^@@' || true)

  MISSING=0
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    if ! echo "$LOCALE_KEYS" | grep -qxF "$key"; then
      echo "  MISSING: $key"
      MISSING=$((MISSING + 1))
    fi
  done <<< "$TEMPLATE_KEYS"

  TEMPLATE_COUNT=$(echo "$TEMPLATE_KEYS" | wc -l)
  LOCALE_COUNT=$(echo "$LOCALE_KEYS" | wc -l)

  if [ "$MISSING" -gt 0 ]; then
    echo "FAIL: $BASENAME is missing $MISSING key(s) (has $LOCALE_COUNT, expected $TEMPLATE_COUNT)"
    HAD_ERROR=true
  else
    echo "OK: $BASENAME has all $TEMPLATE_COUNT keys (parity: ${LOCALE_COUNT}/${TEMPLATE_COUNT})"
  fi
done

if [ "$HAD_ERROR" = true ]; then
  echo ""
  echo "ERROR: One or more locale files have missing keys."
  exit 1
fi

echo "All locales have 100% key parity with app_en.arb."
echo ""

# ──────────────────────────────────────────────
# Section 2: Detect hardcoded user-facing strings
# Scans lib/features/ and lib/core/ for string
# literals in Text(), Semantics(label:), etc.
# that are not using l10n.* or AppLocalizations.
# ──────────────────────────────────────────────
echo "Checking for hardcoded user-facing strings (heuristic)..."
HARDCODED=false

while IFS=':' read -r file line content; do
  [ -z "$file" ] && continue
  # Skip lines using l10n or AppLocalizations
  case "$content" in
    *l10n.*|*AppLocalizations.of*) continue ;;
  esac
  echo "  WARN: $file:$line — ${2:-hardcoded string}: $content"
  HARDCODED=true
done < <(grep -rnP 'Text\([^)]*["'"'"']' lib/features/ lib/core/ 2>/dev/null || true)

while IFS=':' read -r file line content; do
  [ -z "$file" ] && continue
  case "$content" in
    *l10n.*|*AppLocalizations.of*) continue ;;
  esac
  echo "  WARN: $file:$line — hardcoded string in Semantics(label:): $content"
  HARDCODED=true
done < <(grep -rnP 'Semantics\([^)]*label:\s*["'"'"']' lib/features/ lib/core/ 2>/dev/null || true)

while IFS=':' read -r file line content; do
  [ -z "$file" ] && continue
  case "$content" in
    *l10n.*|*AppLocalizations.of*) continue ;;
  esac
  echo "  WARN: $file:$line — hardcoded string in tooltip:: $content"
  HARDCODED=true
done < <(grep -rnP 'tooltip:\s*["'"'"']' lib/features/ lib/core/ 2>/dev/null || true)

if [ "$HARDCODED" = true ]; then
  echo ""
  echo "WARNING: Potential hardcoded user-facing strings found (see above)."
  echo "These should use l10n.* or AppLocalizations.of(context)!.* instead."
fi

# ──────────────────────────────────────────────
# Section 3: Detect toStringAsFixed in presentation UI code
# (CSV exports and LLM-facing code are exempt)
# ──────────────────────────────────────────────
echo ""
echo "Checking for toStringAsFixed in presentation code..."
TOSFI_FOUND=false
while IFS=':' read -r file line content; do
  [ -z "$file" ] && continue
  # Skip CSV export files
  case "$file" in
    *export*|*progress_tracker*) continue ;;
  esac
  # Skip LLM-facing code (mentor context, prompts)
  case "$file" in
    *mentor_service*|*prompts*) continue ;;
  esac
  # Only check presentation directories and screens
  case "$file" in
    */presentation/*|*/screens/*|*/widgets/*)
      echo "  WARN: $file:$line — toStringAsFixed in UI code: $content"
      TOSFI_FOUND=true
      ;;
  esac
done < <(grep -rn 'toStringAsFixed' lib/ features/ 2>/dev/null || true)

if [ "$TOSFI_FOUND" = true ]; then
  echo ""
  echo "WARNING: toStringAsFixed found in UI code — use formatDecimal/formatPercent from number_format_utils.dart instead."
fi

# ──────────────────────────────────────────────
# Section 4: Detect dead ARB keys (unreferenced in .dart)
# ──────────────────────────────────────────────
echo ""
echo "Checking for unused ARB keys (dead translations)..."
DEAD_KEYS=false
while IFS= read -r key; do
  [ -z "$key" ] && continue
  # Skip metadata keys starting with @
  case "$key" in
    @*) continue ;;
  esac
  # Count references in .dart files (l10n.keyName or l10n[keyName] or "keyName" in ARB context)
  ref_count=$(grep -r "l10n\.$key\b" lib/ 2>/dev/null | wc -l)
  if [ "$ref_count" -eq 0 ]; then
    echo "  UNUSED: $key (no l10n.$key reference in lib/)"
    DEAD_KEYS=true
  fi
done <<< "$TEMPLATE_KEYS"

if [ "$DEAD_KEYS" = true ]; then
  echo ""
  echo "WARNING: Some ARB keys have no corresponding l10n.* usage in Dart code (may be dead translations)."
fi

echo ""
echo "i18n coverage check complete."
