import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';
import '../widgets/snackbar_utils.dart';

class AppErrorHandler {
  static final Logger _logger = const Logger('AppErrorHandler');
  static Logger? _testLogger;

  // Invariant English fallbacks for contexts with no AppLocalizations
  // ancestor (early startup, route teardown, global/router errors),
  // mirroring the `l10n?.key ?? 'English fallback'` pattern from
  // lib/core/utils/error_boundary.dart.
  static const _kNetworkErrorMessage =
      'Unable to connect to the server. Please check your internet connection and try again.';
  static const _kApiKeyMissingMessage =
      'API key is required. Please configure it in Settings.';
  static const _kInvalidApiKeyMessage =
      'Invalid API key. Please check your credentials in Settings.';
  static const _kApiRateLimitMessage =
      'Too many requests. Please wait a moment and try again.';
  static const _kApiAuthMessage =
      'Authentication failed. Please check your API credentials.';
  static const _kApiNotFoundMessage = 'The requested resource was not found.';
  static const _kApiInternalServerMessage =
      'The server encountered an error. Please try again later.';
  static const _kDatabaseMessage = 'A database error occurred. Please try again.';
  static const _kPdfParseMessage =
      'Unable to parse the PDF file. Please ensure it is a valid PDF.';
  static const _kContentGenerationMessage =
      'Failed to generate content. Please try again.';
  static const _kLlmUnavailableMessage =
      'The AI service is temporarily unavailable. Please try again.';
  static const _kUnexpectedMessage =
      'An unexpected error occurred. Please try again.';
  static const _kValidationPrefix = 'Validation failed: ';
  static const _kRetryText = 'Retry';
  static const _kRetryConnectionText = 'Retry Connection';
  static const _kRetryAfterWaitText = 'Retry After Wait';
  static const _kTryAgainText = 'Try again';

  @visibleForTesting
  static Logger get logger => _testLogger ?? _logger;
  @visibleForTesting
  static set logger(Logger value) {
    _testLogger = value;
  }

  @visibleForTesting
  static void logError(Object error, String context) {
    _logError(error, context);
  }

  static Future<void> handleError(
    BuildContext context,
    Object error,
    String contextName, {
    bool retry = false,
    void Function()? retryCallback,
  }) async {
    _logError(error, contextName);
    final l10n = AppLocalizations.of(context);
    final exception = convertToAppException(error, l10n);
    _showErrorUI(context, exception, retry: retry, retryCallback: retryCallback);
  }

