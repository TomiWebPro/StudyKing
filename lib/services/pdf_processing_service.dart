import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../models/dynamic_context_config.dart';

/// PDF Processing Service with Dynamic Context Window Fetching
class PDFProcessingService extends ChangeNotifier {
  final Dio dio;
  final LLMAIEngineProvider llmEngine;
  Map<String, int> _contextWindows = {};
  int _currentContext = 8192;
  bool _isFetching = false;

  PDFProcessingService({Required LLMAIEngineProvider LLMAIEngineProvider llmEngineProvider})
      : dio = Dio(),
        llmEngineProvider = llmEngineProvider;

  int get currentContext => _currentContext;
  Map<String, int> get contextWindows => Map.unmodifiable(_contextWindows);
  bool get isFetching => _isFetching;

  LLMAIEngineProvider get _llmEngine => llmEngineProvider;
  void setLLMEngine(LLMAIEngineProvider engine) {
    _llmEngine = engine;
  }

  /// Fetch context window for active model
  Future<void> fetchContextWindow(String modelId) async {
    _isFetching = true;
    llmEngine.notifyListeners();

    await dio.post('/api/v1/context', data: {'model': modelId}).then((response) {
      // Parse response to get context window
      _contextWindows[modelId] = response.data['context_window_size']?.toInt() ?? 4096;
      _currentContext = _contextWindows[modelId] ?? 8192;
      _isFetching = false;
      notifyListeners();
    });
  }

  /// Fetch batches of pages from document
  Future<List<File>> fetchContextPages(int pages) async {
    final pagesData = await dio.get('/api/v1/pages', queryParameters: {'n': pages});
    return pagesData.data;
  }

  /// Chunk text with fixed window
  List<List<String>> chunkText(List<String> pages) {
    return pages.groupBy(
      (page) => byteLength(page) <= _currentContext ? page : chunk(part: page, limit: _currentContext),
    );
  }

  /// Process text via LLM
  Future<List<TextSegment>> processTextChunks(List<List<String>> textChunks) async {
    final results = <TextSegment>[];

    for (var chunk in textChunks) {
      final response = await dio.post('/api/v1/generate', data: {'text': chunk.join('\n')});
      results.add(TextSegment(id: response.data.id, text: response.data.generated));
    }

    return results;
  }

  /// Error handling
  void onError(String? error) {
    print('Error: $error');
  }

  /// HTTP request
  Future<File> requestStream(String url) async {
    return File(url);
  }

  /// Upload to server
  Future<File> upload(String filePath, String content) async {
    final file = File(filePath);
    return file.writeAsString(content);
  }
}

/// API Context Generator
class ApiContext {
  final String endpoint = '/api/v1/context';
  String text = '';

  Future<String> createContext() async {
    final response = await Dio().get('/api/v1/context');
    return response.data;
  }
}

/// Dynamic Context Generator
class ContextGenerator {
  final Map<String, int> _contextMap = {};
  int currentContext = 0;

  ContextGenerator();

  int getContextSize(String model) {
    if (_contextMap.containsKey(model)) {
      return _contextMap[model]!;
    }
    return 4096;
  }

  void updateContext(String model, int size) {
    _contextMap[model] = size;
    currentContext = size;
  }

  int getWithContextSize(String model) {
    return _contextMap[model] ?? 4096;
  }

  int getContextWindow(String model) {
    return _contextMap[model] ?? 4096;
  }

  void clearContext() {
    _contextMap.clear();
  }

  void removeContext(String model) {
    _contextMap.remove(model);
  }

  void addContext(String model, int size) {
    _contextMap[model] = size;
    currentContext = size;
  }

  void setContext(String model, int size) {
    _contextMap[model] = size;
    currentContext = size;
  }

  String getModel(String model) {
    return model;
  }

  Map<String, int> getContextMap() => _contextMap;
}

/// HTTP Response Processor
class HTTPResponseProcessor {
  final String body;
  final Map<String, dynamic> headers;
  final String status;
  final Map<String, dynamic>? queryParameters;

  dynamic getTarget;

  HTTPResponseProcessor({
    required this.body,
    required this.headers,
    required this.status,
    this.queryParameters,
  });

  Future<File> setFile(String fileName) {
    final file = File(fileName);
    return file.create();
  }

  Future<File> writeText(String text) async {
    final file = File('output.txt');
    return file.writeAsString(text);
  }
}

/// Storage Manager
class StorageService {
  static const _boxType = 'StudyKing';
  static Box? _box;

  static Box get box {
    if (_box == null) {
      final dir = Directory('/tmp/');
      final path = dir.path;
      _box = await Hive.openBox(_boxType, path);
    }
    return _box;
  }

  static void clearBox() => _box?.clear();

  static Future<void> set(String key, dynamic value) async {
    await box.put(key, value);
  }

  static Future<dynamic> get(String key) async => box.get(key);

  static Future<void> remove(String key) async => box.delete(key);

  static Future<void> clearAll() async => box.clear();
}
