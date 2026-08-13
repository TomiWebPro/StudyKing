# Lessons: Enhance Slides/Presentation Mode for Structured Lesson Delivery

**Severity:** minor
**Affected area:** Teaching Mode — Lesson Presentation
**Reported by:** codebase audit

## Description

The vision document specifies that lessons should be "structured, visual, slide-like, or interactive" with the ability to deliver "PPT-like structured guides." The current slides mode in the Tutor Screen (`tutor_screen.dart`) is a basic `PageView` of `LessonBlockCard` widgets — it lacks professional presentation features:

1. **No slide transitions** — Pages snap without animation
2. **No slide notes** — No presenter notes or speaker notes
3. **No full-screen mode** — Slides are displayed within the chat UI, not full-screen
4. **No content zoom** — No pinch-to-zoom for diagrams or equations
5. **No progress indicators** — Students don't know how many slides remain or their overall lesson progress
6. **No slide thumbnails** — No overview or navigation grid
7. **No embedded media** — No video, audio, or interactive elements within slides
8. **No slide reordering** — The lesson plan order is fixed, cannot be adjusted on-the-fly

## Steps to reproduce

1. Start a tutor session
2. Toggle to slides view using the slides button
3. Observe: basic card-flip interface with no presentation polish

## Expected behavior

The slides mode should be a polished presentation experience:
- Smooth slide transitions (slide, fade, zoom)
- Full-screen mode with a dedicated presentation controller
- Slide counter with total count
- Thumbnail grid for jumping between slides
- Pinch-to-zoom on content
- Embedded media support (video players, interactive elements)
- Speaker notes for the tutor (not visible to student)

## Actual behavior

Basic PageView with no presentation features.

## Code analysis

- `lib/features/teaching/presentation/tutor_screen.dart:1114-1168` — `_buildSlidesView()` renders `PageView` of `LessonBlockCard`
- `lib/features/lessons/presentation/widgets/lesson_block_card.dart` — Individual slide card with basic layout
- `lib/features/teaching/presentation/widgets/lesson_progress_bar.dart` — Currently shows section timeline, not slide count

## Suggested approach

1. **Create a dedicated `SlidesPresentationWidget`** that wraps a `PageController` with:
   - Slide transition animations (curved, fade, zoom) using `PageView` with custom `PageController` + `AnimatedBuilder`
   - Full-screen toggle (enter/exit full-screen mode via `SystemChrome.setEnabledSystemUIMode`)
   - Slide counter badge ("Slide 5 of 12")
   - Thumbnail grid (tap to show a grid of all slides for quick navigation)

2. **Enhance `LessonBlockCard`** with:
   - Pinch-to-zoom via `InteractiveViewer`
   - Embedded video player for video content
   - Audio playback for audio content
   - Math rendering (see separate issue on math rendering)

3. **Add slide navigation controls**:
   - Swipe left/right to navigate
   - Keyboard arrows (for desktop)
   - On-screen prev/next buttons
   - Slide number input (jump to specific slide)

4. **Preserve slide state** — Remember which slide the student was on if they switch back to chat mode

5. **Support slide reordering** — Allow the AI tutor to dynamically reorder slides based on student understanding (e.g., skip a slide the student already mastered, repeat a slide they struggled with)
