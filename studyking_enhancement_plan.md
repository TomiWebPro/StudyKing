# StudyKing Enhancement Plan

## Overview
This document outlines the complete enhancement roadmap for StudyKing to transform it from a solid MVP into a production-ready, enterprise-grade adaptive learning platform capable of supporting long-horizon student study needs.

---

## 📊 Current Status Assessment

### What Works (Production Ready)
- ✅ Hive database layer (9 models, 8 repositories)
- ✅ 3 fully functional UI screens (Lessons, Quick Guide, Planner)
- ✅ Zero compile errors (5 minor warnings only)
- ✅ LLM service architecture (mock & real API ready)
- ✅ PDF ingestion pipeline skeleton
- ✅ Adaptive practice engine (Ebbinghaus algorithm)
- ✅ Progress tracking basic implementation
- ✅ Clean architecture patterns
- ✅ Material 3 responsive UI

### Critical Gaps
- ❌ Settings UI missing (API keys hardcoded in main.dart)
- ❌ No multi-modal input (video/audio/images not implemented)
- ❌ Large PDF handling not optimized (300+ pages may crash)
- ❌ No long-term planning (semester/year roadmaps missing)
- ❌ No unit tests (0% coverage)
- ❌ No search indexing (linear search on large datasets)

---

## 🎯 Priority Roadmap

### 🔴 CRITICAL - Fix Immediately (Week 1)

