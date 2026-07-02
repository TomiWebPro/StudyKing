# Quick Guide Feature

## Overview

The Quick Guide provides an AI-powered conversational assistant accessible from anywhere in the app. It acts as a lightweight tutor using streaming LLM responses, suggested prompts, study mode navigation, and conversation memory.

## Key Files

| Layer | Files |
|---|---|
| Screens | `QuickGuideScreen` |
| Widgets | `ModeNavigationWidget`, `SuggestedPromptsWidget`, `MessageListWidget`, `QuickGuideHelpDialog` |

## Core Services

The Quick Guide screen depends on `LlmService` (from core) for streaming chat completions. It uses `ConversationMemory` for context retention within a session.

## Key Widgets

| Widget | Purpose |
|---|---|
| `QuickGuideScreen` | Main screen with chat interface, streaming responses, prompt suggestions, and mode navigation |
| `ModeNavigationWidget` | Displays study mode cards (Practice, Lessons, Mentor, Planner, Focus) for quick navigation to other features |
| `SuggestedPromptsWidget` | Displays 3 contextual prompt chips (Explain, Quiz, Math) that auto-fill and send when tapped |
| `MessageListWidget` | Renders conversation messages using `ChatBubble` widgets with scrolling |
| `QuickGuideHelpDialog` | Alert dialog explaining the Quick Guide feature |

## Usage Flow

1. **Initial State:** The screen shows a welcome message from the tutor, a mode navigation bar, and 3 suggested prompts
2. **API Key Check:** If no API key is configured, a warning banner is shown with a link to the API config screen
3. **User Input:** User types a message or taps a suggested prompt
4. **Streaming Response:** The message is sent to the LLM via `chatStream()`; tokens are streamed into a placeholder message bubble with real-time updates
5. **Fallback:** If the LLM call fails, a local fallback response is generated based on keywords (explain/quiz/math)
6. **Memory:** Messages are stored in `ConversationMemory` for context in follow-up turns
7. **Clear Conversation:** User can tap the refresh button to reset the conversation and memory
8. **Navigation:** Mode cards navigate to their respective feature screens

## Key UI Features

- **Streaming chat bubbles** with real-time token display
- **Reduce motion support** for scroll animations
- **Semantic labels** for accessibility on all interactive elements
- **Responsive layout** adapting mode cards for mobile vs tablet
