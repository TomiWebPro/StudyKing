# StudyKing - Product Roadmap

**Version:** 1.0  
**Last Updated:** April 23, 2026  
**Status:** Pre-Launch Development

---

## 📊 Current State Assessment

### Core Infrastructure ✅ COMPLETE
- **Database:** Hive with 8 models (Subject, Topic, Question, Answer, Source, StudentAttempt, LessonBlock, Lesson, StudySession)
- **Repositories:** 9 repositories with subject filtering
- **State Management:** Riverpod with providers
- **Theme System:** Material 3 with custom color scheme
- **Migration Framework:** Version tracking and schema updates

### Implemented Features ✅ WORKING

#### 1. Subject Management
**Files:** 7
- `Subject` model with full CRUD operations
- `SubjectRepository` with filtering and topic linking
- `SubjectListView` - displays all subjects
- `SubjectSelectionScreen` - add new subjects with color picker
- `SubjectManagementScreen` - advanced subject settings
- Color selection (6 predefined colors)
- Subject code, teacher, syllabus support
- Exam date tracking

#### 2. Lesson System
**Files:** 4
- `Lesson` and `LessonBlock` models
- `LessonRepository` with subject filtering
- `TopicListScreen` - navigable topic hierarchy
- `LessonListScreen` - questions per topic

#### 3. Question System
**Files:** 7
- `Question` model with 10 question types
- `QuestionRepository` with advanced filtering
- `QuestionCardWidget` - displays questions
- `SingleAnswerWidget` - multiple choice interface
- `MathExpressionWidget` - basic math rendering
- `CanvasDrawingWidget` - interactive drawing
- `AnswerValidator` - validation logic
- `Markscheme` model for answers

#### 4. Practice Features
**Files:** 2
- `PracticeScreen` - basic practice interface
- `AdaptivePracticeEngine` - placeholder for adaptive learning

#### 5. Planner System
**Files:** 2
- `PlannerScreen` - schedule display
- Basic planning features

#### 6. Quick Guide
**Files:** 2
- `QuickGuideScreen` - help documentation
- User guide reference

#### 7. Settings
**Files:** 5
- `SettingsScreen` - main settings
- `ProfileScreen` - user profile
- `APIConfigScreen` - LLM API configuration
- `SettingsRepository` - user preferences
- `UserProfileModel` - user data

#### 8. Core Services
**Files:** 35
- `LlmService` - AI content generation with subject context
- `PdfIngestionService` - PDF processing (placeholder)
- `PdfGenerator` - question PDF export
- `StudyProgressTracker` - analytics tracking
- Database migration framework
- Hive initializer with migrations

### Empty/Incomplete Features ⚠️ NEEDS WORK

#### 1. Sessions
- **Status:** Empty directory (0 files)
- **Issue:** Session tracking exists in models but no UI

#### 2. Authentication
- **Status:** Empty directory (0 files)
- **Issue:** No login/registration system

---

## 🚧 Features Needing Enhancement

### Priority 1: High Impact, Needs Implementation

#### 1.1 Practice Session Flow
**Current:** Basic placeholder `PracticeScreen`
**Needs:**
- [ ] Complete practice session UI with question navigation
- [ ] Real-time answer validation display
- [ ] Progress tracking during session
- [ ] Score calculation and summary
- [ ] Next question auto-advance
- [ ] Retry incorrect questions
- [ ] Time tracking per question

**Files to Create/Update:**
- `features/practice/presentation/practice_session_screen.dart` (NEW)
- `features/practice/widgets/question_navigation.dart` (NEW)
- `features/practice/widgets/session_progress.dart` (NEW)

#### 1.2 Navigation & Routing
**Current:** Tab-based with limited navigation
**Needs:**
- [ ] Deep linking to topics from subjects
- [ ] Subject detail view showing all content
- [ ] Breadcrumb navigation
- [ ] Back button handling
- [ ] State preservation when navigating

**Files to Create/Update:**
- `features/subject/presentation/subject_detail_screen.dart` (NEW)
- `core/utils/routes.dart` (COMPLETE)
- `core/utils/navigator.dart` (COMPLETE)

#### 1.3 Question Types Implementation
**Current:** Supports 10 types, but only basic rendering
**Needs:**
- [ ] Complete `SingleAnswerWidget` for MCQs
- [ ] Implement `TypedAnswerWidget` for text input
- [ ] Implement `CanvasDrawingWidget` with save/load
- [ ] Implement `EssayAnswerWidget` with character counter
- [ ] Implement `MathExpressionWidget` with proper LaTeX rendering
- [ ] Implement `GraphDrawingWidget` with axis tools
- [ ] Implement `StepByStepWidget` for multi-part answers

**Files to Create/Update:**
- `features/questions/ui/widgets/typed_answer_widget.dart` (NEW)
- `features/questions/ui/widgets/essay_answer_widget.dart` (NEW)
- `features/questions/ui/widgets/graph_drawing_widget.dart` (NEW)

---

### Priority 2: Core Functionality

