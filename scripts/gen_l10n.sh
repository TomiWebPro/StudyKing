#!/bin/bash
# Regenerate Flutter localization Dart code from ARB files
# Run this after editing any .arb file in lib/l10n/

cd "$(dirname "$0")/.."
flutter gen-l10n
echo "Localization files regenerated successfully."
