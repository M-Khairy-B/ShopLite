import 'package:json_annotation/json_annotation.dart';
import 'package:e_commerce_learn/core/utils/read_json.dart';

// The generated code (`_$ProductFromJson`) lives in this part file, made by
// `dart run build_runner build`. Rerun it after changing the fields.
part 'product.g.dart';

/// A single product in the store.
///
/// Immutable: every field is `final`, so a product never changes after it is
/// created. If product data changes, we create a new [Product].
@JsonSerializable()
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.rating,
    required this.category,
    required this.thumbnailUrl,
  });

  /// Reads one product object from the DummyJSON API.
  ///
  /// Extra fields are ignored. Throws a [FormatException] if a field we need
  /// is missing or has the wrong type, so bad data fails here, loudly, instead
  /// of crashing somewhere in the UI later.
  factory Product.fromJson(Map<String, dynamic> json) =>
      readJson(() => _$ProductFromJson(json));

  final int id;
  final String title;
  final String description;

  /// Price in cents (e.g. 1299 = $12.99). Stored as an `int` because
  /// `double` cannot represent most decimal amounts exactly.
  @JsonKey(name: 'price', fromJson: _centsFromDollars)
  final int priceCents;

  /// Average customer rating from 0 to 5.
  final double rating;

  final String category;

  @JsonKey(name: 'thumbnail')
  final String thumbnailUrl;
}

/// The API sends dollars as a decimal (19.99). Convert once, here, and
/// round: 19.99 * 100 is 1998.9999999999998 in floating point.
int _centsFromDollars(num dollars) => (dollars * 100).round();
