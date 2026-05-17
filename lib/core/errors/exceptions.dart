enum ExceptionType {
  network,
  apiKeyMissing,
  invalidApiKey,
  apiAuth,
  apiRateLimit,
  apiNotFound,
  apiInternalServer,
  database,
  validation,
  pdfParse,
  llm,
  contentGeneration,
  unknown,
}

class AppException implements Exception {
  final String message;
  final ExceptionType type;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.type = ExceptionType.unknown,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}
