import 'dart:io' show Directory, File;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/audio_chunker.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';

class TranscriptionPipeline {
  final TranscriptionExtractor _extractor;
  final AsrEngine? _asrEngine;
  final LlmService? _llmService;
  final http.Client _httpClient;
  static final Logger _logger = const Logger('TranscriptionPipeline');

  static const _chunkDurationSeconds = 30;
  static const _maxAsrFileSizeBytesDefault = 25 * 1024 * 1024;

  /// File size (bytes) above which ASR is chunk-decoded rather than sent whole.
  /// Configurable so the chunked path can be exercised in tests without
  /// allocating 25+ MB buffers.
  final int maxFileSizeBytes;

  TranscriptionPipeline({
    required TranscriptionExtractor extractor,
    AsrEngine? asrEngine,
    LlmService? llmService,
    http.Client? httpClient,
    int? maxFileSizeBytes,
  })  : _extractor = extractor,
        _asrEngine = asrEngine,
        _llmService = llmService,
        _httpClient = httpClient ?? http.Client(),
        maxFileSizeBytes = maxFileSizeBytes ?? _maxAsrFileSizeBytesDefault;

  Future<TranscriptionResult> transcribe({
    required String rawContent,
    String? sourceUrl,
  }) async {
    final effectiveUrl = sourceUrl ?? rawContent;

    if (effectiveUrl.contains('youtube.com') || effectiveUrl.contains('youtu.be')) {
      return _transcribeYouTube(effectiveUrl);
    }

    if (effectiveUrl.startsWith('file://')) {
      return _transcribeFile(effectiveUrl.substring(7));
    }

    if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      return _transcribeUrl(effectiveUrl);
    }

