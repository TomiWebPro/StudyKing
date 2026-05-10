# Change Log

All notable changes to the StudyKing project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **P0-1**: Single/multi-choice questions now use `question.options` field properly
- **P0-2**: AnswerValidator initialized with `question.markscheme` (not null)
- **P0-3**: `test/widget_test.dart` fixed to check StudyKing UI instead of counter widget
- **P1-1**: Raw exception stack traces sanitization added (first line only, no trace)
- **P1-2**: Settings loading error now shows user-friendly alert
- **P1-3**: Timer state redeclaration conflict resolved + UI display connected
- **P2-8**: Spaced repetition algorithm wired to repository (`spaced_repetition_repository.dart`)
- **P2-9**: Question analytics dashboard service implemented
- **P2-10**: Session history export feature with CSV support
- **P2-7**: Font size validation enforced (10-30 range) with clamping
- **P3-1**: CHANGELOG.md created with comprehensive release notes

### Added
- New repository: `lib/core/data/repositories/spaced_repetition_repository.dart` with query methods for due questions and review scheduling
- Analytics service: `lib/core/services/study_progress_tracker.dart` with CSV export methods
- Font size slider now shows values as "Xpx" with 10-30 range

### Changed
- `lib/features/settings/presentation/settings_screen.dart`: Updated font size defaults from 12-24 to 10-30 with validation
- `lib/core/services/study_progress_tracker.dart`: Added `exportProgressCSV()`, `exportQuestionsAndAttemptsCSV()`, `exportSessionHistoryCSV()` methods
- `lib/features/settings/data/repositories/settings_repository.dart`: Updated font size validation logic

## [0.1.0] - 2026-05-10

### Added
- Initial release of StudyKing
- Core subject and practice features
- Dynamic AI model fetching from OpenRouter API
- Settings management with theme, font size, and model configuration
- Database integration with Hive (local storage)
- Basic adaptive practice engine

---

Built with ❤️ by TomiWebPro
