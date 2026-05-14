import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/generated/app_localizations_en.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

/// Centralized error handling utility
/// 
/// Handles errors throughout the application with:
/// - User-friendly error messages
/// - Retry mechanisms
/// - Analytics logging
/// - Proper error UI feedback
class AppErrorHandler {
  static final Logger _logger = const Logger('AppErrorHandler');
  static AppLocalizations get _defaultL10n => AppLocalizationsEn();

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

    final l10n = AppLocalizations.of(context)!;
    final exception = _convertToAppException(error);
    final errorMessage = _getErrorMessage(exception, l10n);

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
                child: Text(l10n.retry),
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
    final l10n = AppLocalizations.of(context)!;
    // Map exception types to user-friendly messages
    final errorMessage = _getErrorMessage(exception, l10n);
    final snackBar = SnackBar(
      content: retry && retryCallback != null
          ? Row(
              children: [
                const Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
                TextButton(
                  onPressed: retryCallback,
                  child: Text(l10n.retry),
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
  static String _getErrorMessage(AppException exception, [AppLocalizations? l10n]) {
    l10n ??= _defaultL10n;
    switch (exception) {
      case NetworkException _:
        return l10n.errorNetworkConnection;
      case ApiKeyMissingException _:
        return l10n.errorApiKeyMissing;
      case InvalidApiKeyException _:
        return l10n.errorInvalidApiKey;
      case ApiRateLimitException _:
        return l10n.errorApiRateLimit;
      case ApiNotFoundException _:
        return l10n.errorApiNotFound;
      case ApiInternalServerError _:
        return l10n.errorApiInternalServer;
      case DatabaseException _:
        return l10n.errorDatabase;
      case ValidationException _:
        return l10n.validationFailed(exception.message);
      case PdfParseException _:
        return l10n.errorPdfParse;
      case ContentGenerationException _:
        return l10n.errorContentGeneration;
      case LlmException _:
        return l10n.errorLlmUnavailable;
      case ApiAuthException _:
        return l10n.errorApiAuth;
      default:
        return l10n.errorUnexpected;
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
  static String getRetryText(AppException exception, [AppLocalizations? l10n]) {
    l10n ??= _defaultL10n;
    switch (exception) {
      case NetworkException _:
        return l10n.retryConnection;
      case ApiRateLimitException _:
        return l10n.retryAfterWait;
      case ApiInternalServerError _:
        return l10n.tryAgain;
      default:
        return l10n.retry;
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
    _logger.e('[$context] Error: $error');
  }
  
  
  static AppException _convertToAppException(Object error, [AppLocalizations? l10n]) {
    l10n ??= _defaultL10n;
    if (error is AppException) {
      return error;
    }
    
    final errorStr = error.toString();
    
    if (errorStr.contains('ConnectionFailedError') || 
        errorStr.contains('SocketException') ||
        errorStr.contains('Network')) {
      return NetworkException(
        message: l10n.errorNetworkConnection,
        originalError: error,
      );
    }
    
    if (errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('invalid')) {
      return InvalidApiKeyException(
        message: l10n.errorInvalidApiKey,
        originalError: error,
      );
    }
    
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return ApiRateLimitException(
        message: l10n.errorApiRateLimit,
        originalError: error,
      );
    }
    
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return ApiNotFoundException(
        message: l10n.errorApiNotFound,
        originalError: error,
      );
    }
    
    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503')) {
      return ApiInternalServerError(
        message: l10n.errorApiInternalServer,
        originalError: error,
      );
    }
    
    if (error is FormatException) {
      return ValidationException(
        message: error.message,
        originalError: error,
      );
    }
    
    if (error is StateError || error is AssertionError) {
      return DatabaseException(
        message: l10n.errorDatabase,
        originalError: error,
      );
    }
    
    return NetworkException(
      message: l10n.errorUnexpected,
      originalError: error,
    );
  }
}


