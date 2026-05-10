# StudyKing Flutter App - Comprehensive Code Review Report

## Executive Summary

This code review identifies **CRITICAL** gaps in the StudyKing application. The app has a foundational structure for subject management and practice sessions, but **is in an incomplete state** with significant missing functionality. Several screens appear functional but lack complete implementation, particularly around question answering, AI integration, and lesson features.

---

## 1. UI/UX OMISSIONS - Screens That Don't Work Properly

### 1.1 PracticeScreen (CRITICAL)
**File:** `lib/features/practice/presentation/practice_screen.dart`

**Issues:**
- ✅ Subjects loading works correctly
- ✅ Empty state shows properly
- ⚠️ **Dialog for practice session starting - no transition to actual practice**
- ⚠️ "Spaced Repetition" mode marked as "Coming soon" but disabled
- ⚠️ "Weak Areas" mode also disabled
- ⚠️ `_showTopicSelector()` shows snackbar message only - no topic selection UI
- **Button at line 156-162 has `onPressed` with empty comment** - dead code

### 1.2 PracticeSessionScreen (CRITICAL)
**File:** `lib/features/practice/presentation/practice_session_screen.dart`

**Issues:**
- ⚠️ **Lines 395-403: SingleChoice/MultiChoice questions use hardcoded options**
  ```dart
  options: ['Answer A', 'Answer B', 'Answer C', 'Answer D']
  ```
  Actual question options from markscheme are NOT loaded or displayed
  
- ⚠️ **Timer not actually tracking time** - Timer initialized at line 60 but never used for counting
   
- ⚠️ **Validation is overly permissive** at line 172: typed answers accepted if not empty

- **Line 64: Timer period is 1 second with empty callback** - doesn't actually track elapsed time

### 1.3 SubjectListView (CRITICAL)
**File:** `lib/features/subjects/presentation/subject_list_view.dart`

**Issues:**
- **Line 111: Card tap handler is empty** - no navigation or action
  ```dart
  onTap: () {
    // Navigate to subject detail
  },
  ```

### 1.4 LessonListScreen (CRITICAL)
**File:** `lib/features/lessons/presentation/lesson_list_screen.dart`

**Issues:**
- ✅ Basic lesson list working
- ⚠️ **"No lessons - use Planner to generate!" message displayed** - suggests features not connected
- ✅ Navigation to LessonDetailScreen implemented

### 1.5 SessionHistoryScreen (WORKING)
**File:** `lib/features/sessions/presentation/session_history_screen.dart`

**Assessment:** This screen is **fully functional** with:
- ✅ Session filtering by date
- ✅ Session filtering by subject  
- ✅ Delete sessions with confirmation dialog
- ✅ Statistics calculation
- ✅ Clean UI with proper formatting

### 1.6 LESSON FEATURE - CRITICAL GAP
**Screen:** `lib/features/lessons/presentation`

**Issues:**
- README claims "Planner" generates content
- `planner.dart` and `planner_screen.dart` EXIST but no integration shown in main navigation
- Topics/Questions flow from AI → Planner → Lessons → Practice is **NOT implemented**

---

## 2. MISSING FEATURES / INCOMPLETE IMPLEMENTATIONS

### 2.1 AI-Generated Questions Pipeline (CRITICAL)
**Status:** INCOMPLETE
- `core/services/ai_model_service.dart` exists
- `core/services/pdf_ingestion_service.dart` exists
- **No actual AI question generation implementation**
- Questions cannot be created without manual creation (no UI found for this)

### 2.2 Markscheme/Answer Validation (CRITICAL)
**File:** `lib/features/questions/services/answer_validator.dart`

- Exists as export but **no implementation details found**
- PracticeSession uses naive validation logic
- No fuzzy matching for text answers

### 2.3 Spaced Repetition Algorithm (CRITICAL)
**Status:** MARKED "Coming soon" but never implemented
- Enabled spaced repetition cards in practice modes
- No `lib/core/services/adaptive_practice_engine.dart` implementation found

### 2.4 PDF Processing (CRITICAL)
**F iles:** `core/services/pdf_generator/`, `core/services/pdf_ingestion_service.dart`
- Exist in codebase but **no workflow integration**
- `pdf_ingestion_service.dart` has no import in main app

### 2.5 Features Not in Navigation (CRITICAL)
**Files existing but not navigable:**
- `lib/features/planner/planner.dart` - No route or nav button
- Sessions functionality appears incomplete
- Questions management UI not found

### 2.6 Settings Navigation (CRITICAL)
**File:** `main.dart`

- **SettingsScreen in navigation bar has no route definition**
- Routes only define: `/api-config`, `/profile`
- SettingsScreen imports exist but user **cannot navigate to it via app navigation**

---

## 3. ERROR HANDLING ISSUES

### 3.1 PracticeScreen Error Handling (MAJOR)
```dart
try {
  final subjects = await _fetchSubjects();
  // ...
} catch (e) {
  debugPrint('Error loading subjects: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load subjects: $e')),
    );
  }
}
```
- **Re-pronounces full exception to user** - should sanitize error messages
- No retry mechanism

