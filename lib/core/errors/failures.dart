import 'result.dart';

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);

  /// A failure carrying the exception [e] that caused it.
  DatabaseFailure.from(Object e, StackTrace st)
      : super(e.toString(), cause: e, stackTrace: st);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}
