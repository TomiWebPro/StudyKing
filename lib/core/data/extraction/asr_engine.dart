import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:studyking/core/constants/app_api_config.dart';
import 'package:studyking/core/utils/logger.dart';
import 'transcription_extractor.dart';

abstract class AsrEngine {
  bool get isAvailable;

  Future<TranscriptionResult> transcribeFile({
    required String filePath,
    String? language,
  });
}

class WhisperApiAsrEngine implements AsrEngine {
  final String? _apiKey;
  final Uri _apiUrl;
  final http.Client _httpClient;
  static final Logger _logger = const Logger('WhisperApiAsrEngine');

  WhisperApiAsrEngine({
    String? apiKey,
    String? baseUrl,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _apiUrl = _resolveApiUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  /// Resolves the transcription endpoint. An explicit [baseUrl] (or the
  /// `OPENAI_BASE_URL` override via [ApiConfig.openAIDefaultUrl]) is
  /// honored so a self-hosted, OpenAI-compatible Whisper server can be
  /// used instead of the paid cloud — the same override every other
  /// OpenAI-compatible service in the app already respects.
  static Uri _resolveApiUrl(String? baseUrl) {
    final base =
        (baseUrl != null && baseUrl.isNotEmpty) ? baseUrl : ApiConfig.openAIDefaultUrl;
    final normalized =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return Uri.parse('$normalized/audio/transcriptions');
  }

  @override
  bool get isAvailable => _apiKey != null && _apiKey.isNotEmpty;

  @override
  Future<TranscriptionResult> transcribeFile({
    required String filePath,
    String? language,
  }) async {
    if (!isAvailable) {
      _logger.w('Whisper API not available - no API key configured');
      return const TranscriptionResult(
        text: '',
        extractionMethod: 'whisper_no_api_key',
      );
    }

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const TranscriptionResult(
          text: '',
          extractionMethod: 'whisper_file_not_found',
        );
      }

      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      final request = http.MultipartRequest('POST', _apiUrl)
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..fields['model'] = 'whisper-1'
        ..fields['response_format'] = 'verbose_json'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ));

      if (language != null && language.isNotEmpty) {
        request.fields['language'] = language;
      }

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        _logger.w('Whisper API returned status ${response.statusCode}: ${response.body}');
        return TranscriptionResult(
          text: '',
          extractionMethod: 'whisper_api_error',
          errorMessage: 'Whisper API error: ${response.statusCode}',
        );
      }

      return _parseWhisperResponse(response.body);
    } catch (e) {
      _logger.w('Whisper API transcription failed', e);
      return TranscriptionResult(
        text: '',
        extractionMethod: 'whisper_failed',
        errorMessage: 'Whisper transcription failed: $e',
      );
    }
  }

  TranscriptionResult _parseWhisperResponse(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final text = decoded['text'] as String? ?? '';
      final duration = decoded['duration'] as num?;
      final segmentsJson = decoded['segments'] as List<dynamic>?;

      List<TranscriptionSegment> segments = [];
      double totalConfidence = 0.0;

      if (segmentsJson != null) {
        for (final seg in segmentsJson) {
          if (seg is Map<String, dynamic>) {
            final segText = seg['text'] as String? ?? '';
            final segStart = (seg['start'] as num?)?.toDouble() ?? 0.0;
            final segEnd = (seg['end'] as num?)?.toDouble() ?? 0.0;
            final avgLogprob = (seg['avg_logprob'] as num?)?.toDouble() ?? 0.0;
            final confidence = _avgLogprobToConfidence(avgLogprob);

            segments.add(TranscriptionSegment(
              text: segText.trim(),
              startSeconds: segStart,
              endSeconds: segEnd,
              confidence: confidence,
            ));
            totalConfidence += confidence;
          }
        }
      }

      final overallConfidence = segments.isNotEmpty
          ? totalConfidence / segments.length
          : null;

      return TranscriptionResult(
        text: text.trim(),
        durationSeconds: duration?.toInt(),
        extractionMethod: 'whisper_api',
        confidence: overallConfidence,
        segments: segments.isNotEmpty ? segments : null,
      );
    } catch (e) {
      _logger.w('Failed to parse Whisper API response', e);
      try {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final text = decoded['text'] as String? ?? '';
        return TranscriptionResult(
          text: text.trim(),
          extractionMethod: 'whisper_api',
        );
      } catch (e) {
        _logger.w('Failed to extract fallback text from Whisper response', e);
        return const TranscriptionResult(
          text: '',
          extractionMethod: 'whisper_parse_failed',
        );
      }
    }
  }

  double _avgLogprobToConfidence(double avgLogprob) {
    final score = exp(avgLogprob);
    return score.clamp(0.0, 1.0);
  }

  void dispose() {
    _httpClient.close();
  }
}

class NoopAsrEngine implements AsrEngine {
  @override
  bool get isAvailable => false;

  @override
  Future<TranscriptionResult> transcribeFile({
    required String filePath,
    String? language,
  }) async {
    return const TranscriptionResult(
      text: '',
      extractionMethod: 'no_asr_engine',
    );
  }
}
