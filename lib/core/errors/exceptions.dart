/// Application-specific exceptions for error handling
/// 
/// These exceptions provide structured error types that can be
/// caught and handled appropriately throughout the application.

/// Base exception for all app errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

/// Network-related exceptions
class NetworkException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const NetworkException({
    required this.message,
    this.code = 'NETWORK_ERROR',
    this.originalError,
  });
}

/// API-related exceptions
class ApiAuthException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const ApiAuthException({
    required this.message,
    this.code = 'AUTH_ERROR',
    this.originalError,
  });
}

class ApiRateLimitException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const ApiRateLimitException({
    required this.message,
    this.code = 'RATE_LIMIT_ERROR',
    this.originalError,
  });
}

class ApiNotFoundException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const ApiNotFoundException({
    required this.message,
    this.code = 'NOT_FOUND_ERROR',
    this.originalError,
  });
}

class ApiInternalServerError implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const ApiInternalServerError({
    required this.message,
    this.code = 'SERVER_ERROR',
    this.originalError,
  });
}

/// Database-related exceptions
class DatabaseException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const DatabaseException({
    required this.message,
    this.code = 'DATABASE_ERROR',
    this.originalError,
  });
}

class DatabaseNotFoundException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const DatabaseNotFoundException({
    required this.message,
    this.code = 'NOT_FOUND_ERROR',
    this.originalError,
  });
}

// Model validation exceptions
class ValidationException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const ValidationException({
    required this.message,
    this.code = 'VALIDATION_ERROR',
    this.originalError,
  });
}

// File system exceptions
class FileSystemException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const FileSystemException({
    required this.message,
    this.code = 'FILE_SYSTEM_ERROR',
    this.originalError,
  });
}

// PDF-specific exceptions
class PdfParseException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const PdfParseException({
    required this.message,
    this.code = 'PDF_PARSE_ERROR',
    this.originalError,
  });
}

// Content generation exceptions
class ContentGenerationException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const ContentGenerationException({
    required this.message,
    this.code = 'GENERATION_ERROR',
    this.originalError,
  });
}

// LLM-specific exceptions
class LlmException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const LlmException({
    required this.message,
    this.code = 'LLM_ERROR',
    this.originalError,
  });
}

// API Key exceptions
class ApiKeyMissingException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const ApiKeyMissingException({
    required this.message,
    this.code = 'API_KEY_MISSING',
    this.originalError,
  });
}

class InvalidApiKeyException implements AppException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final dynamic originalError;

  const InvalidApiKeyException({
    required this.message,
    this.code = 'INVALID_API_KEY',
    this.originalError,
  });
}
