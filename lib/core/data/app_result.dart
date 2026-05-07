sealed class AppResult<T> {
  const AppResult();

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    return switch (this) {
      AppSuccess<T>(data: final data) => success(data),
      AppFailure<T>(message: final message) => failure(message),
    };
  }
}

class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.data);

  final T data;
}

class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.message);

  final String message;
}
