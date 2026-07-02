# Setup Guide

## Prerequisites

- **Flutter SDK:** ^3.11.5 (see `pubspec.yaml` for exact version)
- **Dart SDK:** ^3.11.5
- **Platform support:** Linux, macOS, Windows, Web, Android, iOS

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd StudyKing
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Environment Configuration

Copy the environment template:

```bash
cp .env.example .env
```

Configure your environment variables as needed.

### 4. Generate localizations

```bash
bash scripts/gen_l10n.sh
# Or directly:
flutter gen-l10n
```

### 5. Run the app

```bash
flutter run
```

For a specific platform:

```bash
flutter run -d linux
flutter run -d chrome     # Web
flutter run -d android    # Connected device/emulator
```

## IDE Setup

### VS Code

Recommended extensions:
- **Flutter** — Official Flutter extension
- **Error Lens** — Inline error display
- **Material Icon Theme** — File icon theming

### Android Studio / IntelliJ

- **Flutter plugin** — Required for Flutter development
- **Dart plugin** — Required for Dart support

## Build Configurations

### Environment Build Variants

Build configuration constants are in `lib/core/constants/`:

| File | Purpose |
|---|---|
| `app_build_config.dart` | Build environment (dev/staging/prod), app name, version |
| `app_api_config.dart` | API URLs, authentication constants |
| `app_storage_config.dart` | Hive box configuration |
| `app_config.dart` | General app configuration |
| `app_constants.dart` | Aggregated constants, initialization |

## Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/practice/services/spaced_repetition_engine_test.dart

# Run tests for a specific feature
flutter test test/features/planner/
```

## Code Generation

```bash
# Generate localization files
bash scripts/gen_l10n.sh

# Generate Hive type adapters (when models change)
dart run build_runner build
```

## Validation

```bash
# Lint check
flutter analyze

# ARB duplicate key validation
dart run scripts/validate_arb_no_duplicates.dart

# Check for hardcoded user-facing strings
grep -rn "'[A-Z][a-z]" lib/features/ lib/core/ | grep -v '.arb' | grep -v 'import'
```

## Data Backup

The app supports automatic and manual data backup via the Settings screen. Backups export all Hive box data to a JSON file that can be restored later.
