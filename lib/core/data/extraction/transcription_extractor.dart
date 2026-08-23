import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class TranscriptionSegment {
  final String text;
  final double startSeconds;
  final double endSeconds;
  final double confidence;

  const TranscriptionSegment({
    required this.text,
    required this.startSeconds,
    required this.endSeconds,
    required this.confidence,
  });
}

class TranscriptionResult {
  final String text;
  final int? durationSeconds;
  final String extractionMethod;
  final String? errorMessage;
  final double? confidence;
  final List<TranscriptionSegment>? segments;

  const TranscriptionResult({
    required this.text,
    this.durationSeconds,
    required this.extractionMethod,
    this.errorMessage,
    this.confidence,
    this.segments,
  });

  bool get isError => errorMessage != null;
}

class TranscriptionExtractor {
  final LlmService? _llmService;
  final String _modelId;
  final http.Client _httpClient;
  final String _localeName;
  final AsrEngine? _asrEngine;
  static final Logger _logger = const Logger('TranscriptionExtractor');

  TranscriptionExtractor({
    LlmService? llmService,
    required String modelId,
    http.Client? httpClient,
    required String localeName,
    AsrEngine? asrEngine,
  })  : _llmService = llmService,
        _modelId = modelId,
        _httpClient = httpClient ?? http.Client(),
        _localeName = localeName,
        _asrEngine = asrEngine {
    if (modelId.isEmpty) {
      _logger.w('TranscriptionExtractor created with empty modelId - LLM transcription will fail');
    }
  }

  Future<TranscriptionResult> transcribeAudio({
    required String rawContent,
    required String? sourceUrl,
  }) async {
    final effectiveUrl = sourceUrl ?? rawContent;

    if (effectiveUrl.startsWith('file://')) {
      return _transcribeFile(effectiveUrl.substring(7));
    }

    if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      return _transcribeUrl(effectiveUrl, isVideo: false);
    }

    if (_llmService != null && rawContent.length > 20) {
      return _transcribeWithLlm(rawContent);
    }

