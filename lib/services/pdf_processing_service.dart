import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:studyking/providers/llm_engine_provider.dart';

/// PDF Processing Service with Dynamic Context Window Fetching
class PDFProcessingService extends ChangeNotifier {
  final Dio dio;
  final LLMAIEngineProvider llmEngineProvider;
  final Map<String, int> _contextWindows = {};
  int _currentContext = 8192;
  bool _isFetching = false;

  PDFProcessingService({required this.llmEngineProvider})
      : dio = Dio();

  int get currentContext => _currentContext;
  Map<String, int> get contextWindows => Map.unmodifiable(_contextWindows);
  bool get isFetching => _isFetching;

  /// Fetch context window for active model
  Future<void> fetchContextWindow(String modelId) async {
    _isFetching = true;
    llmEngineProvider.notifyListeners();

    try {
      final response = await dio.post('/api/v1/context', data: {'model': modelId});
      _contextWindows[modelId] = response.data['context_window_size']?.toInt() ?? 4096;
      _currentContext = _contextWindows[modelId] ?? 8192;
    } catch (e) {
      _contextWindows[modelId] = 4096;
      _currentContext = 8192;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Fetch batches of pages from document
  Future<List<Map<String, dynamic>>> fetchContextPages(int pages) async {
    final response = await dio.get('/api/v1/pages', queryParameters: {'n': pages});
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data as List);
    }
    return [];
  }

  /// Chunk text with fixed window
  List<List<String>> chunkText(List<String> pages) {
    final result = <List<String>>[];
    var currentChunk = <String>[];
    var currentSize = 0;

    for (var page in pages) {
      final pageSize = page.length;
      if (currentSize + pageSize > _currentContext && currentChunk.isNotEmpty) {
        result.add(currentChunk);
        currentChunk = [];
        currentSize = 0;
      }
      currentChunk.add(page);
      currentSize += pageSize;
    }

    if (currentChunk.isNotEmpty) {
      result.add(currentChunk);
    }

    return result;
  }

  /// Process text via LLM
  Future<List<TextSegment>> processTextChunks(List<List<String>> textChunks) async {
    final results = <TextSegment>[];

    for (var chunk in textChunks) {
      final response = await dio.post('/api/v1/generate', data: {'text': chunk.join('\n')});
      final data = response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
      results.add(TextSegment(
        id: data['id']?.toString() ?? '',
        text: data['generated']?.toString() ?? '',
      ));
    }

    return results;
  }

  /// Error handling
  void onError(String? error) {
    debugPrint('PDFProcessingService error: $error');
  }

  /// HTTP request
  Future<File> requestStream(String url) async {
    final response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
    final tempFile = File('${Directory.systemTemp.path}/stream_output');
    await tempFile.writeAsBytes(response.data as List<int>);
    return tempFile;
  }

  /// Upload to server
  Future<Response> upload(String filePath, String url) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    return await Dio().post(url, data: formData);
  }
}

/// Text segment for processed content
class TextSegment {
  final String id;
  final String text;

  TextSegment({required this.id, required this.text});
}

/// API Context Generator
class ApiContext {
  final String endpoint = '/api/v1/context';

  Future<String> createContext() async {
    final response = await Dio().get('/api/v1/context');
    return response.data?.toString() ?? '';
  }
}

/// Dynamic Context Generator
class ContextGenerator {
  final Map<String, int> _contextMap = {};
  int currentContext = 0;

  int getContextWindow(String model) {
    return _contextMap[model] ?? 4096;
  }

  void setContext(String model, int size) {
    _contextMap[model] = size;
    currentContext = size;
  }

  void clearContext() {
    _contextMap.clear();
  }

  Map<String, int> getContextMap() => _contextMap;
}

/// HTTP Response Processor
class HTTPResponseProcessor {
  final String body;
  final Map<String, dynamic> headers;
  final String status;
  final Map<String, dynamic>? queryParameters;

  HTTPResponseProcessor({
    required this.body,
    required this.headers,
    required this.status,
    this.queryParameters,
  });
}

/// Storage Manager
class StorageService {
  static Future<void> initialize() async {
    // TODO: Add Hive initialization when hive package is properly configured
  }

  static Future<void> set(String key, dynamic value) async {
    // TODO: Implement with Hive when available
  }

  static Future<dynamic> get(String key) async => null;

  static Future<void> remove(String key) async {}

  static Future<void> clearAll() async {}

  static Future<void> clearBox() async {}
}
