import 'package:equatable/equatable.dart';

/// Base failure class for error handling across the app.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Thrown when a network/HTTP request fails (e.g. no internet).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Thrown on HTTP 401 — token expired or missing.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized. Please log in.']);
}

/// Thrown on HTTP 404.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

/// Thrown on HTTP 400 — bad request / validation errors.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Thrown on HTTP 409 — conflict (e.g. email already registered).
class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

/// Thrown on HTTP 500 or unexpected server errors.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

/// Thrown for local cache / parsing errors.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Thrown for Supabase storage errors.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