#### 2.1 Adaptive Practice Engine
**Current:** Empty engine, no adaptive logic
**Needs:**
- [ ] Spaced repetition algorithm
- [ ] Difficulty adjustment based on performance
- [ ] Learning curve analysis
- [ ] Question recommendation system
- [ ] Performance analytics
- [ ] Personalized study schedules

**Files to Create/Update:**
- `core/services/adaptive_practice_engine.dart` (COMPLETE)
- `core/services/analytics_engine.dart` (NEW)
- `core/models/analytics_model.dart` (NEW)

#### 2.2 Study Session Tracking
**Current:** Models exist but no UI
**Needs:**
- [ ] Session counter and timer
- [ ] Session history view
- [ ] Study time analytics
- [ ] Streak tracking
- [ ] Daily/weekly study goals
- [ ] Achievement badges

**Files to Create/Update:**
- `features/sessions/presentation/session_tracker.dart` (NEW)
- `features/sessions/presentation/session_history.dart` (NEW)
- `features/sessions/widgets/session_analytics.dart` (NEW)

#### 2.3 PDF Generation & Ingestion
**Current:** Basic generator, no real ingestion
**Needs:**
- [ ] Integrate `dart_pdf` package
- [ ] Generate PDFs with proper formatting
- [ ] Export practice sets to PDF
- [ ] Export answer keys
- [ ] PDF import for learning materials
- [ ] OCR integration for scanned documents

**Files to Create/Update:**
- `core/services/pdf_ingestion_service.dart` (COMPLETE)
- `core/services/pdf_generator.dart` (COMPLETE)
- Add `pubspec.yaml` dependencies

---

### Priority 3: Advanced Features

#### 3.1 Multi-Subject Organization
**Current:** Basic subject support
**Needs:**
- [ ] Subject progress dashboard
- [ ] Cross-subject analytics
- [ ] Subject comparison tools
- [ ] Syllabus alignment tracking
- [ ] Teacher-assigned subjects

**Files to Create/Update:**
- `features/subjects/presentation/subject_dashboard.dart` (NEW)
- `features/subjects/widgets/subject_stats.dart` (NEW)
- `features/subjects/presentation/syllabus_tracker.dart` (NEW)

#### 3.2 Progress Analytics
**Current:** Basic tracking in models
**Needs:**
- [ ] Performance charts and graphs
- [ ] Topic mastery tracking
- [ ] Weak area identification
- [ ] Time management insights
- [ ] Prediction of exam performance
- [ ] Comparative analysis with peers

**Files to Create/Update:**
- `core/services/analytics_service.dart` (NEW)
- `core/widgets/progress_charts.dart` (NEW)
- `core/widgets/mastery_indicators.dart` (NEW)

#### 3.3 Content Generation
**Current:** LLM service with basic prompts
**Needs:**
- [ ] Improved prompt engineering
- [ ] Question difficulty calibration
- [ ] Markscheme generation validation
- [ ] Content quality scoring
- [ ] Duplicate question detection
- [ ] Question variety optimization

**Files to Create/Update:**
- `core/services/llm_prompt_engine.dart` (NEW)
- `core/services/content_validator.dart` (NEW)
- `core/services/question_generator.dart` (COMPLETE)

---

### Priority 4: Polish & UX

#### 4.1 User Experience
**Current:** Basic Material 3 theme
**Needs:**
- [ ] Dark mode complete implementation
- [ ] Accessibility improvements (contrast, sizing)
- [ ] Offline mode support
- [ ] Push notifications for study reminders
- [ ] Haptic feedback for interactions
- [ ] Smooth animations and transitions

**Files to Create/Update:**
- `core/config/theme.dart` (COMPLETE)
- `core/services/notification_service.dart` (NEW)
- `core/utils/accessibility.dart` (NEW)

#### 4.2 Performance Optimization
**Current:** No optimization
**Needs:**
- [ ] Lazy loading for large lists
- [ ] Image/canvas caching
- [ ] Database query optimization
- [ ] Network request batching
- [ ] Memory management
- [ ] App startup optimization

**Files to Create/Update:**
- `core/utils/cache_manager.dart` (NEW)
- `core/utils/database_optimizer.dart` (NEW)
- `core/utils/app_performance.dart` (NEW)

---

### Priority 5: Production Ready

#### 5.1 Testing
**Current:** No tests
**Needs:**
- [ ] Unit tests for all repositories
- [ ] Widget tests for UI components
- [ ] Integration tests for feature flows
- [ ] End-to-end tests for critical paths
- [ ] Test coverage reporting

**Files to Create:**
- `test/repositories/` (NEW)
- `test/widgets/` (NEW)
- `test/integration/` (NEW)
- `test/e2e/` (NEW)

#### 5.2 Authentication & Sync
**Current:** No authentication
**Needs:**
- [ ] User registration/login
- [ ] Social sign-on (Google, Apple, etc.)
- [ ] Cloud backup and sync
- [ ] Multi-device support
- [ ] Data privacy controls
- [ ] Account management

