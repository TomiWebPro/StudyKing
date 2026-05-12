You are building an application called StudyKing: a Flutter based all-in-one AI-native learning platform designed to maximize student learning efficiency and act as a complete long-term study companion.

This prompt describes the vision, not a rigid specification. The implementation details are intentionally incomplete. Your responsibility is to understand the intended product, challenge weak assumptions, improve poor designs, and continuously evolve the system into the best possible version of this vision. 

StudyKing should combine teaching, mentorship, planning, adaptive practice, content management, and student progress intelligence into one cohesive system.

The platform should deeply understand the student: what they are learning, what they struggle with, how much time they spend, what learning methods work best for them, and how their goals evolve over time.

At its core, StudyKing should maintain a structured knowledge system built around study content, lessons, questions, answers, attempts, schedules, student performance, and generated learning materials. AI-generated content should not be blindly trusted; correctness, consistency, and usefulness should be continuously validated and improved.

Students should be able to upload large amounts of study materials such as textbooks, PDFs, notes, question banks, syllabi, online video link, video/audio, online website link, screenshots, etc. The system should intelligently process, organize, classify, validate, and integrate this material into the broader learning system. If needed, more are to be generated and validated from online sources or the LLM itself. 

The question system is central to the product vision:
questions should be organized, categorized, linked to sources/topics/syllabi, expanded through generated variants, and used to measure understanding, identify weak areas, and drive adaptive revision. Student progress should be measurable directly from structured interactions with these questions.

The platform should support multiple forms of interaction:
- typed input
- voice conversation
- speech-to-text and text-to-speech
- multiple choice responses
- handwritten/drawn responses on canvas
- vision-based interpretation of student work
- rich rendering for mathematical and scientific content, including graphs and charts

StudyKing should contain two distinct AI interaction systems:

1. Teaching Mode (During lessons)
This is the active learning environment where AI functions as a true tutor.

Teaching mode should be conversational, not static. The student should be able to speak naturally with the AI tutor, ask follow-up questions, interrupt explanations, request clarification, and engage in real-time back-and-forth discussion through both text and voice.

The AI tutor should:
- dynamically generate the lesson plans and goals beforehand 
- teach concepts interactively
- explain ideas step-by-step
- adapt explanations to student understanding
- provide examples
- assign exercises and homework during and after class
- review student answers
- interpret handwritten work
- provide immediate corrective feedback
- guide problem solving rather than simply giving answers
- provide encouragement during lesson time
- respect the requested class hour
- keep a reord of chow the class went

Lessons may be structured, visual, slide-like, or interactive, but should always remain conversational and adaptive. 

2. Assistance / Mentor Mode (During off-periods)
This is the non-teaching companion layer.

This mode exists to support the student outside of lessons and should function more like an intelligent academic mentor, planner, and assistant.

This assistant should help with:
- scheduling lessons
- rescheduling classes
- planning long-term study goals
- creating or modifying study roadmaps
- motivation and encouragement
- accountability
- wellbeing support related to studying
- discussing workload
- helping decide what to study next
- receiving student suggestions or feedback about lessons
- adjusting study pacing
- creating new courses or subject plans
- modifying learning objectives 

This mode should NOT silently alter schedules or commitments without explicit user confirmation when important changes are involved.

This assistant should feel like a persistent mentor that understands the student’s history, habits, preferences, and academic goals.

Planning should be intelligent and long-term.

Example:
“I want to learn IB Physics in 180 days.”

The platform should:
- estimate realistic workload
- break longterm goals into manageable schedules
- generate lesson pathways
- assign practice
- adapt plans as progress changes
- track actual adherence vs intended schedule

Adaptive practice should be a major component:
the system should continuously test understanding, focus on weak areas, revisit old content intelligently, and optimize for retention and mastery rather than simple completion.

The platform should track:
- study hours by subject
- syllabus progress
- performance history
- lesson completion
- practice behavior
- weak/strong topic areas
- adherence to planned study schedules

The system should proactively engage students with reminders, prompts, revision nudges, lesson notifications, accountability messaging, and practice encouragement.

The system should allow student to learn and track from multiple syllabi simultainously. Lesson are for one syllabus. Lesson time and duration can be dynamically specified by the student. A relative remaining lesson count shoud be given by the system towards mastery, so not all lesson must be planned at once. System should nudge student to keep learning whilest prevent student from overworking and stress. 

The platform should support both local and remote AI providers, including systems such as OpenRouter, Ollama, and other compatible providers. It should remain model-agnostic. It should track LLM token usage for different tasks and have a task manager-like portal to view actively running inferencing task and for what purpose. 

The application should be responsive, polished, and production-quality across all screen sizes, localised prompt and strings for different world languages. 

Engineering expectations:
- maintainable architecture
- prioritise local app and cross platform
- exportable progress
- clean code quality
- zero unresolved analysis warnings/errors
- continuous improvement mindset

Most importantly:
do not treat this as a feature checklist.

Your objective is to build the strongest possible AI-native education platform consistent with this vision, even when that requires redesigning or extending ideas beyond this prompt. Your current task is already at the start of this prompt. 

DO NOT UNDER ANY CIRCUMSTANCE EDIT/DELETE THIS FILE. 
