# Profile avatar picker UI needs complete redesign

**Severity:** major
**Affected area:** Profile screen — avatar selection UI
**Reported by:** user

## Description

The avatar picker bottom sheet on the Profile screen has multiple visual and layout issues. The avatar choice icons are cramped/smashed together, left-aligned instead of centered, and the overall appearance is not visually appealing. The widget composition (`ChoiceChip` with `avatar: CircleAvatar(...)` and `label: SizedBox.shrink()`) misuses Material Design APIs, resulting in broken rendering and poor UX. A complete redesign of the picker is requested.

## Steps to reproduce

1. Open the app and navigate to the Profile screen.
2. Tap on the avatar circle to open the avatar picker bottom sheet.
3. Observe the layout of the avatar choice icons.

## Expected behavior

- The avatar picker should display icon options in a visually appealing, centered grid or wrap layout with adequate spacing.
- Each avatar option should be clearly tappable with proper visual feedback (size, padding, selection state).
- The picker should feel polished and consistent with the rest of the app's design.
- Alignment should be centered, not left-flushed.

## Actual behavior

- Icons appear "smushed together" (insufficient visual breathing room between choices).
- The layout is left-aligned, creating an unbalanced, lopsided look.
- The `ChoiceChip` widgets render awkwardly — they combine a `CircleAvatar` (meant for user photos/initials) with an empty `SizedBox.shrink()` label, which breaks the chip's intrinsic layout.
- `visualDensity: VisualDensity.compact` compresses the chips further.
- `showCheckmark: false` removes selection feedback, so the user has no visual cue of which avatar is currently selected when re-opening the picker.
- The `Wrap` widget defaults to `WrapAlignment.start`, pushing all icons to the left.

## Code analysis

### Root cause 1: Misuse of `ChoiceChip` API
**File:** `lib/features/settings/presentation/profile_screen.dart:228-238`

```dart
ChoiceChip(
  avatar: CircleAvatar(child: Icon(icon)),
  label: const SizedBox.shrink(),        // <-- label is required but empty
  selected: isSelected,
  onSelected: (_) { ... },
  visualDensity: VisualDensity.compact,   // <-- compresses already broken layout
  showCheckmark: false,                   // <-- removes selection visual cue
),
```

The `ChoiceChip.label` parameter is **required** — it is the primary content area. Setting it to `SizedBox.shrink()` means the chip has zero content width in its label slot. The `avatar` parameter is designed as a **leading** decoration alongside a text label, not as the sole content. This combination causes the chip to render as a misshapen, cramped circle-within-a-rectangle with no identifiable bounds.

### Root cause 2: Left-aligned `Wrap`
**File:** `lib/features/settings/presentation/profile_screen.dart:169`

```dart
Wrap(
  spacing: 12,
  runSpacing: 12,
  // no alignment specified → defaults to WrapAlignment.start
  children: [ ... ],
),
```

Without an explicit `alignment`, Flutter's `Wrap` defaults to `WrapAlignment.start`, pushing all items to the leading edge. For a grid of icons in a bottom sheet, `WrapAlignment.center` (or `spaceEvenly`) would be more appropriate.

### Root cause 3: Misuse of `CircleAvatar`
**File:** `lib/features/settings/presentation/profile_screen.dart:229`

`CircleAvatar` is a Material widget designed for user profile images and initials (it clips to a circle and applies a background color). Using it solely to wrap a Material `Icon` widget is semantically incorrect and adds unnecessary circular clipping and padding on top of what the `ChoiceChip` already provides.

### Root cause 4: Only 8 hardcoded icon choices
**File:** `lib/features/settings/presentation/profile_screen.dart:173-181`

The limited set of 8 icons (`Icons.face`, `Icons.person`, `Icons.school`, `Icons.local_hospital`, `Icons.leaderboard`, `Icons.emoji_events`, `Icons.sports_tennis`, `Icons.coffee`) is functional but not visually inspiring. A redesign should consider more icons and/or a richer visual treatment.

## Suggested approach

Completely replace the avatar picker UI with a properly designed component. Options:

### Option A: Grid of styled icon containers (recommended)
Replace the `ChoiceChip`-based picker with a `Wrap` or `GridView` of simple, well-styled icon containers:

```dart
GridView.count(
  crossAxisCount: 4,
  shrinkWrap: true,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  children: avatarOptions.map((entry) {
    final isSelected = _avatarIconKey == entry.key;
    return GestureDetector(
      onTap: () {
        setState(() => _avatarIconKey = entry.key);
        Navigator.pop(context);
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 2.5)
              : null,
        ),
        child: Icon(
          entry.value,
          size: 32,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }).toList(),
)
```

This approach:
- Uses simple `Container` circles with icons (no `ChoiceChip`/`CircleAvatar` misuse).
- Centered by default inside a `Center` or with `WrapAlignment.center`.
- Shows clear selection state via color and border.
- Has adequate spacing and proper tap targets.

### Option B: Expand icon set
Increase the avatar icon pool to 16–24 options for more personalization. Consider categorizing them (animals, objects, symbols, etc.).

### Key changes needed in `lib/features/settings/presentation/profile_screen.dart`:
1. Replace `_pickAvatar()` bottom sheet layout (lines 152–193) — use `Wrap(alignment: WrapAlignment.center)` with properly padded icon containers.
2. Replace `_buildAvatarChoice()` (lines 195–240) — remove `ChoiceChip`/`CircleAvatar` misuse.
3. Update `_getIconFromAvatar()` (lines 249–270) if the icon set changes.
4. Ensure the avatar preview circle (lines 336–364) remains consistent with the new picker design.

### Files to modify:
- `lib/features/settings/presentation/profile_screen.dart` — primary redesign target
- `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` — if new accessibility strings are needed
- `test/features/settings/presentation/profile_screen_test.dart` — update avatar picker tests to reflect new layout