### 3.2 Generic Error Messages (MAJOR)
- All error messages show raw error strings: `'Failed to load subjects: $e'`
- **User sees internal errors** - should translate to user-friendly messages
- **No logging framework** - only `debugPrint`

### 3.3 HiveBox Initialization (CRITICAL)
**File:** `main.dart`

```dart
await HiveInitializer.initialize();
await database.subjectRepository.init();
await database.topicRepository.init();
// ...
```

- Relies on **asynchronous DatabaseService initialization in `main()`** before app starts
- If error occurs during database init, **app may crash without user recovery**
- Exception handler at line 168-171 just prints and continues

### 3.4 Setting Loading Errors (MAJOR)
```dart
try {
  final settings = await _repository.getSettings();
  state = settings;
} catch (e) {
  debugPrint('Error loading settings: $e');
  state = SettingsBox();  // Silently defaults
}
```
- **Silently falls back** without user notification
- User unaware settings failed to load

---

## 4. STATE MANAGEMENT PROBLEMS

### 4.1 Mixed Patterns (MAJOR)
- **Riverpod** used for some providers in `main.dart`
- But widgets directly call `database.*Repository` instead of using Riverpod
- **Inconsistent state flow** - some data through Riverpod, some bypassing it

### 4.2 Provider Initialization Order (MAJOR)
**File:** `main.dart` (lines 182-187)

```dart
final settings = ref.watch(settingsProvider);

// Sync secondary providers with settings
 WidgetsBinding.instance.addPostFrameCallback((_) {
   ref.read(apiKeyProvider.notifier).state = settings.apiKey;
   // ...
});
```

- **Settings Controller loads in main.dart before WidgetTree appears**
- This creates a race condition: settings load asynchronously, but ConsumerWidget may start before data ready
- **Provider state sync happens after first frame** - may cause visual glitches

### 4.3 Cycle Guards Missing (MAJOR)
```dart
@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```
- Timer implemented in PracticeSession
- **But PracticeScreen timer not cleaned up if navigation happens**

### 4.4 Global Database Dependency (MINOR)
```dart
import 'package:studyking/main.dart' show database;
```
- **Multiple files import from main.dart** creating circular dependencies risk
- **Not testable in isolation** - global state coupling

---

## 5. MISSING TESTS

### 5.1 Test Coverage Assessment (CRITICAL)

**File:** `test/widget_test.dart`

**Status:** BASIC ONLY
```dart
testWidgets('StudyKing app loads', (WidgetTester tester) async {
  await tester.pumpWidget(const StudyKingApp());
  expect(find.text('0'), findsOneWidget);
  expect(find.text('1'), findsNothing);
  // ...
  await tester.tap(find.byIcon(Icons.add));
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
});
```

- **This test** checks OLD code pattern (counter from sample app)
- **Does NOT test** StudyKingApp (StudyKingApp has no counter!)
- **Actually tests wrong UI** - Checks for text '0' and '1' which don't exist in StudyKing
- **No business logic tests** for questions, subjects, sessions

### 5.2 Missing Test Files (CRITICAL)
The following have ZERO test coverage:

| Component | Test Status |
|-----------|-------------|
| QuestionRepository | ❌ None |
| SubjectRepository | ❌ None |
| LessonRepository | ❌ None |
| StudySessionRepository | ❌ None |
| LessonBlockRepository | ❌ None |
| TopicRepository | ❌ None |
| AnswersRepository | ❌ None |
| AttemptsRepository | ❌ None |
| QuestionPDFGenerator | ❌ None |
| MarkdownGenerator | ❌ None |
| Dynamo Repository | ❌ None |
| AnswerValidator | ❌ None |
| PracticeSessionScreen | ❌ None |
| StudyKingApp | ❌ None |
| SettingsRepository | ❌ None |

### 5.3 Test Configuration (MAJOR)
```bash
flutter_test:    sdk: flutter
flutter_lints:   ^5.0.0
leak_tracker_flutter_testing: ^3.0.10
hive_generator:  ^2.0.1
```

- **Hive tests setup not configured** - `hive_generator` exists but no test files or setup
- **No mocking framework** for repositories
- **No integration tests** at all

### 5.4 Test Recommendations: ADD AT LEAST

1. `test/repository_test.dart` - Core repository operations
2. `test/screens.practice.test.dart` - Practice functionality
3. `test/screens.subjects.test.dart` - Subject management
4. `test/screens.sessions.test.dart` - Session tracking
5. `test/validation.answer.test.dart` - Answer validation logic
6. `test/integration.practice.test.dart` - Full practice flow

---

## 6. DOCUMENTATION GAPS

### 6.1 README.md (PARTIAL)
**Strengths:**
- Basic setup instructions present
- Feature list is aspirational but unclear current status
- Tech stack documented