    return _extractor.transcribeAudio(rawContent: rawContent, sourceUrl: sourceUrl);
  }

  Future<TranscriptionResult> _transcribeYouTube(String url) async {
    _logger.d('Pipeline: processing YouTube URL');

    final transcriptResult = await _extractor.transcribeVideo(
      rawContent: url,
      sourceUrl: null,
    );
    if (transcriptResult.text.isNotEmpty) {
      return transcriptResult;
    }

    // The extractor's YouTube path already handles caption-less videos
    // (`youtube_no_transcript`), and an LLM cannot transcribe a video
    // from a URL alone — so there is no LLM fallback to apply here.
    // Re-calling the extractor with identical arguments would only
    // duplicate the failed network round trip.
    if (_llmService != null) {
      _logger.d(
        'Pipeline: YouTube transcript unavailable; LLM cannot transcribe video from URL alone',
      );
    }

    return transcriptResult;
  }

  Future<TranscriptionResult> _transcribeFile(String filePath) async {
    _logger.d('Pipeline: processing file $filePath');

    final file = File(filePath);
    if (!file.existsSync()) {
      _logger.w('Pipeline: file not found: $filePath');
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'file_not_found',
      );
    }
    final fileSizeBytes = await file.length();

    if (_asrEngine != null && _asrEngine.isAvailable) {
      if (fileSizeBytes > maxFileSizeBytes) {
        _logger.d(
          'Pipeline: file size ${_mb(fileSizeBytes)} > ${_mb(maxFileSizeBytes)}, '
          'using frame-aware chunked ASR',
        );
        final chunkResult =
            await _transcribeFileChunked(filePath, fileSizeBytes);
        if (chunkResult.text.isNotEmpty) return chunkResult;
        // Unsupported format is a specific, actionable error — preserve it
        // rather than masking as a generic size-limit failure.
        if (chunkResult.extractionMethod == 'asr_unsupported_format') {
          return chunkResult;
        }
        // Over-sized and chunking could not recover (all chunks empty): fail
        // loud instead of re-sending the whole file (which would only hit the
        // API size limit again) or base64-encoding the entire recording for
        // an LLM that cannot hear audio.
        return _largeFileFailure(fileSizeBytes);
      }

      final asrResult = await _asrEngine.transcribeFile(filePath: filePath);
      if (asrResult.text.isNotEmpty) {
        _logger.d('Pipeline: ASR transcription successful for $filePath');
        return asrResult;
      }
      _logger.w(
        'Pipeline: ASR returned empty for $filePath, falling back to LLM',
      );
      // Small file: fall through to the extractor LLM path below.
    } else if (fileSizeBytes > maxFileSizeBytes) {
      // No ASR configured and the recording is too large to safely send to an
      // LLM (base64 inflates it ~33%). Fail loud with guidance.
      return _largeFileFailure(fileSizeBytes);
    }

    return _extractor.transcribeAudio(
      rawContent: 'file://$filePath',
      sourceUrl: null,
    );
  }

  TranscriptionResult _largeFileFailure(int fileSizeBytes) {
    final est = _estimateDurationSeconds(fileSizeBytes);
    final estStr = est > 0
        ? ' (estimated ${_formatDuration(est)})'
        : '';
    return TranscriptionResult(
      text: '',
      extractionMethod: 'asr_file_too_large',
      errorMessage: 'Audio file exceeds the ${_mb(maxFileSizeBytes)} '
          'safe chunked-transcription limit.$estStr '
          'Split the recording into shorter segments (under '
          '${_mb(maxFileSizeBytes)} each) or configure an ASR key in Settings.',
    );
  }

  double _estimateDurationSeconds(int bytes) {
    // Heuristic: assume a 128 kbps MP3 stream (a typical lecture recording).
    const bitsPerSecond = 128000;
    return (bytes * 8) / bitsPerSecond;
  }

  String _formatDuration(double seconds) {
    final s = seconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';

  Future<TranscriptionResult> _transcribeFileChunked(
    String filePath,
    int fileSizeBytes,
  ) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'chunked_file_not_found',
      );
    }

    // Frame-aware splitting: each output chunk is a self-contained, decodable
    // audio file (a run of whole MP3 frames, or a complete WAV), never an
    // arbitrary byte slice that loses codec framing.
    final bytes = await file.readAsBytes();
    final chunker = AudioChunker(targetSeconds: _chunkDurationSeconds);
    final chunkResult = chunker.chunk(bytes);

    if (!chunkResult.isSuccess || chunkResult.chunks.isEmpty) {
      _logger.w(
        'Pipeline: chunker could not split audio — ${chunkResult.errorMessage}',
      );
      return TranscriptionResult(
        text: '',
        extractionMethod: 'asr_unsupported_format',
        errorMessage: chunkResult.errorMessage ??
            'Unable to chunk audio for transcription.',
      );
    }

    final tempDir = Directory.systemTemp;
    final chunkDir = Directory(
      '${tempDir.path}/transcription_chunks_${DateTime.now().millisecondsSinceEpoch}',
    );
    await chunkDir.create(recursive: true);

    final baseName = p.basenameWithoutExtension(filePath);
    final ext = p.extension(filePath);
    final chunkPaths = <String>[];

    try {
      final segments = <TranscriptionSegment>[];
      var totalOffset = 0.0;
      var index = 0;
      for (final chunk in chunkResult.chunks) {
        final chunkPath = '${chunkDir.path}/${baseName}_chunk_$index$ext';
        final chunkFile = File(chunkPath);
        await chunkFile.writeAsBytes(chunk.bytes);
        chunkPaths.add(chunkPath);

        final asrResult = await _asrEngine!.transcribeFile(filePath: chunkPath);
        if (asrResult.text.isNotEmpty) {
          if (asrResult.segments != null) {
            for (final seg in asrResult.segments!) {
              segments.add(TranscriptionSegment(
                text: seg.text,
                startSeconds: seg.startSeconds + totalOffset,
                endSeconds: seg.endSeconds + totalOffset,
                confidence: seg.confidence,
              ));
            }
          } else {
            segments.add(TranscriptionSegment(
              text: asrResult.text,
              startSeconds: totalOffset,
              endSeconds: totalOffset + chunk.durationSeconds,
              confidence: asrResult.confidence ?? 0.0,
            ));
          }
        }
        // Each chunk occupies its own slice of the timeline even when it
        // yields no text (silence, noise, a transient failure), so the offset
        // advances by the chunk's real duration — otherwise every later
        // segment shifts earlier.
        totalOffset += chunk.durationSeconds;
        index++;
      }

      if (segments.isEmpty) {
        return const TranscriptionResult(
          text: '',
          extractionMethod: 'chunked_asr_empty',
        );
      }

      final fullText = segments.map((s) => s.text).join(' ');
      final avgConfidence = segments.fold<double>(
            0.0,
            (sum, s) => sum + s.confidence,
          ) /
          segments.length;

      return TranscriptionResult(
        text: fullText,
        durationSeconds: totalOffset.toInt(),
        extractionMethod: 'chunked_asr',
        confidence: avgConfidence,
        segments: segments,
      );
    } catch (e, st) {
      _logger.w('Pipeline: chunked ASR failed', e, st);
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'chunked_asr_failed',
      );
    } finally {
      for (final chunkPath in chunkPaths) {
        final chunkFile = File(chunkPath);
        if (chunkFile.existsSync()) {
          await chunkFile.delete();
        }
      }
      if (chunkDir.existsSync()) {
        await chunkDir.delete();
      }
    }
  }

  Future<TranscriptionResult> _transcribeUrl(String url) async {
    _logger.d('Pipeline: processing URL $url');

    if (_asrEngine != null && _asrEngine.isAvailable) {
      final downloadedPath = await _downloadToTempFile(url);
      if (downloadedPath == null) {
        _logger.w('Pipeline: failed to download URL $url');
      } else {
        try {
          final fileSizeBytes = await File(downloadedPath).length();
          if (fileSizeBytes > maxFileSizeBytes) {
            _logger.d(
              'Pipeline: downloaded file ${_mb(fileSizeBytes)} > limit, '
              'chunking',
            );
            final chunkResult =
                await _transcribeFileChunked(downloadedPath, fileSizeBytes);
            if (chunkResult.text.isNotEmpty) return chunkResult;
            if (chunkResult.extractionMethod == 'asr_unsupported_format') {
              return chunkResult;
            }
            return _largeFileFailure(fileSizeBytes);
          }
          final asrResult =
              await _asrEngine.transcribeFile(filePath: downloadedPath);
          if (asrResult.text.isNotEmpty) {
            _logger.d('Pipeline: ASR transcription successful for URL');
            return asrResult;
          }
          _logger.w('Pipeline: ASR returned empty for downloaded URL file');
        } finally {
          final tempFile = File(downloadedPath);
          if (tempFile.existsSync()) {
            await tempFile.delete();
          }
        }
      }
    }

    if (_llmService != null) {
      return _extractor.transcribeAudio(rawContent: url, sourceUrl: null);
    }

    return const TranscriptionResult(
      text: '',
      extractionMethod: 'pipeline_no_handler',
    );
  }

  Future<String?> _downloadToTempFile(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode != 200) {
        _logger.w('Pipeline: failed to download URL, status ${response.statusCode}');
        return null;
      }

      final contentType = response.headers['content-type'] ?? '';
      final ext = _extensionFromContentType(contentType, url);

      final tempDir = Directory.systemTemp;
      final fileName = 'downloaded_audio_$ext';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _logger.d('Pipeline: downloaded URL to $filePath (${response.bodyBytes.length} bytes)');
      return filePath;
    } catch (e) {
      _logger.w('Pipeline: failed to download URL', e);
      return null;
    }
  }

  String _extensionFromContentType(String contentType, String url) {
    if (contentType.contains('audio/mpeg') || contentType.contains('audio/mp3')) {
      return '.mp3';
    }
    if (contentType.contains('audio/wav') || contentType.contains('audio/x-wav')) {
      return '.wav';
    }
    if (contentType.contains('audio/ogg')) {
      return '.ogg';
    }
    if (contentType.contains('audio/mp4') || contentType.contains('audio/m4a')) {
      return '.m4a';
    }
    if (contentType.contains('audio/webm')) {
      return '.webm';
    }

    final urlPath = Uri.tryParse(url)?.path ?? '';
    final urlExt = p.extension(urlPath).toLowerCase();
    if (['.mp3', '.wav', '.ogg', '.m4a', '.webm', '.mp4'].contains(urlExt)) {
      return urlExt;
    }

    return '.mp3';
  }

  void dispose() {
    _httpClient.close();
  }
}