  static void _showErrorUI(
    BuildContext context,
    AppException exception, {
    bool retry = false,
    void Function()? retryCallback,
  }) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final errorMessage = _getErrorMessage(exception, l10n);
    final snackBar = SnackBar(
      content: retry && retryCallback != null
          ? Row(
              children: [
                Icon(Icons.refresh, color: cs.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
                TextButton(
                  onPressed: retryCallback,
                  child: Text(l10n?.retry ?? _kRetryText),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getErrorIcon(exception),
                  color: cs.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
      backgroundColor: cs.errorContainer,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: retry ? 4 : 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static String _getErrorMessage(AppException exception, AppLocalizations? l10n) {
    return switch (exception.type) {
      ExceptionType.network => l10n?.errorNetworkConnection ?? _kNetworkErrorMessage,
      ExceptionType.apiKeyMissing => l10n?.errorApiKeyMissing ?? _kApiKeyMissingMessage,
      ExceptionType.invalidApiKey => l10n?.errorInvalidApiKey ?? _kInvalidApiKeyMessage,
      ExceptionType.apiRateLimit => l10n?.errorApiRateLimit ?? _kApiRateLimitMessage,
      ExceptionType.apiNotFound => l10n?.errorApiNotFound ?? _kApiNotFoundMessage,
      ExceptionType.apiInternalServer => l10n?.errorApiInternalServer ?? _kApiInternalServerMessage,
      ExceptionType.apiAuth => l10n?.errorApiAuth ?? _kApiAuthMessage,
      ExceptionType.apiError => l10n?.errorUnexpected ?? _kUnexpectedMessage,
      ExceptionType.database => l10n?.errorDatabase ?? _kDatabaseMessage,
      ExceptionType.validation => l10n?.validationFailed(exception.message) ?? '$_kValidationPrefix${exception.message}',
      ExceptionType.pdfParse => l10n?.errorPdfParse ?? _kPdfParseMessage,
      ExceptionType.contentGeneration => l10n?.errorContentGeneration ?? _kContentGenerationMessage,
      ExceptionType.llm => l10n?.errorLlmUnavailable ?? _kLlmUnavailableMessage,
      ExceptionType.unknown => l10n?.errorUnexpected ?? _kUnexpectedMessage,
    };
  }

  static IconData _getErrorIcon(AppException exception) {
    return switch (exception.type) {
      ExceptionType.network => Icons.network_check,
      ExceptionType.apiKeyMissing || ExceptionType.invalidApiKey || ExceptionType.apiAuth => Icons.key_rounded,
      ExceptionType.apiRateLimit => Icons.pause_circle,
      ExceptionType.apiNotFound => Icons.looks_one_outlined,
      ExceptionType.apiInternalServer => Icons.bug_report,
      ExceptionType.apiError => Icons.error_outline,
      ExceptionType.database => Icons.storage,
      ExceptionType.validation => Icons.info,
      ExceptionType.pdfParse => Icons.picture_as_pdf,
      ExceptionType.contentGeneration || ExceptionType.llm => Icons.wifi_tethering_off,
      ExceptionType.unknown => Icons.error_outline,
    };
  }

  static String getRetryText(AppException exception, AppLocalizations? l10n) {
    return switch (exception.type) {
      ExceptionType.network => l10n?.retryConnection ?? _kRetryConnectionText,
      ExceptionType.apiRateLimit => l10n?.retryAfterWait ?? _kRetryAfterWaitText,
      ExceptionType.apiInternalServer => l10n?.tryAgain ?? _kTryAgainText,
      _ => l10n?.retry ?? _kRetryText,
    };
  }

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

  static R? safelySync<R>(
    BuildContext context,
    R Function() operation, {
    R? defaultValue,
    String contextName = 'Operation',
  }) {
    try {
      return operation();
    } catch (error) {
      handleError(context, error, contextName);
      return defaultValue;
    }
  }

  static void showSuccess(BuildContext context, String message) {
    showSuccessSnackBar(context, message);
  }

  static void showError(BuildContext context, String message) {
    showErrorSnackBar(context, message);
  }

  static void _logError(Object error, String context) {
    // Handled, expected error paths (every caller shows a graceful
    // SnackBar/retry UI) log at warning level per AGENTS.md Logger
    // Conventions; `.e()` is reserved for unexpected exceptions that
    // require immediate investigation.
    logger.w('[$context] Error: $error');
  }

  @visibleForTesting
  static AppException convertToAppException(Object error, AppLocalizations? l10n) {
    if (error is AppException) {
      return error;
    }

    final errorStr = error.toString();

    if (errorStr.contains('ConnectionFailedError') ||
        errorStr.contains('SocketException') ||
        errorStr.contains('Network')) {
      return AppException(
        message: l10n?.errorNetworkConnection ?? _kNetworkErrorMessage,
        type: ExceptionType.network,
        originalError: error,
      );
    }

    if (errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('invalid')) {
      return AppException(
        message: l10n?.errorInvalidApiKey ?? _kInvalidApiKeyMessage,
        type: ExceptionType.invalidApiKey,
        originalError: error,
      );
    }

    if (errorStr.contains('429') || errorStr.contains('rate limit') || errorStr.contains('too many requests')) {
      return AppException(
        message: l10n?.errorApiRateLimit ?? _kApiRateLimitMessage,
        type: ExceptionType.apiRateLimit,
        originalError: error,
      );
    }

    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return AppException(
        message: l10n?.errorApiAuth ?? _kApiAuthMessage,
        type: ExceptionType.apiAuth,
        originalError: error,
      );
    }

    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return AppException(
        message: l10n?.errorApiNotFound ?? _kApiNotFoundMessage,
        type: ExceptionType.apiNotFound,
        originalError: error,
      );
    }

    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503')) {
      return AppException(
        message: l10n?.errorApiInternalServer ?? _kApiInternalServerMessage,
        type: ExceptionType.apiInternalServer,
        originalError: error,
      );
    }

    if (error is FormatException) {
      return AppException(
        message: error.message,
        type: ExceptionType.validation,
        originalError: error,
      );
    }

    if (error is StateError || error is AssertionError) {
      return AppException(
        message: l10n?.errorDatabase ?? _kDatabaseMessage,
        type: ExceptionType.database,
        originalError: error,
      );
    }

    return AppException(
      message: l10n?.errorUnexpected ?? _kUnexpectedMessage,
      type: ExceptionType.unknown,
      originalError: error,
    );
  }
}
