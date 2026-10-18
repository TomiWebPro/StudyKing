import 'dart:typed_data';

/// Audio containers the chunker knows how to split safely.
enum AudioContainer { mp3, wav, unknown }

/// One frame-aware chunk.
///
/// [bytes] is a self-contained, decodable audio fragment — a run of whole
/// MP3 frames, or a complete WAV file with its own RIFF header — so that no
/// codec-framing is broken at chunk boundaries. [durationSeconds] is the real
/// audio length of the chunk.
class AudioChunk {
  final Uint8List bytes;
  final double durationSeconds;

  const AudioChunk(this.bytes, this.durationSeconds);
}

/// Outcome of frame-aware chunking.
class AudioChunkResult {
  final List<AudioChunk> chunks;
  final String? errorMessage;
  final double? estimatedDurationSeconds;

  const AudioChunkResult({
    this.chunks = const [],
    this.errorMessage,
    this.estimatedDurationSeconds,
  });

  /// True when at least one valid chunk was produced.
  bool get isSuccess => errorMessage == null && chunks.isNotEmpty;
}

/// Splits an audio byte buffer into frame-aware chunks so each chunk is a valid,
/// self-contained audio file.
///
/// This fixes the byte-split bug in chunked transcription, where cutting a
/// compressed stream (MP3) at an arbitrary byte offset produces chunks whose
/// non-first members lack codec framing — they are rejected or mis-transcribed
/// by the ASR backend, yielding partial/empty transcripts for long lectures.
///
/// Supported containers:
///  - MP3: scans for valid MPEG frame syncs and cuts only on frame boundaries.
///  - WAV: parses the `fmt`/`data` chunks and splits at sample-boundary
///    offsets, re-emitting a complete RIFF header per chunk.
///
/// Any other container (or an MP3 with no decodable frames) returns a
/// fail-loud [AudioChunkResult] with a guidance message and a best-effort
/// duration estimate, instead of producing broken chunks.
class AudioChunker {
  /// Target duration of each chunk in seconds.
  final int targetSeconds;

  const AudioChunker({this.targetSeconds = 30});

