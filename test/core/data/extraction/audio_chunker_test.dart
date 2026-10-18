import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/extraction/audio_chunker.dart';

/// MPEG-1 Layer III, 128 kbps, 44100 Hz frame header.
/// Frame size = 144 * 128000 / 44100 = 417 bytes; 1152 samples/frame.
const _kMp3FrameSize = 417;
const _kMp3SamplesPerFrame = 1152;
const _kMp3SampleRate = 44100;
const _kMp3Header = [0xFF, 0xFB, 0x90, 0x00];

Uint8List _buildSyntheticMp3(int numFrames) {
  final bytes = Uint8List(numFrames * _kMp3FrameSize);
  for (var f = 0; f < numFrames; f++) {
    final off = f * _kMp3FrameSize;
    bytes[off] = _kMp3Header[0];
    bytes[off + 1] = _kMp3Header[1];
    bytes[off + 2] = _kMp3Header[2];
    bytes[off + 3] = _kMp3Header[3];
  }
  return bytes;
}

Uint8List _packLe(int value, int width) {
  return Uint8List.fromList(
    List<int>.generate(width, (i) => (value >> (8 * i)) & 0xFF),
  );
}

/// Builds a canonical PCM WAV (RIFF/WAVE/fmt/data) with [dataBytes] of audio.
Uint8List _buildSyntheticWav({
  required int dataBytes,
  int sampleRate = 44100,
  int channels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  final blockAlign = channels * (bitsPerSample ~/ 8);
  final fmt = Uint8List(16)
    ..setRange(0, 2, _packLe(1, 2)) // audioFormat = 1 (PCM)
    ..setRange(2, 4, _packLe(channels, 2))
    ..setRange(4, 8, _packLe(sampleRate, 4))
    ..setRange(8, 12, _packLe(byteRate, 4))
    ..setRange(12, 14, _packLe(blockAlign, 2))
    ..setRange(14, 16, _packLe(bitsPerSample, 2));

  final bb = BytesBuilder();
  bb.add(Uint8List.fromList([0x52, 0x49, 0x46, 0x46])); // RIFF
  bb.add(_packLe(4 + fmt.length + 8 + dataBytes, 4)); // file size
  bb.add(Uint8List.fromList('WAVE'.codeUnits));
  bb.add(Uint8List.fromList([0x66, 0x6D, 0x74, 0x20])); // fmt
  bb.add(_packLe(fmt.length, 4));
  bb.add(fmt);
  bb.add(Uint8List.fromList([0x64, 0x61, 0x74, 0x61])); // data
  bb.add(_packLe(dataBytes, 4));
  bb.add(Uint8List(dataBytes)); // silence
  return Uint8List.fromList(bb.toBytes());
}

int _indexOf(Uint8List bytes, List<int> needle, [int start = 0]) {
  outer:
  for (var i = start; i + needle.length <= bytes.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// Reads a little-endian unsigned int of [width] bytes at [offset].
int _le(Uint8List b, int offset, int width) {
  var v = 0;
  for (var i = 0; i < width; i++) {
    v |= (b[offset + i] & 0xFF) << (8 * i);
  }
  return v;
}

double _mp3Duration(int frames) => frames * _kMp3SamplesPerFrame / _kMp3SampleRate;

void main() {
  group('AudioChunker detection', () {
    test('detects MP3 by leading frame sync', () {
      final chunker = AudioChunker();
      final result = chunker.chunk(_buildSyntheticMp3(5));
      expect(result.isSuccess, isTrue);
    });

    test('detects WAV by RIFF header', () {
      final chunker = AudioChunker();
      final result = chunker.chunk(_buildSyntheticWav(dataBytes: 1024));
      expect(result.isSuccess, isTrue);
    });

    test('fails loud on unsupported data', () {
      final chunker = AudioChunker();
      final result = chunker.chunk(Uint8List.fromList(List.filled(256, 0xAB)));
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('Unsupported audio format'));
    });

    test('fails loud on empty input', () {
      final chunker = AudioChunker();
      final result = chunker.chunk(Uint8List(0));
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });
  });

  group('AudioChunker MP3 chunking', () {
    test('splits into frame-boundary chunks, preserving every frame', () {
      // 300 frames (~7.84s) at 2s target → 4 chunks.
      final bytes = _buildSyntheticMp3(300);
      final chunker = AudioChunker(targetSeconds: 2);
      final result = chunker.chunk(bytes);

      expect(result.isSuccess, isTrue);
      final chunks = result.chunks;
      expect(chunks.length, 4);

      var totalFrames = 0;
      var totalDuration = 0.0;
      for (final chunk in chunks) {
        // Every chunk starts on a frame boundary → valid MP3 sync.
        expect(chunk.bytes[0], 0xFF);
        expect(chunk.bytes[1] & 0xE0, 0xE0);
        expect(chunk.bytes.length % _kMp3FrameSize, 0);
        totalFrames += chunk.bytes.length ~/ _kMp3FrameSize;
        totalDuration += chunk.durationSeconds;
      }
      expect(totalFrames, 300);
      expect(totalDuration, closeTo(_mp3Duration(300), 0.01));
      expect(result.estimatedDurationSeconds, closeTo(_mp3Duration(300), 0.01));
    });

    test('each chunk is a valid MP3 (starts with sync, ends on frame boundary)',
        () {
      final bytes = _buildSyntheticMp3(200);
      final chunker = AudioChunker(targetSeconds: 2);
      final result = chunker.chunk(bytes);

      expect(result.chunks.length, greaterThan(1));
      for (final chunk in result.chunks) {
        expect(
          chunk.bytes[0] == 0xFF && (chunk.bytes[1] & 0xE0) == 0xE0,
          isTrue,
        );
        expect(chunk.bytes.last & 0xE0, isNot(0xE0));
      }
    });

    test('a single short file yields one chunk', () {
      final bytes = _buildSyntheticMp3(10);
      final chunker = AudioChunker(targetSeconds: 30);
      final result = chunker.chunk(bytes);

      expect(result.chunks, hasLength(1));
      expect(result.chunks.single.bytes.length, 10 * _kMp3FrameSize);
    });

    test('skips a leading ID3v2 tag before chunking frames', () {
      // 10-byte ID3v2 header + 42-byte tag body, then 30 real frames.
      final id3 = Uint8List(10)
        ..[0] = 0x49
        ..[1] = 0x44
        ..[2] = 0x33
        ..[3] = 3;
      const tagSize = 42;
      id3[6] = (tagSize >> 21) & 0x7F;
      id3[7] = (tagSize >> 14) & 0x7F;
      id3[8] = (tagSize >> 7) & 0x7F;
      id3[9] = tagSize & 0x7F;
      final header = id3;
      final body = Uint8List(tagSize);
      final frames = _buildSyntheticMp3(30);
      final combined = Uint8List.fromList(
        header + body + frames,
      );

      final chunker = AudioChunker(targetSeconds: 30);
      final result = chunker.chunk(combined);

      expect(result.isSuccess, isTrue);
      for (final chunk in result.chunks) {
        expect(chunk.bytes[0], 0xFF);
      }
      final totalFrames = result.chunks
          .fold(0, (s, c) => s + c.bytes.length ~/ _kMp3FrameSize);
      expect(totalFrames, 30);
    });
  });

  group('AudioChunker WAV chunking', () {
    test('splits into sample-boundary WAV chunks', () {
      // 3s of mono 16-bit 44100Hz PCM = 3 * 88200 bytes.
      const sampleRate = 44100;
      const channels = 1;
      const byteRate = 88200;
      const dataBytes = byteRate * 3;
      final bytes = _buildSyntheticWav(
        dataBytes: dataBytes,
        sampleRate: sampleRate,
        channels: channels,
      );

      final chunker = AudioChunker(targetSeconds: 1);
      final result = chunker.chunk(bytes);

      expect(result.isSuccess, isTrue);
      expect(result.chunks.length, 3);
      var totalData = 0;
      for (final chunk in result.chunks) {
        expect(chunk.bytes.sublist(0, 4), [0x52, 0x49, 0x46, 0x46]); // RIFF
        expect(chunk.bytes.sublist(8, 12), [0x57, 0x41, 0x56, 0x45]); // WAVE
        final dataTagIdx = _indexOf(chunk.bytes, [0x64, 0x61, 0x74, 0x61]);
        expect(dataTagIdx, greaterThan(0));
        totalData += _le(chunk.bytes, dataTagIdx + 4, 4);
        expect(chunk.durationSeconds, closeTo(1.0, 0.01));
      }
      expect(totalData, dataBytes);
      expect(result.estimatedDurationSeconds, closeTo(3.0, 0.01));
    });

    test('produces one WAV chunk for short input', () {
      final bytes = _buildSyntheticWav(dataBytes: 1024);
      final chunker = AudioChunker(targetSeconds: 30);
      final result = chunker.chunk(bytes);

      expect(result.chunks, hasLength(1));
      expect(result.chunks.single.bytes.sublist(0, 4), [0x52, 0x49, 0x46, 0x46]);
    });
  });

  group('AudioChunker fail-loud paths', () {
    test('random bytes with no audio header fails loud with estimate', () {
      final chunker = AudioChunker();
      final result = chunker.chunk(Uint8List.fromList(List.filled(256, 0x5A)));
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.estimatedDurationSeconds, greaterThan(0));
    });
  });
}
