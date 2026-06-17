/// Domain-level exceptions that the UI knows how to present.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Location/GPS could not be obtained (permission denied, services off, ...).
class LocationException extends AppException {
  const LocationException(super.message);
}

/// A network/backend call failed.
class ServerException extends AppException {
  const ServerException(super.message);
}

/// The backend responded but the payload was not what we expected.
class ParsingException extends AppException {
  const ParsingException(super.message);
}
