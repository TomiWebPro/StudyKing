#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COVERAGE_DIR="$PROJECT_DIR/coverage"

cd "$PROJECT_DIR"

echo "=== Step 1: Run base constants tests (no special defines) ==="
flutter test --coverage test/core.constants.*.test.dart
cp coverage/lcov.info coverage/lcov_base.info

echo ""
echo "=== Step 2: Run production env tests (APP_ENV=production, empty key) ==="
flutter test --coverage \
  --dart-define=APP_ENV=production \
  test/advanced/core.constants.app_production_config.test.dart
cp coverage/lcov.info coverage/lcov_prod.info

echo ""
echo "=== Step 3: Run combined production + encryption tests ==="
flutter test --coverage \
  --dart-define=APP_ENV=production \
  --dart-define=STUDYKING_ENCRYPTION_KEY=MyKeyWithNumbers123456789012345678 \
  test/advanced/core.constants.app_encryption_config.test.dart
cp coverage/lcov.info coverage/lcov_combined.info

echo ""
echo "=== Step 4: Merge all coverage files ==="
python3 scripts/merge_lcov.py \
  coverage/lcov.info \
  coverage/lcov_base.info \
  coverage/lcov_prod.info \
  coverage/lcov_combined.info

echo ""
echo "=== Step 5: Coverage summary for lib/core/constants/ ==="
python3 scripts/coverage_summary.py coverage/lcov.info
