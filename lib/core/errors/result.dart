sealed class Result<T> {
  final T? data;
  final String? error;

  const Result({this.data, this.error});

  factory Result.success(T data) = SuccessResult<T>;
  factory Result.failure(String? error) = FailureResult<T>;

  bool get isSuccess => this is SuccessResult<T>;
  bool get isFailure => this is FailureResult<T>;
  bool get hasError => error != null;
}

class SuccessResult<T> extends Result<T> {
  const SuccessResult(T data) : super(data: data);
}

class FailureResult<T> extends Result<T> {
  const FailureResult(String? error) : super(error: error);
}
