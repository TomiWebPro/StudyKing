# StudyKing

StudyKing is a Flutter-based, AI-native learning platform designed to maximize
student learning efficiency and act as a complete long-term study companion.

It combines teaching, mentorship, planning, adaptive practice, content management,
and student progress intelligence into one cohesive system.

## Features

- **Teaching Mode** — conversational AI tutor with interactive lessons,
  follow-up questions, voice interaction, and immediate corrective feedback.
- **Mentor Mode** — an off-class companion for scheduling, long-term goal
  planning, roadmaps, motivation, accountability, and wellbeing support.
- **Adaptive Practice** — spaced repetition, mastery tracking, and practice
  sessions focused on weak areas.
- **Content Ingestion** — upload textbooks, PDFs, notes, question banks,
  syllabi, links, audio/video, and screenshots; content is processed,
  classified, and integrated into the knowledge system.
- **Planner** — long-term study plans ("Learn X in N days"), roadmaps,
  scheduling, and adherence tracking.
- **Question Bank** — organized, categorized questions linked to sources,
  topics, and syllabi, with generated variants.
- **Multi-Syllabus** — learn and track several syllabi simultaneously.
- **Model-Agnostic AI** — local and remote providers (OpenRouter, OpenAI,
  Ollama, and compatible endpoints) with token-usage tracking and an LLM
  task manager.
- **Localized** — internationalized strings and locale-aware formatting.

## Prerequisites

- **Flutter SDK:** ^3.11.5 (see `pubspec.yaml`)
- **Dart SDK:** ^3.11.5
- **Platform support:** Linux, macOS, Windows, Web, Android, iOS

## Getting Started

```bash
git clone <repository-url>
cd StudyKing

# Install dependencies
flutter pub get

# Generate localizations
flutter gen-l10n

# Run the app
flutter run
# Or for a specific platform:
flutter run -d linux
flutter run -d chrome
```

### Environment Configuration

Copy the environment template and fill in API keys:

```bash
cp .env.example .env
```

Keys are passed at build time, for example:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=sk-...
flutter build apk --dart-define=APP_ENV=production
```

Supported variables: `OPENROUTER_API_KEY`, `GOOGLE_API_KEY`,
`WHISPER_API_KEY`, `APP_ENV`, `STUDYKING_ENCRYPTION_KEY`, and optional
model/base-URL overrides (see `.env.example` for the full list).

## Testing

```bash
flutter analyze
flutter test
```

## Project Structure

```
lib/
  core/        # Shared services, providers, utils, models, widgets
  features/    # Feature modules (dashboard, mentor, teaching, planner, ...)
docs/          # Architecture, core, feature, and development guides
test/          # Unit and widget tests mirroring lib/ layout
```

## Documentation

- [Documentation index](docs/README.md) — architecture, features, development
- [AGENTS.md](AGENTS.md) — coding conventions, test placement, issue protocol
- [agent_must_read.md](agent_must_read.md) — product vision

## License

See [LICENSE](LICENSE).
