import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// Every category in the mock catalog, in the order it first appears.
final List<String> mockCategories = mockProducts
    .map((product) => product.category)
    .toSet()
    .toList();

/// Returns the mock products in [category] (empty if there are none).
List<Product> findMockProductsByCategory(String category) {
  return mockProducts.where((product) => product.category == category).toList();
}

/// Returns the mock product with this [id], or `null` if there is none.
Product? findMockProductById(int id) {
  for (final product in mockProducts) {
    if (product.id == id) {
      return product;
    }
  }
  return null;
}

/// Temporary hard-coded catalog used while we build the UI in Phase 1.
///
/// The values are copied from the DummyJSON API (https://dummyjson.com),
/// which replaces this list in Phase 3.
const List<Product> mockProducts = [
  Product(
    id: 1,
    title: 'Essence Mascara Lash Princess',
    description:
        'The Essence Mascara Lash Princess is a popular mascara known for its '
        'volumizing and lengthening effects. Achieve dramatic lashes with this '
        'long-lasting and cruelty-free formula.',
    priceCents: 999,
    rating: 2.56,
    category: 'beauty',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp',
  ),
  Product(
    id: 2,
    title: 'Eyeshadow Palette with Mirror',
    description:
        'The Eyeshadow Palette with Mirror offers a versatile range of '
        'eyeshadow shades for creating stunning eye looks. With a built-in '
        "mirror, it's convenient for on-the-go makeup application.",
    priceCents: 1999,
    rating: 2.86,
    category: 'beauty',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/beauty/eyeshadow-palette-with-mirror/thumbnail.webp',
  ),
  Product(
    id: 6,
    title: 'Calvin Klein CK One',
    description:
        'CK One by Calvin Klein is a classic unisex fragrance, known for its '
        "fresh and clean scent. It's a versatile fragrance suitable for "
        'everyday wear.',
    priceCents: 4999,
    rating: 4.37,
    category: 'fragrances',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/fragrances/calvin-klein-ck-one/thumbnail.webp',
  ),
  Product(
    id: 7,
    title: 'Chanel Coco Noir Eau De',
    description:
        'Coco Noir by Chanel is an elegant and mysterious fragrance, featuring '
        'notes of grapefruit, rose, and sandalwood. Perfect for evening '
        'occasions.',
    priceCents: 12999,
    rating: 4.26,
    category: 'fragrances',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/fragrances/chanel-coco-noir-eau-de/thumbnail.webp',
  ),
  Product(
    id: 78,
    title: 'Apple MacBook Pro 14 Inch Space Grey',
    description:
        'The MacBook Pro 14 Inch in Space Grey is a powerful and sleek laptop, '
        "featuring Apple's M1 Pro chip for exceptional performance and a "
        'stunning Retina display.',
    priceCents: 199999,
    rating: 3.65,
    category: 'laptops',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/laptops/apple-macbook-pro-14-inch-space-grey/thumbnail.webp',
  ),
  Product(
    id: 79,
    title: 'Asus Zenbook Pro Dual Screen Laptop',
    description:
        'The Asus Zenbook Pro Dual Screen Laptop is a high-performance device '
        'with dual screens, providing productivity and versatility for '
        'creative professionals.',
    priceCents: 179999,
    rating: 3.95,
    category: 'laptops',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/laptops/asus-zenbook-pro-dual-screen-laptop/thumbnail.webp',
  ),
  Product(
    id: 121,
    title: 'iPhone 5s',
    description:
        'The iPhone 5s is a classic smartphone known for its compact design '
        "and advanced features during its release. While it's an older model, "
        'it still provides a reliable user experience.',
    priceCents: 19999,
    rating: 2.83,
    category: 'smartphones',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/smartphones/iphone-5s/thumbnail.webp',
  ),
  Product(
    id: 122,
    title: 'iPhone 6',
    description:
        'The iPhone 6 is a stylish and capable smartphone with a larger '
        'display and improved performance. It introduced new features and '
        'design elements, making it a popular choice in its time.',
    priceCents: 29999,
    rating: 3.41,
    category: 'smartphones',
    thumbnailUrl: 'https://cdn.dummyjson.com/product-images/smartphones/iphone-6/thumbnail.webp',
  ),
];
