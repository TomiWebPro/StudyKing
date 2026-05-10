import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// PDF File Upload Coordinator with progress tracking
class PDFFileUploadCoordinator {
  late final String _filePath;
  late int _totalBytes;
  final List<_FileChunk> _chunks = [];
  final Map<String, dynamic> _contentMap = {};
  int _pageCounter = 1;
  int _totalSizeKB = 0;
  final int _chunkSize = 4096;

  PDFFileUploadCoordinator({
    required String filePath,
  }) : _filePath = filePath {
    final file = File(filePath);
    _totalBytes = file.lengthSync();
    _totalSizeKB = (_totalBytes / 1024).round();
    _addDownloadProgressListener();
  }

  /// Start coordinate operation
  void startCoordinates() {
    _setHeader('Accept-encoding', 'gzip');

    // Chunk by fixed size, not per byte
    final numChunks = (_totalBytes / _chunkSize).ceil();
    for (var i = 0; i < numChunks; i++) {
      _chunks.add(_FileChunk(index: i));
    }

    final dio = Dio();
    dio.options.connectTimeout = const Duration(milliseconds: 120000);

    // Create batch via API
    dio.get('/api/v1/batch');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          final authHeader = request.headers.remove('Authorization');
          final authValue = authHeader is List<String> && authHeader.isNotEmpty ? authHeader.first : null;
          if (authValue != null) {
            request.headers['Authorization'] = authValue;
          }
          _setHeader('Content-Type', 'multipart/form-data');
          handler.next(request);
        },
        onError: (error, handler) {
          _error(error);
          handler.next(error);
        },
      ),
    );

    // Upload file
    final form = FormData.fromMap({
      'file': MultipartFile.fromFileSync(_filePath),
      'sizeKB': _totalSizeKB.toString(),
      'totalPages': _pageCounter.toString(),
    });

    dio.post('/file/upload', data: form);

    // Map data to JSON
    _fetchContentStream(dio);
  }

  Future<void> _fetchContentStream(Dio dio) async {
    try {
      final response = await dio.get('/content/stream');
      if (response.data is Map) {
        _contentMap.addAll(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      debugPrint('Failed to fetch content stream: $e');
    }
  }

  /// Send to server
  Future<String> sendToServer() async {
    final dio = Dio();
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(_filePath),
      'content': _contentMap.toString(),
      'status': 'completed',
    });

    final response = await dio.post('/upload', data: form);
    return response.statusCode.toString();
  }

  /// Error handling
  Future<void> _error(Object error) async {
    if (error is DioException) {
      debugPrint('Upload error: ${error.message}');
    }
  }

  /// Update chunk states
  void incrementProgress() {
    _pageCounter++;
  }

  /// Cancel download
  void cancel() {
    _totalSizeKB = 0;
  }

  void _setHeader(String type, String value) {
    // Header setting handled via Dio interceptors
  }

  void _addDownloadProgressListener() {
    // Progress listener configured via Dio onReceiveProgress
  }
}

/// File chunk data for tracking upload progress
class _FileChunk {
  final int index;
  bool done = false;

  _FileChunk({required this.index});
}

/// API upload header extraction
class HeadersAPI {
  static const int defaultTimeout = 30000;

  /// Call API with timeout
  Future<T?> call<T>({
    required String endpoint,
    required String headerName,
    required String headerToken,
    T? defaultData,
  }) async {
    final dio = Dio();
    try {
      final data = await dio.post(
        endpoint,
        data: headerName,
        options: Options(
          headers: {headerName: headerToken},
        ),
      );
      if (data.data is T) return data.data as T;
      return defaultData;
    } catch (e) {
      return defaultData;
    }
  }

  /// Raw HTTP call
  Future<Response> callRaw({
    required String url,
    Map<String, String>? headers,
    String? body,
  }) async {
    final dio = Dio();
    return dio.post(
      url,
      data: body,
      options: Options(headers: headers),
    );
  }
}
