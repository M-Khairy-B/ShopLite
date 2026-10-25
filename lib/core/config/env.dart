/// Settings that differ between environments (development, production).
///
/// They are not written in the code: they're passed in when the app is
/// built or run, from a file in `env/`:
///
/// ```
/// flutter run --dart-define-from-file=env/dev.json
/// ```
abstract final class Env {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// The address of the API, e.g. `https://dummyjson.com`.
  ///
  /// Throws a [StateError] with instructions if the app was started without
  /// the env file, instead of failing later with a confusing network error.
  static String get apiBaseUrl {
    if (_apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is not set. Run the app with '
        '--dart-define-from-file=env/dev.json '
        '(in VS Code, use the "ShopLite (dev)" launch configuration).',
      );
    }
    return _apiBaseUrl;
  }
}
