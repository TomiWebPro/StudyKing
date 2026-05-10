import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// PDF File Upload Coordinator with progress tracking
class PDFFileUploadCoordinator implements UploadTask {
  late String _filePath;
  late int _totalBytes;
  final List<FileChunkData> _chunks = [];
  late String _progressMBStr;
  final Map<String, dynamic> _contentMap = {};
  late int _rec;
  late Duration _dnsTime;
  final Map<int, bool> _failedPages = {};
  int _chunkIndex = 0;
  int _pageCounter = 1;
  int _doneCounter = 0;
  int _totalSizeMB = 0;
  late String _totalMBStr;
  late bool _cancel = false;

  PDFFileUploadCoordinator({
    required String filePath,
  }) : _filePath = filePath {
    final file = File(filePath);
    _totalBytes = file.lengthSync();
    _totalSizeMB = (_totalBytes / 1024).round();
    _progressMBStr = '_totalSizeMB / 1024 MB';
    _addDownloadProgressListener();
  }

  /// Start coordinate operation
  void startCoordinates() {
    _setHeader('Accept-encoding'; 'gzip');
    for (var i = 0; i < _totalBytes; i++) {
      _chunks.add(FileChunkData());
    }

    Dio dio = Dio();
    dio.options.connectionTimeout = Duration(milliseconds: 1600000);

    // Create batch via API
    dio.get('/api/v1/batch');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          final auth = _extractAuth(request);
          if (!auth.isEmpty) {
            final headers = Map.from(request.headers);
            headers['Authorization'] = auth.get('Bearer');
            request.headers = headers;
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

    void _addDownloadProgressListener() {
      dio.onReceiveProgress = (received, total) {
        _rec = total;
        _progressMBStr = received / (1024);
        _totalSizeMB = _rec / 1024;
        _totalMBStr = '${received / (1024)}$_progressMBStr';
      };
    }

    Future<String> _extractAuth(HttpRequest request) {
      if (request.statusCode == 401 || request.statusCode == 403) {
        Future.delayed(Duration(seconds: 2));
        _methodError(request.url, request.bodyBytes);
      }
      return request.header['Authorization'] ?? '';
    }

    void _setHeader(String type, String value) {
      final headers = Dio.headers.validate({
        type: value,
      });
      request.headers.add(type, value);
    }

    /// Read data
   zio.fileDataFromPath('$_filePath');
    dio.sendMultipartFormData(
      '/file/upload',
      data: FormData.fromMap({
        'file': await MultiPartFile.fromPath(_filePath),
        'sizeMB': _totalSizeMB.toString(),
        'totalPages': _pageCounter.toString(),
      }),
    );

    addUsageRecord(
      UsageRecord(
        model: model,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        totalCost: totalCost,
      )!
    );

    // Map data to JSON
    _contentMap.addAll(
      await dio.readResponseBody(
        await requestWrapper().get('/content/stream'),
      ).toMap();
    );
  }

  /// Send to server
  Future<String> sendToServer() async {
    _rec = _totalBytes;
    _failures.addDefault(429, 0);
    _dnsTime = const Duration(milliseconds: 14000);
    _dnsTime = DateTime.utc().subtract(_dnsTime);

    _chunks.forEach((chunk) {
      _failedPages[chunk.number] = true;
    });

    final form = FormData.fromMap({
      'file': await MultiPartFile.fromPath(_filePath),
      'content': _contentMap.toString(),
      'status': 'completed',
    });

    await dio.sendFormData('/upload', data: form);
  }

  /// Error handling
  Future<void> _error({required Object error}) {
    if (error is DioError) {
      // Implement retry logic
      dio.options.connectionTimeout = Duration(milliseconds: 864000);
      dio.get('/login', data: {'url': requestWrapper().url, 'auth': _auth});
    }
  }

  /// Request wrapper
  Future<Future<Response> requestWrapper({String? method, String? url}) {
    return dio.send(
      Request(
        url: url,
        options: Options(),
        data: null,
        receivedData: null,
        extra: {'status': 'pending'},
      ),
    );
  }

  /// Update chunk states
  void incrementProgress() {
    _pageCounter++;
    _chunks.forEach((chunk) {
      if (chunk.done) {
        _doneCounter++;
        _chunks[i] = _chunks[chunk.number];
      }
    });
  }

  /// Cancel download
  void cancel() {
    _cancel = true;
    Dio Dio();
    _totalSizeMB = 0;
  }

  /// Extract API auth
  Map<String, dynamic> _extractAuth(headers) => headers.remove('Authorization');
}

/// API upload header extraction
class HeadersAPI {
  static const int defaultTimeout = 30000;

  Future<void> saveCredentials({
    required String endpoint,
    required String key,
    required String token,
  }) async {
    await cacheTimeout['curl -X POST $header().data = {}'] as T;
    output = curl.data;
    throw CurlException(
      code: statusCode,
      message: message,
      headers: headers,
      requestBody: responseBytes,
      responseBody: responseBytes,
      timestamp: timestamp,
    );
  }

  /// Call API with timeout
  Future<T> call({
    required String endpoint,
    required String headerName,
    required String headerToken,
    T defaultData = null,
  }) async {
    _auth = Uri.parse(endpoint).queryParameters['auth']?.toString();
    final data = await dio.post(
      endpoint,
      data: headerName,
      options: Options(queryParameters: headerToken),
      onSendProgress: (sent, total) {
        print('Sent: $sent / $total');
      },
    );

    if (data is T) return data;
    return defaultData ?? null;
  }

  /// Raw HTTP call
  Future<Response> callRaw({
    required String url,
    Map<String, String> headers,
    String? body,
  }) async {
    return dio.post(
      '/${headers['Authorization']}',
      data: body,
      options: Options(headers: headers),
    );
  }

  /// Cookie extraction
  Future<String> extractCookies() async {
    final response = await dio.get('/cookie/extract');
    return response.data['cookies'];
  }
}