**Files to Create:**
- `features/auth/presentation/login_screen.dart` (NEW)
- `features/auth/presentation/register_screen.dart` (NEW)
- `features/auth/services/auth_service.dart` (NEW)
- `features/auth/services/cloud_sync_service.dart` (NEW)

#### 5.3 Deployment
**Current:** Development only
**Needs:**
- [ ] Production build configuration
- [ ] App store optimization
- [ ] Privacy policy generation
- [ ] Terms of service
- [ ] Analytics integration
- [ ] Crash reporting
- [ ] Performance monitoring

**Files to Create:**
- `config/release.yaml` (NEW)
- `docs/privacy_policy.md` (NEW)
- `docs/terms_of_service.md` (NEW)

---

## 🎯 Development Phases

### Phase 1: MVP Ready (Current - 2 weeks)
**Goal:** Minimum viable product for beta testing

**Priorities:**
1. Complete PracticeSessionScreen with navigation
2. Fix remaining UI import issues
3. Implement basic navigation flow
4. Test all CRUD operations
5. Add missing widget imports

**Deliverables:**
- Working subject creation and display
- Usable practice session flow
- Basic question rendering and answering
- No compilation errors

### Phase 2: Feature Complete (2-4 weeks)
**Goal:** All core features working

**Priorities:**
1. Complete all question type widgets
2. Implement adaptive practice engine
3. Add session tracking UI
4. Improve PDF generation
5. Add progress analytics basics

**Deliverables:**
- Full question type support
- Adaptive learning recommendations
- Session history and analytics
- Production-ready PDF export

### Phase 3: Refinement (4-6 weeks)
**Goal:** Polish and optimization

**Priorities:**
1. Complete dark mode
2. Performance optimization
3. Accessibility compliance
4. Comprehensive testing
5. User experience improvements

**Deliverables:**
- Smooth, responsive app
- Full accessibility support
- 80%+ test coverage
- Production build ready

### Phase 4: Production Launch (6-8 weeks)
**Goal:** Ship to app stores

**Priorities:**
1. Authentication system
2. Cloud sync
3. App store deployment
4. Analytics integration
5. Marketing materials

**Deliverables:**
- Live app in stores
- Active user base
- Analytics dashboard
- Support system

---

## 📦 Dependencies Needed

### Currently Missing
```yaml
dependencies:
  # PDF Generation
  pdf: ^3.10.7          # PDF generation
  print_pdf: ^1.0.0     # PDF printing
  
  # Math Rendering
  math_expressions: ^2.4.0  # Math parsing
  typst_parser: ^0.x        # Typst rendering
  
  # Image/Canvas
  image: ^4.1.7       # Image manipulation
  screenshot: ^2.1.0  # Canvas screenshots
  
  # Analytics
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.8
  
  # Authentication
  firebase_auth: ^4.16.0
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0
  
  # Cloud Sync
  firebase_storage: ^11.6.8
  cloud_firestore: ^4.15.8
```

### Testing Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  flutter_lints: ^3.0.1
  integration_test:
    sdk: flutter
```

---

## 🔍 Technical Debt

### Immediate (Blockers)
1. **Import Paths:** ~15 remaining import path issues in widgets
2. **Empty Features:** `sessions/` and `auth/` directories without implementations
3. **Deprecated APIs:** Several deprecated Flutter methods need migration
4. **Missing Providers:** Riverpod providers incomplete

### Short-term (Quality)
1. **Test Coverage:** 0% currently, target 80%
2. **Documentation:** No API documentation, needs Dart docs
3. **Code Analysis:** Lints not enabled, needs configuration
4. **Error Handling:** Inconsistent error handling across features

### Long-term (Scalability)
1. **Architecture:** Move toward feature-first organization
2. **State Management:** Standardize on Riverpod (some inconsistencies)
3. **Database:** Consider migration to SQLite for complex queries
4. **Performance:** Add profiling and optimization

---

## 📈 Success Metrics

### Feature Completion
- [ ] 100% of Priority 1 features implemented
- [ ] 80% of Priority 2 features implemented
- [ ] 0 compile errors
- [ ] 80%+ test coverage

### Performance
- App cold start < 2 seconds
- Frame rate maintained at 60 FPS
- Memory usage < 200MB
- Database queries < 50ms

### User Experience
- < 1 second for page transitions
- Intuitive navigation flow
- No error modals in normal use
- Satisfied users > 85%

---

## 🚀 Next Immediate Actions

1. **Today:** Fix remaining 3 compilation errors
2. **This Week:** 
   - Complete PracticeSessionScreen
   - Fix all import paths
   - Test full CRUD flows
3. **Next Sprint:**
   - Implement session tracking UI
   - Add progress analytics
   - Complete PDF generation
4. **Month 1:**
   - Alpha release to internal testing
   - Collect feedback
   - Prioritize based on user input

---

**Note:** This roadmap is flexible and will evolve based on user feedback, technical constraints, and business priorities. Regular reviews should be conducted every sprint to update priorities and timelines.
