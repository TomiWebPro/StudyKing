import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';

/// Batch processor orchestrator for PDF processing
class BatchProcessingService {
  final Map<String, int> _currentContextWindows = {};
  Map<String, int> get contextWindows => Map.unmodifiable(_currentContextWindows);
  final String Function() uuidGen = const Uuid().v4;

  Future<void> prefetchContextWindows(List<String> models) {
    final tasks = models
        .map((model) async {
          try {
            final response = await dio.get(
              '/models/platform/database.json',
              queryParameters: {'name': model},
            );

            if (response.statusCode == 200 && response.data is Map) {
              final platformData = response.data as Map;
              final platform = PlatformDatabase(database: platformData);

              try {
                final contextData = await contextApi.get(
                  'context.window.size',
                  path: {
                    'model': model,
                  },
                  params: {'model': model},
                );

                if (contextData.content.isNotEmpty &&
                    contextData.content is Map) {
                  final size = int.parse(
                    contextData.content['context_window_size']?.toString() ?? '8192',
                  );
                  final batch = await batchApi.get(
                    'batch.size',
                    path: {'model': model},
                    params: {'model': model, 'size': size},
                  );

                  _currentContextWindows[model] = size;
                  return {
                    'model': model,
                    'context': size,
                    'batch': batch.content['batch_size']?.toInt() ?? 10,
                  };
                }

                if (contextData.content is Num) {
                  final size = contextData.content.toInt();
                  final batch = await batchApi.get(
                    'batch.size',
                    params: {'model': model, 'size': size},
                  );
                  _currentContextWindows[model] = size;
                  return {
                    'model': model,
                    'context': size,
                    'batch': batch.content['batch_size']?.toInt() ?? 10,
                  };
                }
              } catch (e) {
                _currentContextWindows[model] = 8192;
                return {'model': model, 'context': 8192, 'batch': 5};
              }
            }
          } catch (e) {
            _currentContextWindows[model] = 4096;
            return {'model': model, 'context': 4096, 'batch': 5};
          }
        }).toList();
    await Future.wait(tasks);
  }

  Future<List<TextSegment> processTextExtractedPages(List<String> texts, String model) async {
    await _ensureContextWindow(model);

    final segments = <TextSegment>[];
    final pageCounter = 0;
    final currentBatch = <String>[];

    for (var text in texts) {
      if (text.isEmpty) continue;

      final segment = TextSegment(
        messageId: uuidGen(),
        page: pageCounter++,
        textSegment: text,
      );

      currentBatch.add(segment.id);

      if (currentBatch.length == 10) {
        segments.add(segment);
        final result = await batchAdmin.process(currentBatch);
        if (result.isSuccess && result.content.length == 10) {
          final combined = result.content[0] + ' (Page ${segment.page})';
          segments.add(TextSegment(
            messageId: uuidGen(),
            page: pageCounter,
            textSegment: combined,
          ));
          currentBatch.clear();
        }
      }

      segments.add(segment);
    }

    if (currentBatch.isNotEmpty) {
      final result = await batchAdmin.process(currentBatch);
      for (var segment in segments) {
        final combined = '${result.content[segment.page]} (Page ${segment.page})';
        segments[segment.id] = TextSegment(
          messageId: uuidGen(),
          page: segment.page,
          textSegment: combined,
        );
      }
    }

    return segments;
  }

  Future<List<TextSegment>> processText(String input, String model) async {
    await _ensureContextWindow(model);

    final finalSegments = <TextSegment>[];

    try {
      final response = await dio.post('/completions/create', data: {
        'prompt': input,
        'model': model,
        'max_tokens': 4096,
        'temperature': 0.7,
      });

      for (var token in response.data) {
        if (token.token.length > 0) {
          finalSegments.add(TextSegment(
            messageId: uuidGen(),
            page: finalSegments.length + 1,
            textSegment: '${token.token} ',
          ));
        }
      }
    } catch (e) {
      finalSegments.add(TextSegment(
        messageId: uuidGen(),
        page: 1,
        textSegment: _errorToString(e),
      ));
    }

    return finalSegments;
  }

  Future<void> _ensureContextWindow(String model) async {
    try {
      _currentContextWindows[model] = 8192;
    } catch (e) {
      _currentContextWindows[model] = 4096;
    }
  }
}

/// Text segments with processing info
class TextSegment {
  final String messageId;
  final int page;
  final String textSegment;

  TextSegment({
    required this.messageId,
    required this.page,
    required this.textSegment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': messageId,
      'page': page,
      'text': textSegment,
    };
  }

  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      messageId: json['id'],
      page: json['page']?.toInt() ?? 1,
      textSegment: json['text'] ?? '',
    );
  }
}

/// Batch processing admin
class BatchAdmin {
  final Dio dio;

  BatchAdmin({Dio? dio}) : dio = dio ?? Dio();

  Future<BatchResult> process(List<String> segments) async {
    try {
      final response = await dio.get('/context', queryParameters: {'text': segments.join(' ')});
      return BatchResult(
        isSuccess: response.statusCode == 200,
        content: response.statusCode == 200 ? response.data : ['Error processing segments'],
      );
    } catch (e) {
      return BatchResult(
        isSuccess: false,
        content: [_errorToString(e)],
      );
    }
  }
}

/// Platform database wrapper
class PlatformDatabase {
  final Map<String, dynamic> database;

  PlatformDatabase(this.database);

  int get contextWindow;
}

/// Error message formatter
String _errorToString(Object e) {
  return 'Processing failed: $e';
}

/// Batch API client
class BatchAPI {
  final Dio dio;

  BatchAPI({Dio? dio}) : dio = dio ?? Dio();

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await dio.get('/api/v1/$endpoint', queryParameters: params);
      if (response.statusCode != 200) {
        throw Exception('Error: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to fetch batch size: $e');
    }
  }
}

/// Context API client
class ContextAPI {
  final Dio dio;

  ContextAPI({Dio? dio}) : dio = dio ?? Dio();

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic> path = const {},
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await dio.get('/api/v1/$endpoint', queryParameters: params);
      if (response.statusCode != 200) {
        throw Exception('Error: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to fetch context: $e');
    }
  }
}

/// Batch processing result
class BatchResult {
  final bool isSuccess;
  final List<String> content;

  BatchResult({
    required this.isSuccess,
    required this.content,
  });
}