**Gaps:**
- **No API endpoint documentation** (openrouter.ai usage unclear)
- **No data model documentation** (Hive box schema explanation missing)
- **No architecture overview** - unclear folder structure purpose
- **Incomplete changelog** - only v0.1.0 listed

### 6.2 Inline Documentation (INCONSISTENT)

### 6.3 Feature Status Unclear (CRITICAL)
README states:
```
## Features in Development
- [ ] Dynamic AI model selection from API
- [ ] PDF ingestion pipeline
- [ ] Spaced repetition algorithm
```

BUT app contains implementations for features marked incomplete

**Inconsistencies Found:**
- README says "Local database focus" 
  But `pdf_ingestion_service.dart` imports DynamoDB reference (no DB configured)
- README says "No actual implementation" for some features
  But code exists with TODO comments

### 6.4 Missing Files:
- ❌ CHANGELOG.md (beyond README)
- ❌ TODO.md or DEVELOPMENT.md
- ❌ MIGRATION.md for Hive schema changes
- ❌ CONTRIBUTING.md (exists but basic)
- ❌ DESIGN.md or UI Guidelines
- ❌ API.md for any external integrations

---

## 7. HIGH-PRIORITY ISSUES REQUIRING IMMEDIATE ATTENTION

### P0 - CRITICAL (Block User Flow)
1. **SettingsScreen not navigable** from bottom navigation
2. **Subject cards have no tap handler** - no navigation to details
3. **PracticeSession uses hardcoded answers** - cannot test real questions
4. test/widget_test.dart checks **wrong UI elements** - may fail

### P1 - HIGH (User Experience Impact)
1. **Timer not actually tracking time** in practice sessions
2. **Error messages expose internal errors** to users
3. **Mixed Riverpod/global state patterns** - unpredictable behavior
4. **All repositories appear functional in code** but no integration tests to verify

### P2 - MEDIUM (Future Feature Impact)
1. AI question generation pipeline not connected
2. **PDF processing imports not integrated**
3. **Spaced repetition never implemented** despite UI
4. Topic/Question management UI missing

### P3 - LOW (Maintainability)
1. **Imports duplicate `main.dart` across files**
2. **Hive generator needs configuration**
3. **Need clearer naming for question types**

---

## 8. RECOMMENDATIONS

### Immediate (First Sprint)
1. **Implement Settings screen routing** - Add route to MaterialApp routes
2. **Complete subject detail navigation** - Add onTap handler with detail screen
3. **Fix broken test** - Mark as skip or rewrite to test StudyKing
4. **Disable broken features explicitly** - "Coming soon" features should be disabled/dialog

### Short-term (Next Sprint)
1. **Implement question generation workflow** - Create Questions screen
2. **Build AnswerValidator** - Connect actual answers to markscheme
3. **Standardize state management** - Choose one pattern consistently
4. **Add error boundaries** - Better error handling globally

### Medium-term (Feature Complete)
1. **Implement spaced repetition** - Build algorithm or choose library
2. **Connect PDF ingestion** - Complete document processing flow
3. **Add AI model selection** - Wire up OpenRouter.io
4. **Write integration tests** - Test full user flows

### Code Quality
1. **Create unit tests** for all repositories
2. **Replace try/catch with GetIt or Riverpod error handling**
3. **Add declaration files** for RPC interfaces
4. **Use null-safety properly** - Add runtime checks

---

## 9. FILES REQUIRING IMMEDIATE REVIEW

- ✅ `lib/main.dart` - Entry point working but has Architectural issues
- ✅ `lib/features/practice/presentation/practice_screen.dart` - UI exists but broken functionality
- ⚠️ `lib/features/practice/presentation/practice_session_screen.dart` - Critical bug (hardcoded answers)
- ⚠️ `lib/features/subjects/presentation/subject_list_view.dart` - Nav functionality missing
- ⚠️ `lib/features/lessons/presentation/lesson_list_screen.dart` - Connected to missing Planner
- ⚠️ `test/widget_test.dart` - **Broken test - should fix or remove**
- ✅ `lib/core/data/hive_initializer.dart` - Initialized but dependencies incomplete

---

## 10. APP ASSESSMENT

**Current State:** ALPHA BETA (As labeled in README)

- **Working:** Subjects list, Session history display, Basic settings UI
- **Broken:** Subject detail navigation, Practice answer flow, Test suite
- **Missing:** Question creation, AI integration, PDF processing, Spaced repetition
- **Risky:** Mixed patterns no exit strategy, No integration tests

**Verdict:** Foundation exists for a **functional** study app, but major features are **incomplete or broken**. User can:
- ✅ Add subjects
- ✅ View session history
- ✅ Navigate bottom tabs
- ❌ Practice questions (broken answer flow)
- ❌ Manage lessons (navigation incomplete)
- ❌ Configure settings fully (screen not reachable)

---

## Generated: May 10, 2026 01:45 PM
## Reviewer: Hermes Agent
