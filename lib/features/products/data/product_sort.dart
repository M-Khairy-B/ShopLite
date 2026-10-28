/// The ways the catalog can be ordered. The server does the sorting (see
/// `DummyJsonProductsRepository`), so every page follows the same order.
enum ProductSort { featured, priceLowToHigh, priceHighToLow, topRated }
