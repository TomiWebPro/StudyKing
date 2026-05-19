import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

class AppErrorHandler {
  @visibleForTesting
  static Logger logger = const Logger('AppErrorHandler');

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
    final l10n = AppLocalizations.of(context)!;
    final exception = convertToAppException(error, l10n);
    _showErrorUI(context, exception, retry: retry, retryCallback: retryCallback);
  }

  static void _showErrorUI(
    BuildContext context,
    AppException exception, {
    bool retry = false,
    void Function()? retryCallback,
  }) {
    final l10n = AppLocalizations.of(context)!;
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
                  child: Text(l10n.retry),
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

  static String _getErrorMessage(AppException exception, AppLocalizations l10n) {
    return switch (exception.type) {
      ExceptionType.network => l10n.errorNetworkConnection,
      ExceptionType.apiKeyMissing => l10n.errorApiKeyMissing,
      ExceptionType.invalidApiKey => l10n.errorInvalidApiKey,
      ExceptionType.apiRateLimit => l10n.errorApiRateLimit,
      ExceptionType.apiNotFound => l10n.errorApiNotFound,
      ExceptionType.apiInternalServer => l10n.errorApiInternalServer,
      ExceptionType.apiAuth => l10n.errorApiAuth,
      ExceptionType.apiError => l10n.errorUnexpected,
      ExceptionType.database => l10n.errorDatabase,
      ExceptionType.validation => l10n.validationFailed(exception.message),
      ExceptionType.pdfParse => l10n.errorPdfParse,
      ExceptionType.contentGeneration => l10n.errorContentGeneration,
      ExceptionType.llm => l10n.errorLlmUnavailable,
      ExceptionType.unknown => l10n.errorUnexpected,
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

  static String getRetryText(AppException exception, AppLocalizations l10n) {
    return switch (exception.type) {
      ExceptionType.network => l10n.retryConnection,
      ExceptionType.apiRateLimit => l10n.retryAfterWait,
      ExceptionType.apiInternalServer => l10n.tryAgain,
      _ => l10n.retry,
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

  static void _logError(Object error, String context) {
    logger.e('[$context] Error: $error');
  }

  @visibleForTesting
  static AppException convertToAppException(Object error, AppLocalizations l10n) {
    if (error is AppException) {
      return error;
    }

    final errorStr = error.toString();

    if (errorStr.contains('ConnectionFailedError') ||
        errorStr.contains('SocketException') ||
        errorStr.contains('Network')) {
      return AppException(
        message: l10n.errorNetworkConnection,
        type: ExceptionType.network,
        originalError: error,
      );
    }

    if (errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('invalid')) {
      return AppException(
        message: l10n.errorInvalidApiKey,
        type: ExceptionType.invalidApiKey,
        originalError: error,
      );
    }

    if (errorStr.contains('429') || errorStr.contains('rate limit') || errorStr.contains('too many requests')) {
      return AppException(
        message: l10n.errorApiRateLimit,
        type: ExceptionType.apiRateLimit,
        originalError: error,
      );
    }

    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return AppException(
        message: l10n.errorApiAuth,
        type: ExceptionType.apiAuth,
        originalError: error,
      );
    }

    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return AppException(
        message: l10n.errorApiNotFound,
        type: ExceptionType.apiNotFound,
        originalError: error,
      );
    }

    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503')) {
      return AppException(
        message: l10n.errorApiInternalServer,
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
        message: l10n.errorDatabase,
        type: ExceptionType.database,
        originalError: error,
      );
    }

    return AppException(
      message: l10n.errorUnexpected,
      type: ExceptionType.unknown,
      originalError: error,
    );
  }
}
