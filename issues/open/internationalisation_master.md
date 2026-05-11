# Internationalisation: Extensive Hardcoded UI Strings Not Using Localization System

## Context

The StudyKing app has a working localization infrastructure (Flutter's `flutter_localizations` with ARB files for English and Spanish). However, the majority of UI strings throughout the codebase remain hardcoded in English, bypassing the translation system entirely. This severely impacts international users and limits the app's accessibility.

## Affected Files

- `lib/features/settings/presentation/profile_screen.dart` (lines 69, 75, 101, 110, 130, 151, 189, 254, 306, 317, 331, 341, 360, 381, 400, 409, 426-427, 431, 441, 468) — 20+ hardcoded strings
- `lib/features/settings/presentation/settings_screen.dart` (lines 35, 64-65, 78, 89, 139, 147, 162, 186-187, 194, 301, 313, 321, 356-357, 367-368, 370, 378) — 18+ hardcoded strings
- `lib/features/subjects/presentation/subject_detail_view.dart` (lines 241, 315, 352, 364, 613, 621, 629, 645-646, 650, 659, 673, 688) — 12+ hardcoded strings
- `lib/features/subjects/presentation/subject_management_screen.dart` (lines 98, 126, 197, 227) — 4+ hardcoded strings
- `lib/features/subjects/presentation/subject_list_view.dart` (lines 19, 88) — 2 hardcoded strings
- `lib/features/subjects/presentation/subject_selection_screen.dart` (lines 90, 101) — 2 hardcoded strings
- `lib/features/subjects/presentation/subject_form_widgets.dart` (lines 123, 143, 152, 162) — 4 hardcoded strings
- `lib/features/sessions/presentation/session_history_screen.dart` (lines 80, 85, 90, 106, 144, 371, 390) — 7 hardcoded strings
- `lib/features/sessions/presentation/session_tracker_screen.dart` (lines 188, 198, 258, 269, 317, 413, 417, 442, 453) — 9 hardcoded strings
- `lib/features/settings/presentation/api_config_screen.dart` (lines 88, 130) — 2 hardcoded strings
- `lib/pages/graph_rendering_page.dart` (lines 41, 46, 51, 64, 69, 72, 77, 100, 114, 121, 128, 135, 154, 156, 161, 176, 229, 257, 265, 291, 325, 372, 375, 391, 406, 427, 433, 446, 456, 467, 469, 471, 484) — 30+ hardcoded strings
- `lib/pages/lesson_scheduling_page.dart` (lines 22, 45, 64, 87, 89, 121, 141-142) — 8 hardcoded strings
- `lib/features/quickguide/presentation/quick_guide_screen.dart` (lines 96, 321, 332) — 3 hardcoded strings
- `lib/features/questions/ui/widgets/question_card_widget.dart` (lines 162, 183) — 2 hardcoded strings
- `lib/features/questions/ui/widgets/single_answer_widget.dart` (lines 35, 121) — 2 hardcoded strings
- `lib/features/questions/ui/widgets/canvas_drawing_widget.dart` (line 102) — 1 hardcoded string
- `lib/l10n/app_en.arb` — Missing translation keys for profile, settings, and screen titles
- `lib/l10n/app_es.arb` — Missing corresponding translations

## Issue 1: Profile Screen Has 20+ Unlocalized Strings

The Profile screen in `profile_screen.dart` contains extensive hardcoded English strings including:
- 'Name is required', 'Student ID must be numeric', 'Profile saved successfully'
- 'Error saving profile: $e', 'Choose Avatar', 'Select avatar $iconKey'
- 'Profile', 'Full Name', 'Enter your name', 'Student ID (Optional)'
- 'Your student ID number', 'Learning Goal', 'e.g., Final Exams, Certifications'
- 'Preferred Study Time', 'e.g., Evening (6-9 PM)', 'Account Information'
- 'Language', 'English', 'Spanish', 'Notifications', 'Delete Account'
- Warning and confirmation dialogs for account deletion

All these should use `AppLocalizations` for full international support.

## Issue 2: Settings Screen Not Using Localization

Settings screen has 18+ hardcoded strings:
- 'Settings', 'Study Reminders', 'Enable notification alerts'
- 'Total Study Time', 'Sign Out', 'Light', 'Dark'
- 'Font Size', 'API Key Required', 'Please configure your API key first'
- 'Request Timeout', 'Sessions', 'Questions'
- Various dialog content and button labels

## Issue 3: Subject Management Screens Lack Localization

Multiple subject-related screens have hardcoded strings:
- 'My Subjects', 'Add Subject', 'Add New Subject', 'Theme Color'
- 'Exam Date (Optional)', 'Create Subject', 'Start Practice'
- 'No practice history', 'View All Sessions', 'Edit Subject'
- 'Settings', 'Delete Subject', 'Session Details', 'Close'

## Issue 4: Graph Rendering Page Has 30+ Hardcoded Strings

The graph rendering page contains extensive unlocalized strings including:
- 'Graph Renderer', 'Upload Data', 'Upload Data File', 'Or paste data directly'
- 'Graph Type Detection', 'Line Graph', 'Bar Chart', 'Scatter Plot', 'Pie Chart'
- 'LLM Validation', 'Use LLM to validate graph', 'Rendered Graph'
- Various validation and status messages

## Issue 5: Session Tracking Has Unlocalized Strings

- 'Study Session Tracker', 'Start', 'End', 'View All'
- 'Session Complete', 'How many questions did you answer?'
- 'Skip', 'Save'

## Issue 6: Missing Translation Keys in ARB Files

The ARB files lack translation keys for many UI elements:
- Profile field labels and hints
- Settings section titles
- Screen titles ('Graph Renderer', 'Lesson Scheduler', 'Quick Guide')
- Subject management actions and labels
- Session tracking labels
- Confirmation dialogs

## Rationale

This is a high-priority internationalization issue because:

1. **Scope**: Over 100 hardcoded strings across 15+ files affecting every major screen
2. **User Impact**: Non-English users see mixed English/Spanish interfaces, degrading trust
3. **Future Languages**: Adding new languages (French, German, Chinese, etc.) won't help because the strings aren't using the localization system
4. **Consistency**: The localization infrastructure exists but is vastly underutilized
5. **Maintenance**: Hardcoded strings create technical debt and make translation management difficult

## Acceptance Criteria

1. All user-facing strings in `profile_screen.dart` are replaced with `AppLocalizations` calls
2. All user-facing strings in `settings_screen.dart` are replaced with `AppLocalizations` calls
3. All subject management screens use localization for labels, buttons, and messages
4. Graph rendering page uses localization for all UI strings
5. Session tracking and history screens use localization
6. New translation keys are added to both `app_en.arb` and `app_es.arb` for all identified strings
7. `app_localizations.dart` and `app_localizations_es.dart` are regenerated after changes
8. All existing Spanish translations are verified for accuracy (grammar, formality)