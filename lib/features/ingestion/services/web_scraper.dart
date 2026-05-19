import 'package:http/http.dart' as http;
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';

class WebScraper {
  final http.Client _httpClient;
  final Logger _logger = const Logger('WebScraper');

  WebScraper({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<Result<String>> fetchPageContent(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme) {
        return Result.failure('Invalid_URL_scheme');
      }

      final response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent': ApiConfig.userAgent,
        },
      );

      if (response.statusCode != 200) {
        return Result.failure(
          'Fetch_failed_status: ${response.statusCode}',
        );
      }

      final body = response.body;
      final extracted = DocumentExtractor.stripHtmlToText(body);
      if (extracted.isEmpty) {
        return Result.failure('No_readable_content');
      }
      return Result.success(extracted);
    } catch (e) {
      _logger.e('Web scrape error', e);
      return Result.failure(e.toString());
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
