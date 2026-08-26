import 'dart:convert' show Encoding, utf8;

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/page_metadata.dart';

class WebScraper {
  final http.Client _httpClient;
  final ScrapeCache? _cache;
  final Duration politenessDelay;
  static final Logger _logger = const Logger('WebScraper');

  DateTime? _lastFetch;

  WebScraper({
    http.Client? httpClient,
    ScrapeCache? cache,
    this.politenessDelay = Duration.zero,
  })  : _httpClient = httpClient ?? http.Client(),
        _cache = cache;

  Future<Result<ScrapedPage>> fetchPageContent(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme) {
        return Result.failure(
          'Invalid URL: a scheme (http:// or https://) is required',
        );
      }

      if (_cache != null) {
        final cached = await _cache.get(url);
        if (cached != null) {
          _logger.i('Cache hit for $url');
          return Result.success(cached.copyWith(fromCache: true));
        }
      }

      await _enforcePoliteness();

      final response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent': ApiConfig.userAgent,
        },
      );

      if (response.statusCode != 200) {
        return Result.failure(
          'Failed to fetch page (status code: ${response.statusCode})',
        );
      }

      final body = _decodeBody(response);
      final extracted = DocumentExtractor.stripHtmlToText(body);
      if (extracted.isEmpty) {
        return Result.failure(
          'No readable content found on the page',
        );
      }

      final metadata = DocumentExtractor.extractPageMetadata(body);
      final page = ScrapedPage(content: extracted, metadata: metadata);

      if (_cache != null) {
        await _cache.put(url, page);
      }

      return Result.success(page);
    } catch (e) {
      _logger.w('Web scrape error', e);
      return Result.failure(e.toString());
    }
  }

  /// Decodes the response body respecting any charset declared in the
  /// Content-Type header (e.g. ISO-8859-1, windows-1252). Falls back to UTF-8
  /// so non-UTF8 pages render correctly instead of producing mojibake.
  String _decodeBody(http.Response response) {
    final contentType = response.headers['content-type'];
    Encoding encoding = utf8;
    if (contentType != null) {
      try {
        final mediaType = MediaType.parse(contentType);
        final charset = mediaType.parameters['charset'];
        if (charset != null) {
          final resolved = Encoding.getByName(charset);
          if (resolved != null) encoding = resolved;
        }
      } catch (e) {
        _logger.w('Could not parse Content-Type charset; using UTF-8', e);
      }
    }
    return encoding.decode(response.bodyBytes);
  }

  /// Simple politeness delay between successive fetches to avoid hammering a
  /// host. Disabled when [politenessDelay] is zero.
  Future<void> _enforcePoliteness() async {
    if (politenessDelay == Duration.zero) return;
    if (_lastFetch != null) {
      final elapsed = DateTime.now().difference(_lastFetch!);
      if (elapsed < politenessDelay) {
        await Future.delayed(politenessDelay - elapsed);
      }
    }
    _lastFetch = DateTime.now();
  }

  void dispose() {
    _httpClient.close();
  }
}
