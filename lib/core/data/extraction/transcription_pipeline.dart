import 'dart:io' show Directory, File;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/data/extraction/transcription_extractor.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';

class TranscriptionPipeline {
  final TranscriptionExtractor _extractor;
  final AsrEngine? _asrEngine;
  final LlmService? _llmService;
  final http.Client _httpClient;
  static final Logger _logger = const Logger('TranscriptionPipeline');

  static const _maxAsrFileSizeMb = 25.0;
  static const _chunkDurationSeconds = 30;

  TranscriptionPipeline({
    required TranscriptionExtractor extractor,
    AsrEngine? asrEngine,
    LlmService? llmService,
    http.Client? httpClient,
  })  : _extractor = extractor,
        _asrEngine = asrEngine,
        _llmService = llmService,
        _httpClient = httpClient ?? http.Client();

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

    if (_llmService != null) {
      _logger.d('Pipeline: YouTube transcript unavailable, falling back to LLM');
      return _extractor.transcribeVideo(rawContent: url, sourceUrl: null);
    }

    return transcriptResult;
  }

  Future<TranscriptionResult> _transcribeFile(String filePath) async {
    _logger.d('Pipeline: processing file $filePath');

    if (_asrEngine != null && _asrEngine.isAvailable) {
      final file = File(filePath);
      if (file.existsSync()) {
        final fileSizeMb = await file.length() / (1024 * 1024);
        if (fileSizeMb > _maxAsrFileSizeMb) {
          _logger.d('Pipeline: file size ${fileSizeMb.toStringAsFixed(1)}MB > ${_maxAsrFileSizeMb}MB, attempting chunked ASR');
          final chunkResult = await _transcribeFileChunked(filePath);
          if (chunkResult.text.isNotEmpty) {
            return chunkResult;
          }
          _logger.w('Pipeline: chunked ASR failed, falling back to direct ASR');
        }
      }

      final asrResult = await _asrEngine.transcribeFile(filePath: filePath);
      if (asrResult.text.isNotEmpty) {
        _logger.d('Pipeline: ASR transcription successful for $filePath');
        return asrResult;
      }
      _logger.w('Pipeline: ASR returned empty for $filePath, falling back to LLM');
    }

    return _extractor.transcribeAudio(rawContent: 'file://$filePath', sourceUrl: null);
  }

  Future<TranscriptionResult> _transcribeFileChunked(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const TranscriptionResult(
          text: '',
          extractionMethod: 'chunked_file_not_found',
        );
      }

      final tempDir = Directory.systemTemp;
      final chunkDir = Directory('${tempDir.path}/transcription_chunks');
      if (!chunkDir.existsSync()) {
        await chunkDir.create(recursive: true);
      }

      final baseName = p.basenameWithoutExtension(filePath);
      final ext = p.extension(filePath);
      final chunkPaths = <String>[];

      try {
        final originalBytes = await file.readAsBytes();
        final chunkSizeBytes = (_chunkDurationSeconds * 128 * 1024);

        if (originalBytes.length <= chunkSizeBytes) {
          final asrResult = await _asrEngine!.transcribeFile(filePath: filePath);
          return asrResult;
        }

        for (var i = 0; i < originalBytes.length; i += chunkSizeBytes) {
          final end = (i + chunkSizeBytes).clamp(0, originalBytes.length);
          final chunkBytes = originalBytes.sublist(i, end);
          final chunkPath = '${chunkDir.path}/${baseName}_chunk_$i$ext';
          final chunkFile = File(chunkPath);
          await chunkFile.writeAsBytes(chunkBytes);
          chunkPaths.add(chunkPath);
        }

        _logger.d('Pipeline: split audio into ${chunkPaths.length} chunks of ${_chunkDurationSeconds}s');

        final segments = <TranscriptionSegment>[];
        var totalOffset = 0.0;

        for (final chunkPath in chunkPaths) {
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
                endSeconds: totalOffset + _chunkDurationSeconds,
                confidence: asrResult.confidence ?? 0.0,
              ));
            }
            totalOffset += _chunkDurationSeconds;
          }
        }

        if (segments.isEmpty) {
          return const TranscriptionResult(
            text: '',
            extractionMethod: 'chunked_asr_empty',
          );
        }

        final fullText = segments.map((s) => s.text).join(' ');
        final avgConfidence = segments.isNotEmpty
            ? segments.fold<double>(0.0, (sum, s) => sum + s.confidence) / segments.length
            : null;

        return TranscriptionResult(
          text: fullText,
          durationSeconds: totalOffset.toInt(),
          extractionMethod: 'chunked_asr',
          confidence: avgConfidence,
          segments: segments,
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
    } catch (e) {
      _logger.w('Pipeline: chunked ASR failed', e);
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'chunked_asr_failed',
      );
    }
  }

  Future<TranscriptionResult> _transcribeUrl(String url) async {
    _logger.d('Pipeline: processing URL $url');

    if (_asrEngine != null && _asrEngine.isAvailable) {
      final downloadResult = await _downloadToTempFile(url);
      if (downloadResult != null) {
        final filePath = downloadResult;
        try {
          final asrResult = await _asrEngine.transcribeFile(filePath: filePath);
          if (asrResult.text.isNotEmpty) {
            _logger.d('Pipeline: ASR transcription successful for URL');
            return asrResult;
          }
          _logger.w('Pipeline: ASR returned empty for downloaded URL file');
        } finally {
          final tempFile = File(filePath);
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
