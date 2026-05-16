import 'package:http/http.dart' as http;
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/errors/result.dart';

class WebScraper {
  final http.Client _httpClient;
  final Logger _logger = const Logger('WebScraper');

  WebScraper({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<Result<String>> fetchPageContent(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme) {
        return Result.failure('Invalid URL: no scheme provided');
      }

      final response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; StudyKing/1.0)',
        },
      );

      if (response.statusCode != 200) {
        return Result.failure(
          'Failed to fetch URL: HTTP ${response.statusCode}',
        );
      }

      final body = response.body;
      final extracted = _extractMainText(body);
      if (extracted.isEmpty) {
        return Result.failure('No readable content found at URL');
      }
      return Result.success(extracted);
    } catch (e) {
      _logger.e('Web scrape error', e);
      return Result.failure('Failed to fetch URL: $e');
    }
  }

  String _extractMainText(String html) {
    final buffer = StringBuffer();
    final scriptOrStyle = RegExp(r'<(script|style)[^>]*>', caseSensitive: false);
    final endScriptOrStyle = RegExp(r'</(script|style)>', caseSensitive: false);

    var text = html;
    while (text.isNotEmpty) {
      final scriptStart = scriptOrStyle.firstMatch(text);
      if (scriptStart != null) {
        buffer.write(_stripTags(text.substring(0, scriptStart.start)));
        text = text.substring(scriptStart.start);
        final scriptEnd = endScriptOrStyle.firstMatch(text);
        if (scriptEnd != null) {
          text = text.substring(scriptEnd.end);
        } else {
          break;
        }
      } else {
        buffer.write(_stripTags(text));
        break;
      }
    }

    final result = buffer.toString();
    final lines = result
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 20)
        .toList();

    return lines.join('\n\n');
  }

  String _stripTags(String html) {
    final buffer = StringBuffer();
    var inTag = false;
    for (var i = 0; i < html.length; i++) {
      final char = html[i];
      if (char == '<') {
        inTag = true;
      } else if (char == '>') {
        inTag = false;
      } else if (!inTag) {
        buffer.write(char);
      }
    }
    return buffer.toString().trim();
  }

  void dispose() {
    _httpClient.close();
  }
}
