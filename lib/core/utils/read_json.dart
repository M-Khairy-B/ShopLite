import 'package:json_annotation/json_annotation.dart';

/// Runs [read] (a generated `_$ModelFromJson` call) and turns its failure
/// into a [FormatException], which is what our `fromJson` factories promise.
///
/// Repositories catch FormatException (and turn it into
/// `UnexpectedResponseException`), so they don't depend on json_serializable.
T readJson<T>(T Function() read) {
  try {
    return read();
  } on CheckedFromJsonException catch (error) {
    // e.g. 'Could not read Product: there is a problem with "price".
    // (type 'Null' is not a subtype of type 'num' in type cast)'. A nested
    // model's own message is included, so the path to the problem shows.
    throw FormatException(
      'Could not read ${error.className}: there is a problem with '
      '"${error.key}". (${error.innerError})',
    );
  }
}
