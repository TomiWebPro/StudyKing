import '../errors/exceptions.dart';

/// Centralized error handling utility
/// 
/// Handles errors throughout the application with:
/// - User-friendly error messages
/// - Retry mechanisms
/// - Analytics logging
class AppErrorHandler {
  /// Handles an error and displays appropriate feedback
  static Future<void> handleError(
    Object error,
    String context, {
    bool retry = false,
    void Function()? retryCallback,
  }) async {
    // Log to analytics (would be implemented with analytics SDK)
    _logError(error, context);

    // Convert to appropriate exception type
    final exception = _convertToAppException(error);

    // Handle based on exception type
    if (exception is NetworkException) {
      _showUserMessage(
        'Unable to connect to the server. Please check your internet connection.',
        isError: true,
      );
      if (retry && retryCallback != null) {
        retryCallback();
      }
    } else if (exception is ApiKeyMissingException) {
      _showUserMessage(
        'API key is required. Please configure it in Settings.',
        isError: true,
      );
    } else if (exception is InvalidApiKeyException) {
      _showUserMessage(
        'Invalid API key. Please check your credentials in Settings.',
        isError: true,
      );
    } else if (exception is ApiRateLimitException) {
      _showUserMessage(
        'Too many requests. Please wait a moment and try again.',
        isError: true,
      );
    } else if (exception is ApiNotFoundException) {
      _showUserMessage(
        'The requested resource was not found.',
        isError: true,
      );
    } else if (exception is ApiInternalServerError) {
      _showUserMessage(
        'The server encountered an error. Please try again later.',
        isError: true,
      );
    } else if (exception is DatabaseException) {
      _showUserMessage(
        'A database error occurred. Please try again.',
        isError: true,
      );
    } else if (exception is ValidationException) {
      _showUserMessage(
        exception.message,
        isError: true,
      );
    } else if (exception is PdfParseException) {
      _showUserMessage(
        'Unable to parse the PDF file. Please ensure it\'s a valid PDF.',
        isError: true,
      );
    } else if (exception is ContentGenerationException) {
      _showUserMessage(
        'Failed to generate content. Please try again.',
        isError: true,
      );
    } else if (exception is LlmException) {
      _showUserMessage(
        'The AI service is temporarily unavailable. Please try again.',
        isError: true,
      );
    } else {
      _showUserMessage(
        'An unexpected error occurred. Please try again.',
        isError: true,
      );
    }
  }

  /// Wraps an async operation with error handling
  static Future<T?> safely<T>(
    Future<T> Function() operation, {
    T? defaultValue,
    String context = 'Operation',
  }) async {
    try {
      return await operation();
    } catch (error) {
      await handleError(error, context);
      return defaultValue;
    }
  }

  /// Wraps a synchronous operation with error handling
  static R? safelySync<R>(
    R Function() operation, {
    R? defaultValue,
    String context = 'Operation',
  }) {
    try {
      return operation();
    } catch (error) {
      _handleSyncError(error, context);
      return defaultValue;
    }
  }

  static void _logError(Object error, String context) {
    // This would integrate with analytics services
    // For now, just print to console in debug mode
    if (const bool.hasEnvironment('flutter.debug')) {
      print('[$context] Error: $error');
    }
  }

  static void _handleSyncError(Object error, String context) {
    // Synchronous error logging
    if (const bool.hasEnvironment('flutter.debug')) {
      print('[$context] Sync Error: $error');
    }
  }

  static void _showUserMessage(String message, {bool isError = false}) {
    // This would integrate with the UI layer
    // For now, just print to console
    if (isError) {
      print('ERROR UI: $message');
    } else {
      print('INFO UI: $message');
    }
  }

  static AppException _convertToAppException(Object error) {
    // Already an AppException
    if (error is AppException) {
      return error;
    }

    // Handle specific error types
    if (error.toString().contains('ConnectionFailedError') || 
        error.toString().contains('Network')) {
      return NetworkException(
        message: 'Network request failed',
        originalError: error,
      );
    }

    if (error is FormatException) {
      return ValidationException(
        message: 'Invalid data format',
        originalError: error,
      );
    }

    if (error is StateError) {
      return DatabaseException(
        message: 'State error occurred',
        originalError: error,
      );
    }

    // Default to generic exception
    if (error.toString().contains('Format')) {
      return ValidationException(
        message: 'Invalid data format',
        originalError: error,
      );
    }

    if (error.toString().contains('State')) {
      return DatabaseException(
        message: 'State error occurred',
        originalError: error,
      );
    }

    // Default to generic exception
    return NetworkException(
      message: 'An unexpected error occurred: ${error.toString()}',
      originalError: error,
    );
  }
}

/// Result type for operations that can fail
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result.success(this.data) : error = null, isSuccess = true;
  const Result.failure(this.error) : data = null, isSuccess = false;

  bool get hasError => error != null;
}