#### 1.1 UI Settings Screen
**Purpose**: Allow users to configure API keys and app preferences
**Files to Create**:
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/settings/presentation/api_config_screen.dart`
- `lib/features/settings/presentation/profile_screen.dart`

**Features**:
- API key configuration for OpenRouter/Ollama
- Theme toggle (light/dark/system)
- Profile management (student name, ID)
- Data management (backup/export)
- Clear cache storage

**API Keys Needed**:
- `OPENROUTER_API_KEY` - LLM content generation
- `GOOGLE_API_KEY` - YouTube/Audio analysis
- `WHISPER_API_KEY` - Audio transcription (if using Whisper)

---

#### 1.2 Error Handling Framework
**Purpose**: Proper error handling throughout the app
**Files to Create**:
- `lib/core/errors/handlers.dart`
- `lib/features/*/*.exceptions.dart`

**Implementation**:
```dart
// Add centralized error handling
class AppErrorHandler {
  static Future<void> handle(Exception e, String context) async {
    // Log to analytics
    // Show user-friendly error message
    // Retry if applicable
  }
}
```

---

#### 1.3 Unit Test Framework
**Purpose**: Code quality and regression prevention
**Files to Create**:
- `test/core/models/*_test.dart`
- `test/core/services/*_test.dart`
- `test/core/repositories/*_test.dart`

**Targets** (90% coverage):
- Question model validation
- Repository CRUD operations
- LLM service mock tests
- Progress calculation accuracy

---

### 🟠 HIGH PRIORITY (Weeks 2-3)

#### 2.1 Multi-Modal Input Services
**Purpose**: Accept content from video/audio/images, not just PDFs

**Files to Create**:
```
lib/core/services/
├── video_content_parser.dart    # YouTube/mp4 extraction
├── audio_content_parser.dart    # Podcast/speech extraction  
├── image_content_parser.dart    # Diagrams/equations
└── content_detector.dart        # Auto-detect file type
```

**YouTube Feature**:
- Extract transcript via YouTube API
- Generate questions at timestamp intervals
- Store chapter/segment metadata

**Audio Feature**:
- Whisper API integration for speech-to-text
- Support for uploaded audio files
- Language detection and auto-translate

**Image Feature**:
- Tesseract OCR for text extraction
- MathPix API for equation recognition
- Image-based question generation

---

#### 2.2 Large PDF Optimization
**Purpose**: Handle 300+ page PDFs without memory crashes

**Changes**:
```dart
class PdfChunkParser {
  static Stream<ParsedChunk> streamParser(File file) async* {
    final reader = PdfReader(file);
    for (int i = 0; i < reader.pages; i++) {
      final text = await reader.extractText(i);
      final chunks = chunkText(text, size: 10000);
      for (final chunk in chunks) {
        yield ParsedChunk(
          pageNumber: i + 1,
          content: chunk,
          source: file,
        );
      }
      yield*; // Process next page
    }
  }
}
```

**Features**:
- 10KB chunks with 500-byte overlap
- Page number tracking
- OCR for scanned documents
- Progress reporting during large file processing

**Memory Budget**:
- PDF < 50 pages: Load entire file
- PDF 50-200 pages: 50KB chunks
- PDF 200-500 pages: 25KB chunks, streaming
- PDF > 500 pages: 10KB chunks, background processing

---

#### 2.3 User Profile & Settings Storage
**Purpose**: Persist user preferences and account data

**Files to Create**:
- `lib/core/data/models/user_profile.dart`
- `lib/core/data/repositories/user_profile_repository.dart`

**Profile Data**:
- Student name, ID, avatar
- Learning goals (exams, certifications)
- Preferred study times
- Notification preferences
- Language preference
- Accessibility settings

---

### 🟡 MEDIUM PRIORITY (Weeks 4-5)

#### 3.1 Long-Term Planning System
**Purpose**: Support semester/year study horizons

**Files to Create**:
```
lib/core/services/
├── long_term_planner.dart    # Semester roadmaps
├── exam_mode.dart           # Timed practice
├── milestone_tracker.dart   # Assignment/exam deadlines
└── study_calendar.dart      # Integration with calendar
```

**LongTermPlanner Features**:
- Course calendar creation (semester start, exam dates)
- Backward planning from exam date
- Study hour allocation (weekly/monthly targets)
- Milestone alerts (assignments, quizzes, exams)
- Cumulative progress tracking across courses
- Recommended pacing vs. actual pace
**Exam Mode**:
- Timed practice sessions
- Exam simulation (no breaks, strict timing)
- Post-exam analytics vs. real exam conditions
- Difficulty progression simulation

**Calendar Integration**:
- Sync with Google/Apple calendar
- Study session reminders
- Milestone notifications
- Weekly review scheduling

---

#### 3.2 Search & Indexing
**Purpose**: Fast content retrieval on large datasets

**Implementation**:
```dart
class SearchIndex {
  // Reverse index: term -> [contentIds]
  final Map<String, Set<String>> _contentIndex;
  // Topic index: topicId -> [contentIds]
  final Map<String, Set<String>> _topicIndex;
  
  void indexContent(String contentId, String content, String topicId) {
    final terms = _tokenize(content);
    for (final term in terms) {
      _contentIndex.putIfAbsent(term, () => {});
      _contentIndex[term]!.add(contentId);
    }
    _topicIndex.putIfAbsent(topicId, () => {});
    _topicIndex[topicId]!.add(contentId);
  }
  
  Set<String> search(String query) => _contentIndex[query.toLowerCase()] ?? {};
}
```

**Features**:
- Case-insensitive search
- Partial word matching
- Topic-based filtering
- Recent search history
- Search suggestions

---

#### 3.3 Push Notifications
**Purpose**: Remind users of study sessions and milestones

**Implementation**:
- Firebase Cloud Messaging (FCM)
- Notification types:
  - Daily practice reminder
  - Spaced review scheduled
  - Milestone approaching
  - Session overdue
  - Weekly report notification

**Privacy**:
- Allow users to opt-in
- Local storage for preferences
- No data sent without consent

---

### 🟢 LOWER PRIORITY (Weeks 6+)

#### 4.1 Voice Input System
**Purpose**: Allow students to speak answers and questions

**Components**:
- Speech-to-text for answer entry
- Voice prompts for guided lessons
- Audio recordings for essay explanations

**APIs**:
- Google Speech-to-Text
- Whisper (local or cloud)
- Browser API (Web Speech API)

---

#### 4.2 Canvas Drawing Interface
**Purpose**: Enable hand-written solutions for math/science

**Components**:
- Drawing canvas for equations
- Gesture recognition (circle shapes)
- Ink-to-text conversion
- Image export for sharing

---

#### 4.3 Math Rendering
**Purpose**: Professional LaTeX/Typst rendering

**Components**:
- MathJax integration
- Typst support (via webview)
- Render equations in lessons
- Render student answers for evaluation

---

#### 4.4 Mobile Deployment
**Purpose**: iOS and Android apps from Flutter codebase

**Steps**:
- Android SDK setup
- iOS simulator setup
- Flutter build configurations
- App signing and store deployment
- CodePush for hot updates

---

#### 4.5 Offline Mode
**Purpose**: Full functionality without internet

**Components**:
- Local caching of lessons
- Offline question generation (using cached data)
- Sync queue for when connection restored
- Conflict resolution for offline changes

---

#### 4.6 Export & Analytics
**Purpose**: External data analysis and reporting

**Export Formats**:
- PDF study reports
- CSV analytics data
- Anki flashcards (.apkg)
- JSON full backup

**Analytics Dashboard**:
- Study time heatmaps
- Performance trends over time
- Strength/weakness charts
- Achievement progress visualization

---

#### 4.7 Collaborative Features
**Purpose**: Social learning aspects

**Components**:
- Study groups
- Shared progress boards (opt-in)
- Peer review for essay answers
- Study buddy matching
- Leaderboards (with privacy controls)

---

## 📋 Technical Debt to Address

### Code Quality Issues to Fix
| Issue | Priority | File(s) |
|-------|----------|---------|
| Unused imports | Low | Multiple files |
| Dead code | Medium | lesson_detail_screen.dart |
| Field not final | Low | lesson_detail_screen.dart |
| Async context usage | Low | planner_screen.dart |
| No lints in analysis_options.yaml | Medium | Create new file |

### Architecture Improvements
| Issue | Priority | Recommendation |
|-------|----------|----------------|
| Global `database` variable | Low | Move to Riverpod provider |
| No dependency injection | Medium | Add DI framework (get_it) |
| Hardcoded API URLs | High | Environment variables (.env) |
| No versioning | Low | Add app versioning system |

---

## 🗓️ Detailed Timeline

### Week 1 - Foundation Fixes
```
Day 1-2: Settings UI implementation
Day 3-4: Error handling framework
Day 5-7: Unit test framework + first tests
```

### Week 2 - Multi-Modal Input
```
Day 1-2: VideoContentParser (YouTube)
Day 3-4: AudioContentParser (Whisper)
Day 5: ImageContentParser (OCR)
Day 6-7: ContentDetector + integration
```

### Week 3 - Large File Handling
```
Day 1-2: PdfChunkParser implementation
Day 3: Page metadata extraction
Day 4: OCR for scanned documents
Day 5: Memory optimization testing
Day 6-7: Large file stress testing
```

### Week 4 - Long-Term Planning
```
Day 1-2: LongTermPlannerService
Day 3-4: Exam Mode implementation
Day 5: Milestone tracker
Day 6-7: Calendar integration
```

### Week 5 - Search & Indexing
```
Day 1-2: SearchIndex implementation
Day 3: Full-text search
Day 4: Recent searches
Day 5: Search suggestions
Day 6-7: Performance optimization
```

### Week 6 - Notification System
```
Day 1-2: FCM setup
Day 3-4: Notification types implementation
Day 5: Notification preferences UI
Day 6-7: Testing and optimization
```

### Week 7-8 - Polish & Testing
```
Week 7: Voice input, Canvas, Math rendering
Week 8: Mobile builds, offline mode, final QA
```

---

## 📈 Success Metrics

### Quality Metrics (Target Values)
| Metric | Current | Target |
|--------|---------|--------|
| Compile errors | 0 | 0 ✅ |
| Compile warnings | 5 | 0 |
| Test coverage | 0% | 90% |
| Code complexity | Medium | Low |
| App size increase | N/A | < 10% |

### Feature Completion
| Component | Status | Target |
|-----------|--------|--------|
| Settings UI | 0% | 100% |
| Multi-modal input | 0% | 100% |
| Large PDF handling | 0% | 100% |
| Long-term planning | 0% | 100% |
| Search indexing | 0% | 100% |
| Notifications | 0% | 100% |

---

## 🔐 Security Considerations

### API Key Security
```
❌ DON'T: Store API keys in Git repos
❌ DON'T: Log API responses with keys
❌ DON'T: Expose keys in client-side code

✅ DO: Use environment variables
✅ DO: Encrypt keys in local storage
✅ DO: Token refresh mechanisms
✅ DO: Rate limiting on client
```

### User Data Privacy
```
✅ Explicit consent for data collection
✅ No data sharing without permission
✅ Data export functionality
✅ GDPR compliance for EU users
✅ Data retention limits
```

---

## 📞 Dependencies to Add

### New Package Dependencies

```yaml
# In pubspec.yaml (additions):

# PDF Processing
pdf: ^3.10.1
pdfx: ^3.0.0

# File Handling
file_picker: ^8.0.3
path_provider: ^2.1.2

# Search
flutter_search_bar: ^3.0.0
elastic_search: ^3.0.0

# Charts/Analytics
fl_chart: ^0.69.0
charts_flutter: ^0.12.0

# Notifications
firebase_messaging: ^14.7.8
flutter_local_notifications: ^17.2.2

# Voice
speech_to_text: ^6.6.0

# Drawing
flutter_stylus: ^1.2.0

# Environment
flutter_dotenv: ^5.2.0

# Testing (if not already)
mockito: ^5.4.4
build_runner: ^2.4.13
```

---

## 🏁 Implementation Priority Decision Matrix

| Feature | Impact | Effort | Priority | Owner |
|---------|--------|--------|----------|-------|
| Settings UI | High | Low | 🔴 Critical | Everyone |
| Error Handling | High | Medium | 🔴 Critical | Everyone |
| Unit Tests | High | Medium | 🔴 Critical | QA Lead |
| Video Parser | Medium | Medium | 🟠 High | Backend |
| Large PDF | Medium | High | 🟠 High | Backend |
| Long-Term Planner | High | High | 🟠 High | Backend |
| Search Indexing | Medium | Medium | 🟡 Medium | Backend |
| Notifications | Medium | Low | 🟡 Medium | Mobile |
| Voice Input | Low | High | 🟢 Low | AI Team |
| Canvas Drawing | Low | High | 🟢 Low | Frontend |

---

## 📝 Notes

1. **Start with Settings UI** - This blocks progress on all AI features
2. **No rushing tests** - Write tests as you build new features
3. **Multi-modal first** - This is the biggest differentiator
4. **Large PDF is critical** - Enterprise requirement for most users
5. **Long-term planning** - Required for semester-based curricula

---

## 🚦 Readiness Checklist

### Phase 1 Complete When All Are ✅
- [ ] Settings screen with API configuration
- [ ] Unit tests running with 50%+ coverage
- [ ] Error handling working in all screens
- [ ] No crash when API is unavailable

### Phase 2 Complete When All Are ✅
- [ ] Video processing working
- [ ] Audio transcription working
- [ ] Large PDF (<50 pages) working without crash
- [ ] User can import any content type

### Phase 3 Complete When All Are ✅
- [ ] Large PDF (>300 pages) working
- [ ] Chapter/section detection working
- [ ] Search returns results in <100ms
- [ ] Notifications scheduled correctly

### Phase 4 Complete When All Are ✅
- [ ] Semester planner works
- [ ] Exam mode with timing simulation
- [ ] Milestone tracking active
- [ ] Offline mode functional

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-23  
**Next Review**: After Phase 1 completion
