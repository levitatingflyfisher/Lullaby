sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

abstract class Failure {
  const Failure(this.message, {this.cause, this.stackTrace});
  final String message;

  /// The exception behind this failure, kept whole so the screen can give
  /// the fleet's friendly sentence for it and show it behind Details.
  final Object? cause;
  final StackTrace? stackTrace;
}
