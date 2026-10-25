/// Something went wrong while getting data, described in the app's own terms.
///
/// `ApiClient` turns every network failure into one of these, so nothing
/// above it depends on dio. [message] is written for the user, ready to show
/// on screen.
///
/// The class is `sealed`: these six are the only kinds, so a `switch` over an
/// [AppException] can handle every case and Dart checks that none is missed.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The device couldn't reach the server at all (offline, no signal).
final class NetworkException extends AppException {
  const NetworkException()
    : super('No internet connection. Check your connection and try again.');
}

/// The server took too long to connect or to answer.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException()
    : super('The connection is too slow right now. Please try again.');
}

/// The server answered 404: what we asked for doesn't exist.
final class NotFoundException extends AppException {
  const NotFoundException()
    : super("We couldn't find what you were looking for.");
}

/// The server answered with an error status other than 404 (e.g. 500).
final class ServerException extends AppException {
  const ServerException(this.statusCode)
    : super('Something went wrong on our side. Please try again later.');

  /// The HTTP status code, e.g. 500. Useful for logs, not for users.
  final int? statusCode;
}

/// The server answered, but not with data in the shape we expected.
final class UnexpectedResponseException extends AppException {
  const UnexpectedResponseException()
    : super('We received data we could not read. Please try again later.');
}

/// Anything else, so every failure still ends up as an [AppException].
final class UnknownException extends AppException {
  const UnknownException() : super('Something went wrong. Please try again.');
}
