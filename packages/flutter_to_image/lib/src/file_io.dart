import 'dart:io';
import 'dart:typed_data';

/// Writes [pngBytes] to [path] on disk and returns [path].
///
/// Supports the `docs/vision_next_term.md` §1.1 "agent loop" workflow where
/// visual diffs (expected / actual / diff PNGs) produced by [compareImages] /
/// [renderWidgetToPng] are persisted so they can be attached to issues for
/// review — "expected vs actual PNG + diff" (see `docs/development/visual-testing.md`).
///
/// The parent directory is created recursively if it does not already exist.
/// Returns [path] on success. Throws [StateError] if the bytes cannot be
/// written (e.g. [path] collides with an existing directory, or the location is
/// not writable).
///
/// The write itself is performed synchronously with `dart:io` [`File`] APIs so
/// it is unaffected by the `flutter_test` `FakeAsync` clock — callers may `await`
/// this function inside `testWidgets` without wrapping it in `runAsync`, and it
/// is also safe to call from non-test tooling. It is intended for `flutter test`
/// (VM) and dev-tooling contexts — `dart:io` is not available on the web, so this
/// helper is not for release app code.
///
/// ```dart
/// final path = await savePng(renderedBytes, 'issues/open/visual-foo_actual.png');
/// ```
Future<String> savePng(Uint8List pngBytes, String path) async {
  try {
    final file = File(path);
    file.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes, flush: true);
    return path;
  } catch (e) {
    throw StateError('flutter_to_image: failed to write PNG to $path: $e');
  }
}
