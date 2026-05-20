import '../utils/logger.dart';

sealed class Result<T> {
  final T? data;
  final String? error;

  const Result({this.data, this.error});

  factory Result.success(T data) = SuccessResult<T>;
  factory Result.failure(String? error) = FailureResult<T>;

  bool get isSuccess => this is SuccessResult<T>;
  bool get isFailure => this is FailureResult<T>;

  S fold<S>(S Function(T data) onSuccess, S Function(String error) onFailure) {
    if (this is SuccessResult<T>) {
      return onSuccess(data as T);
    }
    return onFailure(error ?? 'Unknown error');
  }

  Result<S> map<S>(S Function(T data) transform) {
    if (this is SuccessResult<T>) {
      return Result.success(transform(data as T));
    }
    return Result.failure(error);
  }

  static Future<Result<T>> capture<T>(Future<T> Function() block, {String? context}) async {
    try {
      return Result.success(await block());
    } catch (e) {
      if (context != null) {
        Logger(context).w('capture failed: $e');
      }
      return Result.failure(e.toString());
    }
  }

  static Result<T> captureSync<T>(T Function() block, {String? context}) {
    try {
      return Result.success(block());
    } catch (e) {
      if (context != null) {
        Logger(context).w('capture sync failed: $e');
      }
      return Result.failure(e.toString());
    }
  }
}

class SuccessResult<T> extends Result<T> {
  const SuccessResult(T data) : super(data: data);
}

class FailureResult<T> extends Result<T> {
  const FailureResult(String? error) : super(error: error);
}
