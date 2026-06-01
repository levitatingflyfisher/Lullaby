import 'result.dart';

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}
