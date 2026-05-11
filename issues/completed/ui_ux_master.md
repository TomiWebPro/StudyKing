# [UI/UX] Quick Guide is not discoverable and fails core chat accessibility/responsive patterns

## Context
`QuickGuideScreen` appears implemented as a standalone experience, but it is not wired into app navigation (`MainScreen` only exposes Subjects/Practice/Settings). Even if navigated to manually, the chat UI misses key accessibility and responsive interaction patterns expected for a production chat surface.

This creates a high-impact UX failure: users cannot reliably find the feature, and users with assistive needs or small screens have degraded interaction quality.

## Affected files
- `lib/features/quickguide/presentation/quick_guide_screen.dart`
- `lib/main.dart`
- `lib/features/features.dart`

## Why this is high-value
- **Confusing navigation / feature discoverability:** Quick Guide exists in code but has no clear entry point in primary navigation or routes.
- **Accessibility gaps:** The send `IconButton` has no tooltip/semantic label; typing state is plain text (not announced as live status); chat bubbles have no semantic role/metadata; message composer lacks accessible affordances beyond placeholder text.
- **Responsive/layout risk:** Input row is fixed at bottom without keyboard-safe behavior (no explicit `SafeArea`/inset handling around composer), creating potential overlap and cramped tap targets on small devices.
- **Design language inconsistency:** Chat surface uses ad-hoc bubble styling and status text that does not align with broader app information architecture (no section framing, no guidance actions, no empty/help state patterns used elsewhere).

## Acceptance criteria
1. Quick Guide is reachable through an intentional navigation path (primary nav, secondary nav, or clearly labeled settings/tools entry) that users can discover without prior knowledge.
2. Composer and message area remain fully usable on small screens and when keyboard is open (no clipped input/send action; adequate spacing and safe-area behavior).
3. Interactive controls in Quick Guide meet accessibility expectations:
   - Send action has semantic label/tooltip.
   - Input has explicit accessible label/hint (not placeholder-only reliance).
   - Typing/status updates are exposed in a screen-reader-friendly way.
4. Message bubbles and status UI follow app design patterns (spacing, typography scale, and color contrast) and are consistent in both light/dark themes.
5. Quick Guide UX includes a clear orientation state (e.g., suggested prompts or concise onboarding copy) so first-time users know what to do next.

## Notes for implementation
- Keep this as one UX pass: navigation discoverability + accessibility + responsive composer behavior should ship together to avoid exposing a partially usable feature.
