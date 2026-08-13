# file_picker federated plugin warnings on Linux build

**Severity:** minor
**Affected area:** Build output / file_picker dependency
**Reported by:** user

## Description

When building and running the app on Linux, Flutter emits 9 repeated warnings about the `file_picker` package's federated plugin configuration:

```
Package file_picker:linux references file_picker:linux as the default plugin, but it does not provide an inline implementation.
Package file_picker:macos references file_picker:macos as the default plugin, but it does not provide an inline implementation.
Package file_picker:windows references file_picker:windows as the default plugin, but it does not provide an inline implementation.
```

The warnings are harmless — the app builds and runs successfully (`✓ Built build/linux/x64/debug/bundle/studyking`), and file picking works correctly via the native `file_selector_linux` plugin. However, the warnings clutter the build output and may cause confusion.

## Steps to reproduce

1. Run `flutter run` (or `flutter build linux`) on this project
2. Observe 9× repeated warnings about `file_picker:linux`, `file_picker:macos`, `file_picker:windows` default plugin references

## Expected behavior

A clean build output with no plugin configuration warnings.

## Actual behavior

9× warnings about missing inline implementations for `file_picker:linux`, `file_picker:macos`, `file_picker:windows`. The app still builds and runs correctly, and file picking works.

## Code analysis

Root cause: The `file_picker` package at version `^7.0.2` (declared in `pubspec.yaml:45`) has a flawed federated plugin configuration. Its `pubspec.yaml` declares platform-specific default packages (`file_picker:linux`, `file_picker:macos`, `file_picker:windows`) but does not provide corresponding inline implementations (`pluginClass` or `dartPluginClass`) for those platforms. This is an upstream package issue.

The Linux platform uses `file_selector_linux` as the actual native implementation:
- `linux/flutter/generated_plugins.cmake` — lists `file_selector_linux` (not `file_picker`)
- `linux/flutter/generated_plugin_registrant.cc` — registers `FileSelectorPlugin`

There are no `macos/` or `windows/` directories in this project (Linux-only target), so those warnings are doubly irrelevant.

## Suggested approach

Several options to suppress the warnings:

1. **Upgrade file_picker** — Check if a newer version of `file_picker` (e.g., 8.x) has fixed the federated plugin configuration. Update the version constraint in `pubspec.yaml:45`.

2. **Pin to a stable version** — Pin `file_picker` to a version known not to have this issue (e.g., 6.x series as referenced in `pubspec_override.txt`).

3. **Ignore the warnings** — Since the warnings are cosmetic and do not affect functionality, document them as known non-issues and ignore.

4. **File upstream issue** — Report the problem to the `file_picker` package maintainers so they can fix their federated plugin declaration.

Option 1 (upgrade) is preferred if a compatible newer version exists. Option 3 is acceptable if no better version is available.
