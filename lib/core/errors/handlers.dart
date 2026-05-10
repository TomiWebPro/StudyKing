import 'package:flutter/material.dart';
import '../errors/exceptions.dart';

/// Centralized error handling utility
/// 
/// Handles errors throughout the application with:
/// - User-friendly error messages
/// - Retry mechanisms
/// - Analytics logging
/// - Proper error UI feedback
class AppErrorHandler {
  /// Handles an error and displays appropriate feedback
  static Future<void> handleError(
    BuildContext context,
    Object error,
    String contextName, {
    bool retry = false,
    void Function()? retryCallback,
  }) async {
    // Log to analytics (would be implemented with analytics SDK)
    _logError(error, contextName);
    
    // Convert to appropriate exception type
    final exception = _convertToAppException(error);
    
    // Handle based on exception type
    _showErrorUI(context, exception, retry: retry, retryCallback: retryCallback);
  }
  
  /// Handles sync errors (for operations that aren't async)
  static void handleSyncError(BuildContext context, Object error, String contextName, {bool retry = false, void Function()? retryCallback}) {
    _logError(error, contextName);
    
    final exception = _convertToAppException(error);
    final errorMessage = _getErrorMessage(exception);
    
    if (retry && retryCallback != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text(errorMessage)),
              TextButton(
                onPressed: retryCallback,
                child: const Text('Retry'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Show user-friendly error message via ScaffoldMessenger
  static void _showErrorUI(
    BuildContext context,
    AppException exception, {
    bool retry = false,
    void Function()? retryCallback,
  }) {
    // Map exception types to user-friendly messages
    final errorMessage = _getErrorMessage(exception);
    final snackBar = SnackBar(
      content: retry && retryCallback != null
          ? Row(
              children: [
                const Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
                TextButton(
                  onPressed: retryCallback,
                  child: const Text('Retry'),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getErrorIcon(exception),
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
      backgroundColor: Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: retry ? 4 : 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  /// Get user-friendly error message based on exception type
  static String _getErrorMessage(AppException exception) {
    switch (exception) {
      case NetworkException _:
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      case ApiKeyMissingException _:
        return 'API key is required. Please configure it in Settings.';
      case InvalidApiKeyException _:
        return 'Invalid API key. Please check your credentials in Settings.';
      case ApiRateLimitException _:
        return 'Too many requests. Please wait a moment and try again.';
      case ApiNotFoundException _:
        return 'The requested resource was not found.';
      case ApiInternalServerError _:
        return 'The server encountered an error. Please try again later.';
      case DatabaseException _:
        return 'A database error occurred. Please try again.';
      case ValidationException _:
        return exception.message;
      case PdfParseException _:
        return 'Unable to parse the PDF file. Please ensure it is a valid PDF.';
      case ContentGenerationException _:
        return 'Failed to generate content. Please try again.';
      case LlmException _:
        return 'The AI service is temporarily unavailable. Please try again.';
      case ApiAuthException _:
        return 'Authentication failed. Please check your API credentials.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
  
  static IconData _getErrorIcon(AppException exception) {
    switch (exception) {
      case NetworkException _:
        return Icons.network_check;
      case ApiKeyMissingException _:
      case InvalidApiKeyException _:
      case ApiAuthException _:
        return Icons.key_rounded;
      case ApiRateLimitException _:
        return Icons.pause_circle;
      case ApiNotFoundException _:
        return Icons.looks_one_outlined;
      case ApiInternalServerError _:
        return Icons.bug_report;
      case DatabaseException _:
        return Icons.storage;
      case ValidationException _:
        return Icons.info;
      case PdfParseException _:
        return Icons.picture_as_pdf;
      case ContentGenerationException _:
      case LlmException _:
        return Icons.wifi_tethering_off;
      default:
        return Icons.error_outline;
    }
  }
  
  /// Get retry button text based on error type
  static String getRetryText(AppException exception) {
    switch (exception) {
      case NetworkException _:
        return 'Retry Connection';
      case ApiRateLimitException _:
        return 'Retry After Wait';
      case ApiInternalServerError _:
        return 'Try Again';
      default:
        return 'Retry';
    }
  }
  
  /// Wraps an async operation with error handling
  static Future<T?> safely<T>(
    BuildContext context,
    Future<T> Function() operation, {
    T? defaultValue,
    String contextName = 'Operation',
  }) async {
    try {
      return await operation();
    } catch (error) {
      await handleError(context, error, contextName);
      return defaultValue;
    }
  }
  
  /// Wraps a synchronous operation with error handling
  static R? safelySync<R>(
    BuildContext context,
    R Function() operation, {
    R? defaultValue,
    String contextName = 'Operation',
  }) {
    try {
      return operation();
    } catch (error) {
      handleSyncError(context, error, contextName);
      return defaultValue;
    }
  }
  
  static void _logError(Object error, String context) {
    // Log to console in debug mode
    if (const bool.hasEnvironment('flutter.debug')) {
      debugPrint('[$context] Error: $error');
    }
  }
  
  
  static AppException _convertToAppException(Object error) {
    // Already an AppException
    if (error is AppException) {
      return error;
    }
    
    // Handle specific error types by string matching
    final errorStr = error.toString();
    
    if (errorStr.contains('ConnectionFailedError') || 
        errorStr.contains('SocketException') ||
        errorStr.contains('Network')) {
      return NetworkException(
        message: 'Network request failed',
        originalError: error,
      );
    }
    
    if (errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('invalid')) {
      return InvalidApiKeyException(
        message: 'Invalid API key or credentials',
        originalError: error,
      );
    }
    
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return ApiRateLimitException(
        message: 'Too many requests or access denied',
        originalError: error,
      );
    }
    
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return ApiNotFoundException(
        message: 'Resource not found',
        originalError: error,
      );
    }
    
    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503')) {
      return ApiInternalServerError(
        message: 'Server error occurred',
        originalError: error,
      );
    }
    
    if (error is FormatException) {
      return ValidationException(
        message: 'Invalid data format',
        originalError: error,
      );
    }
    
    if (error is StateError || error is AssertionError) {
      return DatabaseException(
        message: 'Application state error',
        originalError: error,
      );
    }
    
    // Default to generic exception
    return NetworkException(
      message: 'An unexpected error occurred',
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
