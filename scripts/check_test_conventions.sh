#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check_test_conventions.sh
#
# Enforces AGENTS.md test conventions in CI:
#   1. No test file imports mockito or mocktail.
#   2. No test file contains both test( and testWidgets(.
#   3. No Hive.init() outside *_hive_test.dart files.
#   4. Every source file in key dirs has a corresponding test file.
# ---------------------------------------------------------------------------
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$HERE")"

cd "$REPO"
EXIT_CODE=0

echo "=== Test Convention Check ==="

# ---- 1. No mockito/mocktail imports ----
echo "--- 1. Checking for mockito/mocktail imports ---"
MOCK_IMPORTS=0
while IFS= read -r f; do
  echo "  mockito/mocktail found in: $f"
  MOCK_IMPORTS=$((MOCK_IMPORTS + 1))
done < <(grep -rl 'import.*mockito\|import.*mocktail' test/ --include='*.dart' 2>/dev/null || true)

if [ "$MOCK_IMPORTS" -eq 0 ]; then
  echo "  PASS: No mockito/mocktail imports."
else
  echo "  FAIL: $MOCK_IMPORTS file(s) use mockito/mocktail."
  EXIT_CODE=1
fi

# ---- 2. No mixed unit/widget tests ----
echo "--- 2. Checking for mixed test() + testWidgets() files ---"
MIXED=0
while IFS= read -r f; do
  has_test=$(grep -cE '\btest\(' "$f" 2>/dev/null || echo 0)
  has_widget=$(grep -cE '\btestWidgets\(' "$f" 2>/dev/null || echo 0)
  if [ "$has_test" -gt 0 ] && [ "$has_widget" -gt 0 ]; then
    echo "  Mixed: $f ($has_test test(), $has_widget testWidgets())"
    MIXED=$((MIXED + 1))
  fi
done < <(find test -name '*_test.dart' -type f | sort)

if [ "$MIXED" -eq 0 ]; then
  echo "  PASS: No mixed unit/widget tests."
else
  echo "  FAIL: $MIXED file(s) mix test() and testWidgets()."
  EXIT_CODE=1
fi

# ---- 3. Hive.init in non-hive test files ----
echo "--- 3. Checking Hive.init() in non-hive test files ---"
HIVE_OFFENDERS=0
while IFS= read -r f; do
  if echo "$f" | grep -q '_hive_test\.dart$'; then
    continue
  fi
  echo "  Hive.init() in non-hive file: $f"
  HIVE_OFFENDERS=$((HIVE_OFFENDERS + 1))
done < <(grep -rl 'Hive\.init(' test/ --include='*.dart' 2>/dev/null || true)

if [ "$HIVE_OFFENDERS" -eq 0 ]; then
  echo "  PASS: No Hive.init() outside *_hive_test.dart."
else
  echo "  FAIL: $HIVE_OFFENDERS file(s) use Hive.init() (should be in *_hive_test.dart only)."
  EXIT_CODE=1
fi

# ---- 4. Missing test files for key locations ----
echo "--- 4. Checking source files have corresponding test files ---"
MISSING=0

_check_file() {
  local src="$1"
  local expected="$2"
  if [ ! -f "$expected" ]; then
    echo "  MISSING: $expected (for $src)"
    MISSING=$((MISSING + 1))
  fi
}

while IFS= read -r src; do
  case "$src" in
    lib/features/*/services/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/features/*/data/repositories/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/features/*/data/adapters/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/features/*/providers/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/features/*/presentation/widgets/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/features/*/presentation/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/features/*/data/models/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/core/services/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/core/providers/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/core/utils/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
    lib/core/data/**/*.dart)
      base="test/${src#lib/}"
      expected="${base%.dart}_test.dart"
      _check_file "$src" "$expected"
      ;;
  esac
done < <(find lib -name '*.dart' -type f | grep -vE '\.(g|freezed|grpc)\.dart$' | sort)

if [ "$MISSING" -eq 0 ]; then
  echo "  PASS: All source files have corresponding test files."
else
  echo "  FAIL: $MISSING source file(s) missing test files."
fi

# ---- Summary ----
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "All test convention checks passed."
else
  echo "Some test convention checks FAILED."
fi

exit $EXIT_CODE
