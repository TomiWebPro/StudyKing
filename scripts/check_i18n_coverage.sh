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