    return const TranscriptionResult(
      text: '',
      extractionMethod: 'audio_no_content',
    );
  }

  Future<TranscriptionResult> transcribeVideo({
    required String rawContent,
    required String? sourceUrl,
  }) async {
    final effectiveUrl = sourceUrl ?? rawContent;

    if (effectiveUrl.contains('youtube.com') || effectiveUrl.contains('youtu.be')) {
      return _transcribeYouTube(effectiveUrl);
    }

    if (effectiveUrl.startsWith('file://')) {
      return _transcribeFile(effectiveUrl.substring(7));
    }

    if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
      return _transcribeUrl(effectiveUrl, isVideo: true);
    }

    if (_llmService != null && rawContent.length > 20) {
      return _transcribeWithLlm(rawContent);
    }

    return const TranscriptionResult(
      text: '',
      extractionMethod: 'video_no_content',
    );
  }

  Future<TranscriptionResult> _transcribeFile(String filePath) async {
    if (kIsWeb) {
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'file_web_unsupported',
      );
    }
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const TranscriptionResult(
          text: '',
          extractionMethod: 'file_not_found',
        );
      }

      if (_asrEngine != null && _asrEngine.isAvailable) {
        final asrResult = await _asrEngine.transcribeFile(filePath: filePath);
        if (asrResult.text.isNotEmpty) {
          return asrResult;
        }
        _logger.w('ASR returned empty result for $filePath, falling back to LLM');
      }

      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      if (_llmService != null) {
        return await _transcribeWithLlm(base64Str);
      }
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'file_no_llm',
      );
    } catch (e) {
      _logger.w('Failed to read audio/video file', e);
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'file_read_error',
      );
    }
  }

  Future<TranscriptionResult> _transcribeUrl(
    String url, {
    bool isVideo = false,
  }) async {
    final prefix = isVideo ? 'video' : 'audio';

    if (_llmService != null) {
      return _transcribeWithLlm(url);
    }
    return TranscriptionResult(
      text: '',
      extractionMethod: '${prefix}_url_no_llm',
    );
  }

  Future<TranscriptionResult> _transcribeYouTube(String url) async {
    final youtubeResult = await _fetchYouTubeTranscript(url);
    if (youtubeResult.text.isNotEmpty) {
      return youtubeResult;
    }

    if (_llmService != null) {
      return _transcribeWithLlm('YouTube URL: $url');
    }
    return youtubeResult;
  }

  Future<TranscriptionResult> _fetchYouTubeTranscript(String url) async {
    try {
      final videoId = _extractYoutubeVideoId(url);
      if (videoId == null) {
        return const TranscriptionResult(
          text: '',
          extractionMethod: 'youtube_invalid_url',
        );
      }

      final transcript = await _fetchTranscript(videoId);
      if (transcript != null && transcript.isNotEmpty) {
        return TranscriptionResult(
          text: transcript,
          extractionMethod: 'youtube_transcript_fetched',
        );
      }

      final pageContent = await _fetchYoutubePageContent(videoId);
      if (pageContent != null && _llmService != null) {
        return await _transcribeWithLlm(
          'YouTube video ID: $videoId\nPage content: $pageContent',
        );
      }

      if (_llmService != null) {
        return await _transcribeWithLlm('YouTube video ID: $videoId\nURL: $url');
      }

      return const TranscriptionResult(
        text: '',
        extractionMethod: 'youtube_no_transcript',
      );
    } catch (e) {
      _logger.w('YouTube transcript fetch failed', e);
      if (_llmService != null) {
        return _transcribeWithLlm('YouTube URL: $url');
      }
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'youtube_fetch_failed',
      );
    }
  }

  String? _extractYoutubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }

    return null;
  }

  Future<String?> _fetchTranscript(String videoId) async {
    try {
      final urls = [
        '${ApiConfig.youtubetranscriptBaseUrl}/?v=$videoId',
        '${ApiConfig.youtubetranscriptApiUrl}/$videoId',
      ];

      for (final url in urls) {
        try {
          final response = await _httpClient.get(
            Uri.parse(url),
            headers: {
              'User-Agent': ApiConfig.userAgent,
            },
          );

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            final body = response.body;

            if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
              try {
                final decoded = jsonDecode(body);
                if (decoded is List && decoded.isNotEmpty) {
                  final textParts = decoded
                      .map((segment) =>
                          (segment is Map ? segment['text'] : null) as String?)
                      .where((t) => t != null && t.isNotEmpty)
                      .join(' ');
                  if (textParts.isNotEmpty) return textParts;
                }
              } catch (e) {
                _logger.w('Failed to parse YouTube transcript JSON', e);
              }
            }

            if (!body.trim().startsWith('<') && body.length > 50) {
              return body;
            }
          }
        } catch (e) {
          _logger.w('Failed to fetch YouTube transcript from URL', e);
        }
      }

      return null;
    } catch (e) {
      _logger.w('Failed to fetch YouTube transcript', e);
      return null;
    }
  }

  Future<String?> _fetchYoutubePageContent(String videoId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('https://www.youtube.com/watch?v=$videoId'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final body = response.body;
        final titleMatch =
            RegExp(r'<title>(.+?)</title>').firstMatch(body);
        final descMatch = RegExp(
          r'<meta\s+name="description"\s+content="([^"]+)"',
        ).firstMatch(body);

        final buffer = StringBuffer();
        if (titleMatch != null) {
          buffer.writeln('Title: ${titleMatch.group(1)}');
        }
        if (descMatch != null) {
          buffer.writeln('Description: ${descMatch.group(1)}');
        }

        if (buffer.isNotEmpty) return buffer.toString().trim();
      }
      return null;
    } catch (e) {
      _logger.w('Failed to fetch YouTube page', e);
      return null;
    }
  }

  Future<TranscriptionResult> _transcribeWithLlm(String content) async {
    if (_llmService == null) {
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'llm_not_available',
        errorMessage: 'No LLM service configured',
      );
    }

    if (_modelId.isEmpty) {
      const errorMsg = 'No transcription-capable model configured. '
          'Please select a model in Settings > AI Configuration.';
      _logger.w(errorMsg);
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'model_id_empty',
        errorMessage: errorMsg,
      );
    }

    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.transcribeUserPrompt(content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: _modelId,
        systemPrompt: l10n.transcribeSystemPrompt,
        feature: 'transcription',
      );
      if (result.isFailure) {
        return TranscriptionResult(
          text: '',
          extractionMethod: 'transcription_llm_failed',
          errorMessage: result.error,
        );
      }
      final response = result.data!;

      if (response.trim().isEmpty) {
        return const TranscriptionResult(
          text: '',
          extractionMethod: 'transcription_empty',
          errorMessage: 'Transcription returned empty result. '
              'The model may not support transcription tasks.',
        );
      }

      return TranscriptionResult(
        text: response.trim(),
        extractionMethod: 'transcribed_llm',
      );
    } catch (e) {
      _logger.w('LLM transcription failed', e);
      return TranscriptionResult(
        text: '',
        extractionMethod: 'transcription_llm_failed',
        errorMessage: 'Transcription failed: $e',
      );
    }
  }

  void dispose() {
    _httpClient.close();
    final asrEngine = _asrEngine;
    if (asrEngine is WhisperApiAsrEngine) {
      asrEngine.dispose();
    }
  }
}
