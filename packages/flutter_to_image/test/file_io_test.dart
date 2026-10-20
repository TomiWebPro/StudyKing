import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_to_image/flutter_to_image.dart';

/// PNG signature prefix so the synthetic bytes look like a real PNG header.
/// `savePng` itself does not validate PNG structure — it writes exactly the
/// bytes it is given — so this is only for realism; byte-exactness is what the
/// tests assert.
final Uint8List _pngLikeBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
]);

void main() {
  // Pure I/O unit tests (no widget rendering, no Hive) — kept in a plain
  // `test()` group per AGENTS.md (unit vs widget tests live in separate files).
  // A fresh system temp dir per test avoids touching the repo and isolates
  // each run.
  group('savePng', () {
    late Directory tmpRoot;

    setUp(() {
      tmpRoot = Directory.systemTemp.createTempSync('flutter_to_image_test_');
    });

    tearDown(() {
      if (tmpRoot.existsSync()) {
        tmpRoot.deleteSync(recursive: true);
      }
    });

    test('writes bytes to a new file and returns the path', () async {
      final path = '${tmpRoot.path}/out/expected.png';
      final returned = await savePng(_pngLikeBytes, path);

      expect(returned, path);
      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsBytesSync(), _pngLikeBytes);
    });

    test('creates nested parent directories recursively', () async {
      final path = '${tmpRoot.path}/issues/open/visual-foo_diff.png';
      await savePng(_pngLikeBytes, path);

      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsBytesSync(), _pngLikeBytes);
    });

    test('overwrites an existing file with new bytes', () async {
      final path = '${tmpRoot.path}/out/golden.png';
      await savePng(_pngLikeBytes, path);

      final newBytes = Uint8List.fromList([0x01, 0x02, 0x03]);
      await savePng(newBytes, path);

      expect(File(path).readAsBytesSync(), newBytes);
    });

    test('returns the path even when bytes are empty', () async {
      final path = '${tmpRoot.path}/out/empty.png';
      final returned = await savePng(Uint8List(0), path);

      expect(returned, path);
      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsBytesSync(), isEmpty);
    });

    test('throws StateError when path collides with an existing directory',
        () async {
      final dirPath = '${tmpRoot.path}/a_directory';
      Directory(dirPath).createSync(recursive: true);

      expect(
        () => savePng(_pngLikeBytes, dirPath),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ImageComparisonResult.saveDiff', () {
    late Directory tmpRoot;

    setUp(() {
      tmpRoot = Directory.systemTemp.createTempSync('flutter_to_image_test_');
    });

    tearDown(() {
      if (tmpRoot.existsSync()) {
        tmpRoot.deleteSync(recursive: true);
      }
    });

    test('writes diffPng to disk and returns the path', () async {
      final diffBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0xFF, 0x00, 0x00, 0xFF,
      ]);
      final result = ImageComparisonResult(
        matches: false,
        differingPixels: 3,
        totalPixels: 12,
        diffPng: diffBytes,
        width: 4,
        height: 3,
      );

      final path = '${tmpRoot.path}/diff.png';
      final returned = await result.saveDiff(path);

      expect(returned, path);
      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsBytesSync(), diffBytes);
    });

    test('produces a file identical to the in-memory diffPng', () async {
      final result = ImageComparisonResult(
        matches: false,
        differingPixels: 1,
        totalPixels: 4,
        diffPng: _pngLikeBytes,
        width: 2,
        height: 2,
      );

      final path = '${tmpRoot.path}/saved_diff.png';
      await result.saveDiff(path);

      expect(File(path).readAsBytesSync(), result.diffPng);
      expect(File(path).readAsBytesSync(), _pngLikeBytes);
    });
  });
}
