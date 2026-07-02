# Quick Guide shows raw markdown link text when no API key configured

**Severity:** minor
**Affected area:** Quick Guide screen / AI Mentor
**Reported by:** user

## Description

When the user has no API key configured and tries to send a message in the Quick Guide (AI Mentor), the app displays the message "Please configure your API key first." followed by the raw markdown link syntax `[Configure Now](/settings/api-config)` rendered literally as text. The `Text` widget used in `ChatBubble` does not parse markdown, so the user sees the raw `[Configure Now](/settings/api-config)` string instead of a clickable link.

## Steps to reproduce

1. Open the Quick Guide / AI Mentor screen
2. Ensure no API key is configured
3. Type any message and send it
4. Observe the response — the raw markdown `[Configure Now](/settings/api-config)` is displayed as plain text

## Expected behavior

The message should either:
- Show only the polite instruction text without the broken markdown link, OR
- Show a properly rendered clickable link (but this would require markdown rendering in ChatBubble)

The preferred approach is to simply remove the markdown link text, since a working "Configure Now" button already exists in the API key banner at the top of the screen.

## Actual behavior

The chat bubble shows:
```
Please configure your API key first.

[Configure Now](/settings/api-config)
```

The `[Configure Now](/settings/api-config)` part is raw markdown syntax rendered literally as text, which looks broken and unprofessional.

## Code analysis

- `lib/features/quickguide/presentation/quick_guide_screen.dart:209` — The `_showNoApiKeyMessage` method constructs the message content with:
  ```dart
  content: '${l10n.pleaseConfigureApiKey}\n\n[${l10n.configureNow}](/settings/api-config)',
  ```
  
- `lib/features/teaching/presentation/widgets/chat_bubble.dart:130-137` — The `ChatBubble._buildContent` method renders message content using a plain `Text` widget, which does not parse markdown syntax.

- `lib/features/quickguide/presentation/quick_guide_screen.dart:349-378` — The `_buildApiKeyBanner` method already provides a working `TextButton` that navigates to the API config screen via `Navigator.pushNamed(context, AppRoutes.apiConfig)`, making the broken markdown link in the chat redundant.

## Suggested approach

Remove the `\n\n[${l10n.configureNow}](/settings/api-config)` suffix from the content string on line 209 of `quick_guide_screen.dart`, so the message content is simply:
```dart
content: l10n.pleaseConfigureApiKey,
```

The banner at the top of the screen already provides the navigation to settings. Alternatively, if a clickable link is desired in the chat, a markdown-aware widget (like `flutter_markdown`) would need to be introduced in `ChatBubble`.