  AudioChunkResult chunk(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const AudioChunkResult(errorMessage: 'Audio data is empty');
    }
    final container = _detectContainer(bytes);
    switch (container) {
      case AudioContainer.mp3:
        return _chunkMp3(bytes);
      case AudioContainer.wav:
        return _chunkWav(bytes);
      case AudioContainer.unknown:
        return AudioChunkResult(
          errorMessage: 'Unsupported audio format for chunked transcription; '
              'convert to MP3 or WAV, or split the recording into shorter segments.',
          estimatedDurationSeconds: _estimateDurationFromSize(bytes),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Container detection
  // ---------------------------------------------------------------------------

  static AudioContainer _detectContainer(Uint8List b) {
    // Skip a leading ID3v2 tag (common on real MP3 files) so detection and
    // frame scanning start at the first real audio frame.
    int start = 0;
    if (_startsWith(b, 0, 'ID3') && b.length >= 10) {
      final tagSize = _id3v2Size(b, 0);
      if (tagSize != null) start = 10 + tagSize;
    }

    if (start + 4 <= b.length && _parseMp3Frame(b, start) != null) {
      return AudioContainer.mp3;
    }
    if (b.length >= 12 && _startsWith(b, 0, 'RIFF') && _startsWith(b, 8, 'WAVE')) {
      return AudioContainer.wav;
    }
    return AudioContainer.unknown;
  }

  static int? _id3v2Size(Uint8List b, int offset) {
    // Flags byte (offset+1) may set a 10-byte header extension; the synchsafe
    // size in bytes [offset+6..9] gives the body length after the 10-byte
    // header. We ignore extended/footer flags for chunk boundary purposes: the
    // frame scanner will skip any remaining header bytes it can't parse.
    var size = 0;
    for (var i = 0; i < 4; i++) {
      size = (size << 7) | (b[offset + 6 + i] & 0x7F);
    }
    return size.isFinite ? size : null;
  }

  static bool _startsWith(Uint8List b, int offset, String ascii) {
    for (var i = 0; i < ascii.length; i++) {
      if (offset + i >= b.length || b[offset + i] != ascii.codeUnitAt(i)) {
        return false;
      }
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // MP3 frame-aware chunking
  // ---------------------------------------------------------------------------

  /// Bitrate (kbps) for a given MPEG version (3=MPEG-1, 1=MPEG-2, 0=MPEG-2.5),
  /// layer (3=Layer I, 2=Layer II, 1=Layer III) and bitrate index (1..13).
  /// Tables are the canonical MPEG bitrate tables (index 0 = free, 15 = illegal;
  /// both return 0 so such headers are rejected as undecodable).
  static int _bitrateKbps(int version, int layer, int idx) {
    if (idx == 0 || idx == 0xF) return 0;
    const l1 = [32, 48, 64, 96, 128, 160, 192, 224, 256, 320, 384, 448];
    const l2 = [32, 48, 64, 96, 112, 128, 160, 192, 224, 256, 320, 384];
    // Layer III uses a different table than Layer I/II, and MPEG-2/2.5 L3 is
    // lower than MPEG-1 L3.
    const l3Mpeg1 = [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 224, 256, 320];
    const l3Mpeg2 = [32, 48, 56, 64, 80, 96, 112, 128, 160, 224, 256, 320];
    final List<int> table;
    if (layer == 1) {
      table = version == 3 ? l3Mpeg1 : l3Mpeg2;
    } else if (layer == 2) {
      table = l2;
    } else {
      table = l1;
    }
    final i = idx - 1;
    return (i >= 0 && i < table.length) ? table[i] : 0;
  }

  /// Parses a single valid MPEG audio frame header at [offset]. Returns null
  /// if the bytes there are not a decodable frame header.
  static _Mp3Frame? _parseMp3Frame(Uint8List b, int offset) {
    if (offset + 4 > b.length) return null;
    final b0 = b[offset];
    final b1 = b[offset + 1];
    // 11-bit sync: 0xFF followed by 111 in the top 3 bits of the second byte.
    if (b0 != 0xFF || (b1 & 0xE0) != 0xE0) return null;

    final version = (b1 >> 3) & 0x3; // 3 = MPEG-1, 2 = reserved, 1 = MPEG-2, 0 = MPEG-2.5
    final layer = (b1 >> 1) & 0x3; // 3 = Layer I, 2 = Layer II, 1 = Layer III
    if (version == 2 || layer == 0) return null; // reserved

    final b2 = b[offset + 2];
    final bitrateIdx = (b2 >> 4) & 0xF;
    final sampleIdx = (b2 >> 2) & 0x3;
    final padding = (b2 >> 1) & 0x1;
    if (bitrateIdx == 0 || bitrateIdx == 0xF) return null; // free / illegal
    if (sampleIdx == 0x3) return null; // reserved sample rate

    final isMpeg1 = version == 3;
    final isMpeg25 = version == 0; // MPEG-2.5 halves the MPEG-2 sample rate again
    final bitrateKbps = _bitrateKbps(version, layer, bitrateIdx);
    if (bitrateKbps == 0) return null;

    final sampleRate = switch (sampleIdx) {
      0 => isMpeg1
          ? 44100
          : isMpeg25
              ? 11025
              : 22050,
      1 => isMpeg1
          ? 48000
          : isMpeg25
              ? 12000
              : 24000,
      2 => isMpeg1
          ? 32000
          : isMpeg25
              ? 8000
              : 16000,
      _ => 0,
    };

    final int frameSize;
    final int samples;
    if (layer == 3) {
      // Layer I
      frameSize = ((12 * bitrateKbps * 1000 / sampleRate).floor() + padding) * 4;
      samples = 384;
    } else if (layer == 2) {
      // Layer II
      final factor = isMpeg1 ? 144 : 72;
      frameSize = (factor * bitrateKbps * 1000 / sampleRate).floor() + padding;
      samples = 1152;
    } else {
      // Layer III (layer == 1)
      final factor = isMpeg1 ? 144 : 72;
      frameSize = (factor * bitrateKbps * 1000 / sampleRate).floor() + padding;
      samples = isMpeg1 ? 1152 : 576;
    }

    if (frameSize <= 0 || offset + frameSize > b.length) return null;

    return _Mp3Frame(
      offset: offset,
      size: frameSize,
      samples: samples,
      sampleRate: sampleRate,
    );
  }

  static bool _isFrameSync(int b0, int b1) =>
      b0 == 0xFF && (b1 & 0xE0) == 0xE0;

  AudioChunkResult _chunkMp3(Uint8List b) {
    int start = 0;
    if (_startsWith(b, 0, 'ID3') && b.length >= 10) {
      final tagSize = _id3v2Size(b, 0);
      if (tagSize != null) start = 10 + tagSize;
    }

    final frames = <_Mp3Frame>[];
    int i = start;
    while (i + 4 <= b.length) {
      if (_isFrameSync(b[i], b[i + 1])) {
        final f = _parseMp3Frame(b, i);
        if (f != null) {
          frames.add(f);
          i += f.size;
          continue;
        }
      }
      // Not a valid frame header here; scan forward to the next sync. This
      // also recovers from any ID3v2 extended-header bytes we skipped above.
      i += 1;
    }

    if (frames.isEmpty) {
      return AudioChunkResult(
        errorMessage: 'No valid MP3 frames detected; '
            'file may be corrupt, not actually MP3, or VBR with an unsupported header.',
        estimatedDurationSeconds: _estimateDurationFromSize(b),
      );
    }

    final chunks = _buildFrames(frames, b);
    final totalDur = frames.fold(
      0.0,
      (s, f) => s + f.samples / f.sampleRate,
    );
    return AudioChunkResult(chunks: chunks, estimatedDurationSeconds: totalDur);
  }

  /// Groups whole-frame runs into ~[targetSeconds] chunks. Each chunk is a
  /// contiguous byte slice spanning whole frames, so it is valid audio.
  List<AudioChunk> _buildFrames(List<_Mp3Frame> frames, Uint8List b) {
    final chunks = <AudioChunk>[];
    var ci = 0; // first frame index of the current chunk
    var accum = 0.0;
    for (var fi = 0; fi < frames.length; fi++) {
      final f = frames[fi];
      final fdur = f.samples / f.sampleRate;
      accum += fdur;
      if (accum >= targetSeconds && ci < fi) {
        // Flush [ci .. fi-1]; the next chunk starts at frames[fi].
        chunks.add(AudioChunk(
          _slice(b, frames[ci].offset, frames[fi].offset),
          accum - fdur,
        ));
        ci = fi;
        accum = fdur;
      }
    }
    if (ci < frames.length) {
      chunks.add(AudioChunk(
        _slice(b, frames[ci].offset, frames.last.offset + frames.last.size),
        accum,
      ));
    }
    return chunks;
  }

  Uint8List _slice(Uint8List b, int start, int end) {
    final out = Uint8List(end - start);
    out.setRange(0, out.length, b.sublist(start, end));
    return out;
  }

  // ---------------------------------------------------------------------------
  // WAV sample-boundary chunking
  // ---------------------------------------------------------------------------

  AudioChunkResult _chunkWav(Uint8List b) {
    final fmt = _findWavChunk(b, 'fmt ');
    final data = _findWavChunk(b, 'data');
    if (fmt == null || data == null) {
      return AudioChunkResult(
        errorMessage: 'WAV file is missing a fmt or data chunk.',
        estimatedDurationSeconds: _estimateDurationFromSize(b),
      );
    }
    final (dataOffset, dataSize) = data;
    final (fmtOff, fmtSize) = fmt;
    if (dataSize == 0) {
      return const AudioChunkResult(
        errorMessage: 'WAV file has an empty audio data chunk.',
      );
    }

    // fmt data layout: audioFormat(2) channels(2) sampleRate(4) byteRate(4)
    // blockAlign(2) bitsPerSample(2).
    final byteRate = _le(b, fmtOff + 8, 4); // bytesPerSec
    final blockAlign = _le(b, fmtOff + 12, 2);
    if (byteRate <= 0 || blockAlign <= 0) {
      return AudioChunkResult(
        errorMessage: 'WAV fmt chunk has invalid byte rate or block align.',
        estimatedDurationSeconds: _estimateDurationFromSize(b),
      );
    }

    final fmtBytes = _slice(b, fmtOff, fmtOff + fmtSize);

    final chunkSize = (targetSeconds * byteRate);
    final alignedChunk = chunkSize - (chunkSize % blockAlign);

    final chunks = <AudioChunk>[];
    var offset = dataOffset;
    while (offset < dataOffset + dataSize) {
      var end = offset + alignedChunk;
      if (end > dataOffset + dataSize) end = dataOffset + dataSize;
      final slice = _slice(b, offset, end);
      final dur = slice.length / byteRate;
      chunks.add(AudioChunk(_buildWav(fmtBytes, slice), dur));
      offset = end;
    }

    return AudioChunkResult(
      chunks: chunks,
      estimatedDurationSeconds: dataSize / byteRate,
    );
  }

  /// Reassembles a WAV file from its original `fmt ` chunk bytes and a slice
  /// of the `data` chunk.
  static Uint8List _buildWav(Uint8List fmtBytes, Uint8List dataSlice) {
    // RIFF header: 'RIFF' + size + 'WAVE' + 'fmt ' + size + fmt + 'data' + size + data
    final dataLen = dataSlice.length;
    final riffSize = 4 + fmtBytes.length + 4 + dataLen; // WAVE + fmtchunk + datachunk
    final out = BytesBuilder()
      ..add(_ascii('RIFF'))
      ..add(_packLe(riffSize, 4))
      ..add(_ascii('WAVE'))
      ..add(_ascii('fmt '))
      ..add(_packLe(fmtBytes.length, 4))
      ..add(fmtBytes)
      ..add(_ascii('data'))
      ..add(_packLe(dataLen, 4))
      ..add(dataSlice);
    return Uint8List.fromList(out.toBytes());
  }

  static (int, int)? _findWavChunk(Uint8List b, String id) {
    // 12-byte RIFF header, then chunks: id(4) + size(4) + data.
    var o = 12;
    while (o + 8 <= b.length) {
      if (_startsWith(b, o, id)) {
        final size = _le(b, o + 4, 4);
        return (o + 8, size);
      }
      final size = _le(b, o + 4, 4);
      o += 8 + size;
      if (size.isOdd) o += 1; // WAV chunks are word aligned.
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  static int _le(Uint8List b, int offset, int bytes) {
    var v = 0;
    for (var i = 0; i < bytes; i++) {
      v |= (b[offset + i] & 0xFF) << (8 * i);
    }
    return v;
  }

  static List<int> _packLe(int value, int width) =>
      List<int>.generate(width, (i) => (value >> (8 * i)) & 0xFF);

  static List<int> _ascii(String s) => s.codeUnits;

  static double _estimateDurationFromSize(Uint8List b) {
    // Heuristic: assume a 128 kbps MP3 stream (a typical lecture recording).
    const bitsPerSecond = 128000;
    return (b.length * 8) / bitsPerSecond;
  }
}

class _Mp3Frame {
  final int offset;
  final int size;
  final int samples;
  final int sampleRate;

  const _Mp3Frame({
    required this.offset,
    required this.size,
    required this.samples,
    required this.sampleRate,
  });
}
