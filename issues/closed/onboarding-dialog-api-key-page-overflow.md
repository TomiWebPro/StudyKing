# Onboarding dialog API key page overflows by 14 pixels when expanded

**Severity:** minor
**Affected area:** Onboarding dialog — API key page
**Reported by:** user

## Description

When the user taps "What is an API key?" on the API key onboarding page, the expandable description is revealed, causing the content Column to overflow by 14 pixels. The Flutter rendering engine displays the overflow in yellow/black stripes at the bottom of the dialog content.

## Steps to reproduce

1. Fresh install (or reset onboarding) so the onboarding dialog appears.
2. Swipe or tap through to the "AI Configuration" page (4th page, with the key icon).
3. Tap the "What is an API key?" expandable row to reveal the description.
4. Observe the yellow/black overflow warning stripes at the bottom of the page.

## Expected behavior

All content on the API key page should fit within the available space without overflowing, even when the description text is expanded.

## Actual behavior

The Column at `lib/features/onboarding/presentation/onboarding_dialog.dart:229` overflows by 14 pixels on the bottom. The layout trace shows:

- Available height: 312px (360px PageView height minus 24px padding top and bottom)
- Total content height (when expanded): ~326px
- Overflow: 14px

## Code analysis

- `lib/features/onboarding/presentation/onboarding_dialog.dart:75` — The `PageView` has a fixed height of 360.
- `lib/features/onboarding/presentation/onboarding_dialog.dart:225-287` — The `_buildApiKeyPage` method creates a Column with fixed (non-scrollable) layout.
- `lib/features/onboarding/presentation/onboarding_dialog.dart:229` — The Column uses `MainAxisAlignment.center` and a fixed layout. When `_apiKeyExpanded` is true, the extra description text (`l10n.whatIsApiKeyDescription`, lines 273-283) is conditionally shown, pushing the total height beyond the available 312px.
- Height breakdown when expanded: Icon (80) + SizedBox (24) + Title (28) + SizedBox (12) + Notice text (48) + SizedBox (16) + Expand toggle (38) + Padding top (8) + Description bodySmall text (~72) = ~326px > 312px.

## Suggested approach

Several options:

1. **Make the page scrollable** — Wrap the Column content in a `SingleChildScrollView` so the user can scroll when the description expands. This is the cleanest fix.

2. **Reduce spacing** — Reduce the SizedBox heights to reclaim the needed 14+ pixels.

3. **Use a different layout for expanded state** — Instead of a Column with center alignment, use a `Spacer` or `Flexible` widgets to dynamically distribute space.

4. **Increase PageView height** — Increase the 360px height to accommodate the expanded content (e.g., 400px), though this may affect the dialog appearance on small screens.

Option 1 (scrollable) is recommended as it gracefully handles all possible text lengths and locales.
