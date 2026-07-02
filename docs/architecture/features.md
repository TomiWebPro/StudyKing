# Features Overview

## Dashboard

The student's home screen showing an overview of their learning journey.

- **Stats summary:** Total study hours, questions answered, mastery %, adherence rate
- **Mastery progress:** Overall mastery and per-subject breakdown
- **Weak areas:** Topics needing attention, at-risk questions
- **Next up:** Scheduled lessons and pending reviews
- **Plan adherence:** Chart showing planned vs actual study time
- **Weekly chart:** Study time distribution across the week
- **Badges:** Achievements earned
- **Workload estimate:** Remaining workload to reach goals
- **Due reviews:** Spaced repetition items due for review
- **Export:** Progress data export functionality

## Planner

Long-term study planning and scheduling system.

- **Study plans:** Create plans like "Learn IB Physics in 180 days"
- **Roadmaps:** Milestone-based learning pathways
- **Scheduling:** Book lessons, manage availability
- **Adherence tracking:** Planned vs actual study time comparison
- **Pending actions:** Action items from the mentor
- **Syllabus progress:** Track progress across multiple syllabi simultaneously
- **Pace adjustment:** Auto-adjust schedule based on actual progress
- **LLM advisor:** AI-powered planning suggestions

## Practice & Spaced Repetition

Adaptive question practice and spaced repetition engine.

- **Practice modes:** Free practice, spaced repetition review, exam simulation
- **Spaced repetition engine:** SM-2 inspired algorithm for optimal review timing
- **Question types:** Multiple choice, written, voice, drawing
- **Mastery tracking:** Per-question and per-topic mastery states
- **Confidence rating:** Student self-assessment during practice
- **Mistake review:** Review and learn from incorrect answers
- **Readiness scoring:** Pre-session readiness assessment
- **Weak area focus:** Targeted practice on identified weak topics

## Teaching / Tutor Mode

Interactive AI-powered tutoring within structured lessons.

- **Lesson plans:** AI generates lesson plans with objectives and structure
- **Interactive teaching:** Conversational AI tutor with real-time back-and-forth
- **Content blocks:** Lesson materials with explanations, examples, exercises
- **Exercise evaluation:** AI evaluates student answers and provides feedback
- **Progress tracking:** Lesson completion, time tracking, topic mastery updates
- **Voice support:** Speech-to-text and text-to-speech for natural interaction
- **Session management:** Orphaned session detection and cleanup

## Mentor Mode

AI companion that helps outside of lesson time.

- **Natural conversation:** Chat-based AI assistant
- **Scheduling:** Book and reschedule lessons
- **Planning support:** Help create and modify study plans
- **Motivation:** Encouragement and accountability messaging
- **Wellbeing:** Detect stress/overwork and suggest breaks
- **Engagement nudges:** Proactive reminders and prompts
- **Context-aware:** Understands student history, habits, and goals
- **Tool-based actions:** Create plans, generate lesson blocks, search questions

## Subjects & Topics

Knowledge organization and curriculum management.

- **Subjects:** Create and manage subjects/courses
- **Topics:** Hierarchical topic trees within subjects
- **Topic dependencies:** Prerequisite relationships between topics
- **Progress tracking:** Per-topic mastery and completion stats
- **Curriculum seed data:** Pre-populated curriculum templates
- **Multi-syllabus:** Learn and track multiple syllabi simultaneously

## Questions

Central question management system.

- **Question bank:** Browse, search, and manage all questions
- **Rich content:** Math expressions, graphs, diagrams, code blocks
- **Answer modes:** Text, multiple choice, voice, drawing, file upload
- **Mark schemes:** Grading rubrics for evaluation
- **Question generation:** AI-generated question variants
- **Source linking:** Questions linked to study materials

## Content Ingestion

Upload and process study materials.

- **File upload:** PDFs, images, documents
- **Web scraping:** Extract content from URLs
- **OCR:** Optical character recognition from images
- **Transcription:** Audio/video transcription
- **Content pipeline:** Extract → Chunk → Classify → Store
- **Source management:** Library of processed study materials

## Focus Mode

Deep work / Pomodoro-style timer.

- **Focus timer:** Configurable study sessions with breaks
- **Inline practice:** Quick practice during focus sessions
- **Session tracking:** History of focus sessions
- **Subject linking:** Associate sessions with subjects/topics

## Settings & Profile

User configuration and preferences.

- **AI configuration:** API keys, provider selection, model settings
- **Profile:** Student name, language, preferences
- **Accessibility:** Font size, bold text, high contrast, reduce motion
- **Theme:** Light/dark/system theme mode
- **Data backup:** Export and restore all local data

## LLM Task Manager

Portal for monitoring AI inference tasks.

- **Active tasks:** View running LLM operations
- **Token usage:** Track token consumption per feature/model
- **Cost estimation:** Monitor estimated API costs
- **Task history:** Completed and failed task logs

## Onboarding

First-run experience that introduces new users to the app.

- **Guided introduction:** Multi-page dialog explaining each major feature
- **API key setup:** Inline configuration step for AI providers
- **Completion tracking:** Marks onboarding as complete to avoid repeats
- **First-launch detection:** Checks onboarding state before showing the dialog

## Quick Guide

In-app help and suggested prompts for interacting with the AI mentor.

- **Mode navigation:** Quick toggles between mentor, teaching, and practice modes
- **Suggested prompts:** Pre-written questions to help users get started
- **Message list:** Rendered conversation history within the guide
- **Help dialog:** Context-sensitive assistance

## Sessions

Study session tracking across all activities.

- **Session history:** Complete log of all study sessions
- **Session analytics:** Time breakdowns by subject/activity
- **Study timer:** Manual session timing
- **Data export:** Export session data for external analysis
