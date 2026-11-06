# Phase 6 Review: Cart & Wishlist

> **How to use this file**
> Read one section at a time. Before reading an explanation, try to explain the concept **out loud** using our ShopLite code. Say what the user taps, which cart or wishlist the cubit holds, and what is written to the device. If you can do that, you understand it.
>
> Labels used below:
> - **[Essential]**: you will use this in every remaining phase.
> - **[Useful]**: good to know now; depth can come later.

**State of the branch at the end of Phase 6** (verified from the Git history):

```
* 439c3d0 feat: format prices with intl and show them through one PriceText widget
* 1326c2a feat: save the cart and wishlist on the device, and restore them at startup
* 031b4ad feat: add a wishlist with hearts on cards and details, and a wishlist screen
* 2f98f56 feat: add to cart from cards and details, with a live cart badge
* 197cecc feat: show the cart with quantity controls and Undo for removals
* 9b60c48 feat: limit each cart line to 10 of a product
* 1ceed40 feat: share one cart cubit across the app
* f31bac1 feat: add the cart and cart item models
*   c9b133a (main, tag: phase-5) Merge phase-5-catalog-features: catalog features
```

On `phase-6-cart-wishlist`: `flutter analyze` reports **No issues found**; `flutter test` reports **464/464 passed** (282 at the end of Phase 5). 70 files changed, +4450 −107 (before this review file).

**How we worked:** the same loop as Phase 5.
- **Test-first:** a stub first, then a test that fails for the right reason, then the code.
- **Probes:** every guard was proven by removing it, watching the right test fail, and putting it back. **A probe that fails nothing means either a missing test or code that does nothing.** Phase 6 had both kinds (section M), and code that did nothing was removed.
- **Emulator:** every screen change was checked on the real API. The emulator caught three bugs the tests had passed: a snackbar covering the "Add to cart" button, and two grey hearts.

---

## A. What we built

### The tasks

| # | Task | Main concept | Commit |
|---|---|---|---|
| 1 | Cart models | `CartItem` snapshot, immutable `Cart`, money in cents, `toJson` | `f31bac1` |
| 2 | One `CartCubit` for the app | `Cubit<Cart>`, provided above the router, bloc's "first emit" rule | `1ceed40` |
| Q2 | Max 10 per product | **Decisions by you, code by Claude**: the rule in `Cart`, `add` caps, `updateQuantity` throws | `9b60c48` |
| 3 | The cart screen | `Dismissible` + Undo, keys by product, reading `context` early, `Wrap` for large text | `197cecc` |
| 4 | Add to cart + the badge | `context.select`, one shared `addToCart`, a screen's own `ScaffoldMessenger` | `2f98f56` |
| 5 | The wishlist | Hearts that rebuild alone, a widget slot in the card, `isSelected`, `/profile/wishlist` | `031b4ad` |
| 6 | Saving on the device | `shared_preferences`, load before `runApp`, save in `onChange`, repairing saved data | `1326c2a` |
| 7 | Price formatting | `intl`'s `NumberFormat`, `PriceText`, fixed currency | `439c3d0` |

### The layers now

```
main.dart                      ApiClient + repository; await openAppPreferences(); two local stores
   │
ShopLiteApp                    RepositoryProvider<ProductsRepository>.value
   │                           MultiBlocProvider: CartCubit(store:) + WishlistCubit(store:)   ← above the router
   ▼
MaterialApp.router             every tab, pushed screen, sheet and dialog finds the same two cubits
   │
Screens & widgets              CartScreen, WishlistScreen, CartTabIcon (select), WishlistButton (select), addToCart
   │
CartCubit / WishlistCubit      emit new Cart / Wishlist values; onChange → store.save(...)
   │
Cart / Wishlist (models)       the rules: limit of 10, snapshots, insertAt for Undo, toggle
   │
CartLocalStore / WishlistLocalStore → SharedPreferencesWithCache → the device
```

### Where the code lives (new in Phase 6 marked ★)

```
lib/
  main.dart                                        async: opens the preferences before runApp
  app/app.dart                                     + MultiBlocProvider with the two cubits; requires both stores
  app/app_preferences.dart                       ★ openAppPreferences(): the allow list of keys
  app/app_shell.dart                               the Cart tab uses CartTabIcon
  app/router.dart                                  + /profile/wishlist and /profile/wishlist/product/:id
  core/utils/price_formatter.dart                  intl NumberFormat (en_US, USD)
  core/widgets/price_text.dart                   ★ a price on screen, with equal-width digits
  features/cart/
    data/models/cart.dart (+ .g.dart)            ★ maxQuantityPerItem, add, remove, updateQuantity, insertAt
    data/models/cart_item.dart (+ .g.dart)       ★ the product snapshot; lineTotalCents
    data/cart_local_store.dart                   ★ load (with repair) and save
    presentation/cubits/cart_cubit.dart          ★ add (returns how many), remove, increment, decrement, restore, clear
    presentation/add_to_cart.dart                ★ the one "Add to cart" action + snackbar
    presentation/screens/cart_screen.dart          rewritten: lines, Undo, subtotal, empty state
    presentation/widgets/cart_line_tile.dart     ★ one line: "$9.99 each", − 2 +, line total, delete
    presentation/widgets/cart_tab_icon.dart      ★ the badge
  features/wishlist/                             ★ models (+ .g.dart), local store, cubit, button, screen
  features/products/presentation/
    screens/product_details_screen.dart            + bottom bar (− 1 + and Add to cart), heart, own ScaffoldMessenger
    widgets/product_card.dart                      + onAddToCart, wishlistButton slot
    widgets/product_grid.dart, paged_product_grid.dart   pass both through
    widgets/quantity_selector.dart                 + onChanged
  features/profile/presentation/screens/profile_screen.dart   + "Wishlist" entry
test/helpers/
  fake_stores.dart                               ★ FakeCartStore, FakeWishlistStore, useInMemoryDeviceStorage
  pump_app.dart                                    withAppProviders (was withProductsRepository), pumpAppAt, pumpShopLiteApp
```

**Changed outside `lib/` and `test/`:**
- `android/gradle.properties`: `kotlin.incremental=false` (section L).
- The generated plugin lists for Linux, macOS and Windows, updated by `flutter pub add`.

**New packages** (constraints in `pubspec.yaml`):
- **App:** `shared_preferences: ^2.5.6`, `intl: ^0.20.3`.
- **Dev:** `shared_preferences_platform_interface: ^2.4.2`, for the in-memory device storage in tests.

---

## B. The cart as a value [Essential]

### A snapshot, not the whole `Product`

```dart
factory CartItem.fromProduct(Product product, {int quantity = 1}) {
  return CartItem(
    productId: product.id,
    title: product.title,
    thumbnailUrl: product.thumbnailUrl,
    unitPriceCents: product.priceCents,   // the price when it was added
    quantity: quantity,
  );
}
```

- **Only what the cart screen shows** is copied. It's saved on the device, and descriptions can be long. This avoids the roadmap's mistake "storing whole `Product` JSON".
- **The snapshot-price rule (decided at the start of the phase):** a line keeps the price from when it was **first** added, also when the same product is added again, and also across restarts. A cart saved last week shows last week's prices. **That's fine for display only**, because the order's real total is worked out by the server from its own prices (Phase 9). It's written in `CartItem.unitPriceCents` and `CartLocalStore`'s documentation.

### Immutable: every change returns a new cart

```dart
Cart({required List<CartItem> items}) : items = List.unmodifiable(items);
const Cart.empty() : items = const [];
```

- **The Phase 4 trap can't happen.** `state.items.add(x); emit(state)` throws, because the list is unmodifiable. Without that, it would change the cart in place, emit the *same* object, and the screen would not rebuild.
- **The list is copied**, so changing the list you passed in can't change the cart later. Probe: removing `List.unmodifiable` failed both tests (one for each case).
- **Two constructors:** `Cart.empty()` can be `const`, because `const []` is known at compile time. `List.unmodifiable(...)` runs when the app runs, so `Cart(items:)` can't be `const`.
- **`Equatable`:** two carts with the same lines are `==`. That's what lets bloc skip a change that changes nothing.

### Money in whole cents

```dart
int get subtotalCents => items.fold(0, (sum, item) => sum + item.lineTotalCents);
int get lineTotalCents => unitPriceCents * quantity;
```

Checked with real doubles: `5 * 19.99` is `99.94999999999999`. In cents it's exactly `9995`. (A first draft claimed `3 * 9.99` comes out wrong. It doesn't, so that test uses the `5 * 19.99` example.)

### Two kinds of wrong input

| Call | What happens | Why |
|---|---|---|
| `remove(99)`, `updateQuantity(99, 5)` (not in the cart) | Ignored | Can happen innocently: a tap arriving just after the line was removed |
| `add(product, quantity: 0)`, `updateQuantity(1, 0)` | `ArgumentError` | A bug in the calling code |
| `add` past the limit (8 in the cart, add 4) | **Capped at 10** | Tapping "Add to cart" again is a normal user action |
| `updateQuantity(1, 11)` | `ArgumentError` | The screen only steps by one and disables "+" at 10, so asking for 11 is a bug |

### Q2: max 10 per product (decisions by you, code by Claude)

Your four decisions:
1. **The rule lives in `Cart`**, so every path follows it, including saved carts and, later, merged carts.
2. **`add` caps** at 10 instead of refusing.
3. **`updateQuantity` throws** outside 1–10.
4. **`CartCubit.increment` returns at the limit**, before asking `Cart` for 11. Probe: without it, `increment` at 10 **threw**, because `updateQuantity(1, 11)` is an error.

`const maxQuantityPerItem = 10` is the only place the number is written. The cart, the cubit, the "+" button and the snackbar messages all use that name.

One line was removed: `add` first had `if (updated == current) return this;`. Removing it failed no test, because `_withLine` builds an equal cart anyway. **Code that changes nothing visible is noise.**

---

## C. One cart for the whole app [Essential]

```dart
// ShopLiteApp.build, above MaterialApp.router
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => CartCubit(store: widget.cartStore)),
    BlocProvider(create: (_) => WishlistCubit(store: widget.wishlistStore)),
  ],
  child: MaterialApp.router(...),
)
```

- **Where it's provided decides how long it lives** (Phase 4). Above the router, the cubit lives as long as the app, and every tab, pushed screen, sheet and dialog finds **the same** one. A test checks it with `same(...)` from Home, Details and the Cart tab.
- **Under the `/cart` route** (the roadmap's question), only widgets inside that route could find the cubit. Home's "Add to cart", the details screen and the badge in the tab bar are outside it, so they would get a `ProviderNotFoundException`. And the cart would live only as long as that page, not as long as the app.
- **`create`, not `.value`:** this provider creates the cubit, so it owns it and closes it. Probe: `.value(value: CartCubit())` failed "closed when the app goes away".
- **`Cubit<Cart>` with no sealed states:** nothing waits for the network, so there is no loading or error. The state *is* the cart. The cubit decides **when** it changes; `Cart`'s methods decide **how**.
- **`−` stops at 1.** Taking a line out is `remove`'s job (swipe or the delete button), so a tap on `−` can't make a line disappear by accident.

### The "first emit" rule [Essential]

```dart
// inside bloc's emit
if (state == _state && _emitted) return;
```

Bloc skips a state equal to the current one **only after the cubit's first emit**. A new cubit would still emit an equal state. Two consequences:
- **`remove`, `clear` and `WishlistCubit.remove` check for themselves** whether anything would change. A test with **no `seed`** guards each check, because `seed` counts as a first emit, so seeded tests never noticed.
- **The `added == 0` guard in `add`** was removed in Task 4 (a probe proved it did nothing: a line can only be full *after* an emit) and **came back in Task 6**, test first. A cubit started from a saved, full line has not emitted yet. See section H.

---

## D. The cart screen [Essential]

### Undo puts back one line, as it was

```dart
void _removeWithUndo(BuildContext context, int index, CartItem item) {
  final cubit = context.read<CartCubit>();          // read now...
  final messenger = ScaffoldMessenger.of(context);   // ...while context is alive
  cubit.remove(item.productId);
  messenger..hideCurrentSnackBar()..showSnackBar(SnackBar(
    content: Text('Removed ${item.title}'),
    action: SnackBarAction(label: 'Undo', onPressed: () => cubit.restore(index, item)),
  ));
}
```

- **`Cart.insertAt`** puts back only that line: same place, same quantity, same price. An index that's too big (lines removed since) goes to the end. A product that was added again since is left alone, so the newer line wins. Emulator: remove the palette, take the MacBook from 9 to 10, tap Undo. The palette came back in the middle, and the MacBook **stayed at 10**.
- **Read the `context` before removing.** The dangerous case is the **last** line. Removing it switches the screen to the empty state, the list leaves the tree, and a later Undo would read from a dead `context`: "Looking up a deactivated widget's ancestor is unsafe". (The first probe passed, because `ListView.builder` passes the *list's* context, which stays alive while other lines remain. The missing test, "Undo works even after the last line", was added.)
- **No `isClosed` check** (unlike Home's sort Undo in Phase 4): this cubit lives as long as the app, so it outlives every snackbar.

### Keys belong to the product

`Dismissible(key: ValueKey(item.productId), ...)`. With `ValueKey(index)`, the next row inherits the removed row's position **and its key**, and Flutter reports "A dismissed Dismissible widget is still part of the tree". The probe failed 4 tests.

### Smaller lessons

- **Disabled, not silent:** `−` is disabled at 1, and `+` at `maxQuantityPerItem`. The button and the rule use the same constant, so they can't disagree.
- **A delete button as well as the swipe:** a swipe is hard to discover and hard to do with a screen reader. Both run `_removeWithUndo`.
- **`Wrap` instead of `Row`:** on a 320 px phone with doubled text, `$199.90` squeezed the "Subtotal" label into a strip about one letter wide, and the footer grew to about 1,000 px. With `Wrap`, the price moves below the label.
- **One semantics group per quantity:** a screen reader hears "Quantity of Essence Mascara Lash Princess, 2", then the two buttons.

---

## E. Adding to the cart and the badge [Essential]

### The badge rebuilds alone

```dart
final count = context.select((CartCubit cart) => cart.state.itemCount);
```

- **`CartTabIcon` is its own small widget.** A cart change rebuilds that icon, not the tab bar or the shell. A test counts rebuilds with Flutter's `debugOnRebuildDirtyWidget` hook. Probe: making the shell depend on the cart failed it.
- **An honest detail:** here `select(itemCount)` behaves like `watch` today, because every cart change also changes the count. What saves the rebuilds is the separate widget. `select` states the intent. (For the hearts in section F, `select` is what really matters.)
- **"9+" above 9, but a screen reader hears the exact number** ("12 items"), and "1 item", not "1 items".

### One `addToCart` for every button

```dart
void addToCart(BuildContext context, Product product, {int quantity = 1}) {
  final cart = context.read<CartCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);          // read before: "View cart" is tapped later
  final added = cart.add(product, quantity: quantity);
  messenger..hideCurrentSnackBar()..showSnackBar(...);   // one of three messages
}
```

- **`add` returns how many it really added**, so the snackbar tells the truth: "Added 3 × …", "Added 2 × …. You now have 10, the limit per product.", or "Your cart already has 10 × …, the limit per product." The cubit knows the cart, so the calculation belongs there, not in each screen.
- **Same rule as Undo: read the `context` early.** Add from a category's product card, then press back: the snackbar outlives that screen. Probe: reading the router inside "View cart" failed with the same "deactivated widget's ancestor" error.
- **The card gets a callback, `onAddToCart`.** No callback means no button, so products code doesn't depend on the cart.

### A snackbar over the button (found on the emulator)

1. "Add to cart" sat in the scrolling content, and the long limit message covered it.
2. Moving it to the Scaffold's `bottomNavigationBar` was **not enough**. With nested Scaffolds, snackbars show in the **outermost** one, the tab shell's, just above the tabs.
3. **The fix: the details screen gets its own `ScaffoldMessenger`.** Its snackbars appear above its own bottom bar and go away with the screen.

The first test passed against the broken layout. It now states the real rule: the snackbar is entirely **above** the button. Probe: removing the messenger failed it.

---

## F. The wishlist [Essential]

- **`Wishlist` works like `Cart`:** immutable, newest first, one snapshot per product (title, photo, price), so the wishlist screen works offline.
- **`toggle` needs no "nothing changed" check** (it always changes something). **`remove` does** (the first-emit rule).
- **`context.select` really matters here:**
  ```dart
  final saved = context.select((WishlistCubit w) => w.state.contains(product.id));
  ```
  Saving the mascara rebuilds **one** heart. With `watch`, every heart on the screen rebuilds. A test counts the rebuilds, and the `watch` probe fails it. (It didn't for the badge.)
- **The card gets a ready-made widget, not a callback** (`wishlistButton`, built by `wishlistButtonBuilder`). If the card were told "saved or not", the whole grid would rebuild on every change. The heart reads the wishlist itself.
- **`isSelected` makes the heart a toggle button.** TalkBack hears "selected" with the tooltip "Remove from wishlist".
- **The heart sets its own color.** An `AppBar` and a `ListTile` give their buttons one color for every state, which made saved hearts **grey** on the emulator. Two tests now check the color the icon is really drawn in (the `RichText` style), and both fail on the old code.
- **No "Add to cart" on the wishlist screen** (changed from the plan): a wishlist entry has the price from when it was saved, maybe weeks old. Tapping it opens the details screen, which loads today's price.
- **`/profile/wishlist/product/1`, not `/product/1`:** the product opens inside the Profile tab, and back returns to the wishlist. Both *look* the same, so the test checks the address with `GoRouterState.of(element).uri`.

---

## G. Saving on the device [Essential]

### `shared_preferences` is for small, non-secret data

- The cart and the wishlist are **small and not secret**, so `shared_preferences` is the right place. It's not a database, and **not secure**. Tokens go in `flutter_secure_storage` in Phase 7.
- **`SharedPreferencesWithCache` with an allow list:** opened once, it reads the allowed keys into memory. After that, **reading is synchronous** and writing is `async`. Keys not in the allow list are neither read nor written. Writing one throws `ArgumentError` (probe 10).

### Load before `runApp`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();     // plugins need the engine first
  ...
  final preferences = await openAppPreferences(); // a few milliseconds
  runApp(ShopLiteApp(..., cartStore: CartLocalStore(preferences), wishlistStore: WishlistLocalStore(preferences)));
}
```

- **The roadmap gave two choices:** load before showing the UI, or show a loading state. Loading first is simpler and takes milliseconds, and the first frame already shows the right badge. A test checks that frame without waiting for anything.
- **`ensureInitialized()`:** `runApp` would normally start the engine, but we use a plugin before it.

### Save once, in `onChange`

```dart
CartCubit({CartLocalStore? store}) : _store = store, super(store?.load() ?? const Cart.empty());

@override
void onChange(Change<Cart> change) {
  super.onChange(change);
  unawaited(_store?.save(change.nextState));
}
```

| Why `onChange` | |
|---|---|
| One place | Covers `add`, `remove`, `increment`, `decrement`, `restore`, `clear`, and any method added later |
| The right cart | `change.nextState` is the cart that was really emitted. A method saving `state` before `emit` would save the old one |
| Only real changes | It runs after each emit, never on rebuilds. That's the roadmap's mistake "saving on every rebuild" |
| `unawaited` | The screen doesn't wait for the disk |

- **The store is optional in the cubit** (`null` in plain tests) but **required by `ShopLiteApp`**, so the real app can't forget to save.

### Saved data is repaired, not trusted (your three decisions)

```dart
Cart load() {
  final saved = _preferences.getString(key);
  if (saved == null) return const Cart.empty();                  // the first launch
  try {
    final json = jsonDecode(saved);
    if (json is! Map<String, dynamic>) throw const FormatException('...');
    return _withinLimits(Cart.fromJson(json));                    // > 10 → 10, < 1 → dropped
  } on FormatException catch (error) {
    _log('Could not read the saved cart, so it starts empty. $error');
    return const Cart.empty();
  }
}
```

1. **A quantity above 10 becomes 10; below 1, the line is dropped.** Saved data may come from an older version, or have been edited. `Cart(items:)` and `fromJson` don't check quantities, so the store does.
2. **Unreadable data gives an empty cart**, with a debug log, instead of a crash. The next save replaces it. A user who can't open the app at all would lose more.
3. **Loaded before `runApp`** (above).

**Watch out later:** if `CartItem`'s JSON changes (a new required field, a renamed key), every saved cart becomes "unreadable", and users start with an empty cart. A future change to a saved model needs a plan for the old data.

### Only device errors are caught

```dart
Future<void> save(Cart cart) async {
  try {
    await _preferences.setString(key, jsonEncode(cart.toJson()));
  } on PlatformException catch (error) {
    _log('Could not save the cart. $error');     // a full disk: the cart stays in memory
  }
}
```

A bug in our own code still shows. Probe 10 is the example: with the wishlist key missing from the allow list, every save throws `ArgumentError`. If `save` caught everything, the app would look fine all session, and the wishlist would be empty after every restart.

---

## H. The deferred guard [Essential]

```dart
int add(Product product, {int quantity = 1}) {
  final before = state.quantityOf(product.id);
  final cart = state.add(product, quantity: quantity);
  final added = cart.quantityOf(product.id) - before;
  if (added == 0) {
    return 0;     // the line is full: nothing changed
  }
  emit(cart);
  return added;
}
```

| Phase 6 moment | Without the guard |
|---|---|
| Task 4 (cubit always starts empty) | A line can only be full after some `add`s, so the cubit has already emitted, and bloc skips the equal cart. **The guard did nothing; a probe proved it, and it was removed** |
| Task 6 (cubit starts from a saved cart) | A saved, full line exists **before any emit**. Bloc lets the equal cart through: every listener rebuilds, and `onChange` rewrites the same data to disk |

**The lesson:** whether a guard is needed depends on how the object is **created**, not only on what its methods do. The test came first: "adding at the limit, to a full saved line, emits nothing" failed, then the guard came back.

---

## I. Prices on screen [Useful]

```dart
final _usDollars = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');

String formatPrice(int cents) {
  assert(cents >= 0, 'Price cannot be negative: $cents');
  return _usDollars.format(cents / 100);     // "$1,999.99"
}
```

- **The one place a double appears.** Doubles go wrong in *arithmetic*: every sum can leave a tiny error that piles up. Here the double is made once, never added or stored, and right away rounded to the nearest cent. A test checks **every** price from $0.00 to $10,000.00 (a million values, under a second), plus totals in the billions.
- **The truncation probe** showed the danger: `1999 / 100` is really 19.98999…, so cutting off the digits shows **$19.98**. Rounding shows $19.99.
- **Currency vs locale:**
  - The **currency** belongs to the data. DummyJSON prices are dollars, so `name: 'USD'` is fixed. Taking it from the phone would show € for a dollar price: a wrong price.
  - The **locale** is only how numbers are written. `en_US` is a choice. A German phone with `de_DE` would show `1.999,99 $`, which is the same amount written the German way. If the app is translated, that's the one line to change.
- **`PriceText`** shows a price alone, with equal-width digits (`FontFeature.tabularFigures()`), so a changing total doesn't shift the text beside it. **`formatPrice`** is for a price inside a sentence ("$9.99 each", snackbars, screen-reader labels). `PriceText` calls `formatPrice`, so the two can't disagree.
- **Made once:** the `NumberFormat` is a top-level `final`, not built on every draw.

---

## J. Dart and Flutter concepts new in Phase 6

| Concept | Example | Remember |
|---|---|---|
| `List.unmodifiable` | `Cart(items:)` | Copies, and throws on any change |
| `fold` | `subtotalCents`, `itemCount` | Reduce a list to one value |
| `createToJson` / `explicitToJson` | `@JsonSerializable(createToJson: true, explicitToJson: true)` | `explicitToJson` makes nested objects plain maps |
| `ArgumentError.value` | `updateQuantity(1, 11)` | For the calling code's mistakes |
| Bloc's first-emit rule | `if (state == _state && _emitted) return;` | A new or seeded-from-storage cubit can emit an equal state |
| `Cubit.onChange` | save the cart | Runs after each real emit; call `super` |
| `unawaited` (`dart:async`) | `unawaited(_store?.save(...))` | Says "not awaiting this is on purpose" |
| `Dismissible` | cart lines | Needs a unique key; must leave the tree once dismissed |
| `SnackBarAction` | Undo, View cart | Runs later: read `context` before |
| Nested `ScaffoldMessenger` | details screen | Snackbars show in the nearest messenger's Scaffold |
| `Badge` | `CartTabIcon` | `isLabelVisible`, `label` |
| `Semantics` + `ExcludeSemantics` | badge, quantity group | Say the useful thing once |
| `IconButton.isSelected` / `selectedIcon` | heart | A toggle for screen readers |
| `PositionedDirectional` | heart over the photo | `end`, not `right`, for right-to-left languages |
| `async main` + `ensureInitialized` | `main.dart` | Needed before using a plugin |
| `SharedPreferencesWithCache` | `openAppPreferences()` | Sync reads after opening; allow list |
| `on PlatformException` | `save` | Catch the device's errors, not ours |
| `jsonEncode` / `jsonDecode` (`dart:convert`) | the stores | `jsonDecode` returns `dynamic`; check its shape |
| `NumberFormat.simpleCurrency` (`intl`) | `formatPrice` | Make once; give `locale` and `name` |
| `FontFeature.tabularFigures()` | `PriceText` | Equal-width digits |

---

## K. Important decisions

| Decision | Why | Revisit when |
|---|---|---|
| A line keeps its first price, also across restarts | Display only; the server prices the order | **Phase 9** |
| Snapshot, not the whole product | Small to save; only what's shown | — |
| Max 10 per product, the rule in `Cart` (your decisions) | Every path follows it | — |
| `add` caps; `updateQuantity` throws | A user action vs a bug | — |
| `CartCubit` and `WishlistCubit` above the router | One cart and one wishlist for the whole app | — |
| Undo restores only the removed line, in place (option A, yours) | Later changes stay | — |
| `−` stops at 1 | Deleting is the delete button's job | — |
| Details screen has its own `ScaffoldMessenger` | Snackbars above its own bottom bar | — |
| No "Add to cart" on the wishlist screen | The saved price may be old | If you want it: load the product first |
| The wishlist is reachable without login | It's local data | **Phase 7** (protected `/profile`) |
| `shared_preferences` with an allow list | Small, non-secret data | — |
| Load before `runApp` (yours) | Milliseconds; right badge on the first frame | If startup grows slow |
| Save in `onChange`, not awaited | One place; the UI doesn't wait | — |
| Saved quantities repaired: > 10 → 10, < 1 dropped (yours) | Old versions or edited data | — |
| Unreadable saved data → empty, with a debug log (yours) | Better than a crash | When a saved model's JSON changes |
| `save` catches only `PlatformException` | Bugs must surface | — |
| Prices as `en_US` / USD | The data is dollars | If the app is translated |
| `get_it` still postponed | Constructor injection still fits (two stores) | **Phase 7** start |
| `kotlin.incremental=false` | Pub cache and project on different drives | If the pub cache moves to D: |

---

## L. Testing

### What Phase 6 added (464 tests in total; 282 at the end of Phase 5)

| File | Tests (Phase 5 → now) | Protects |
|---|---|---|
| `cart_test.dart` | new, 34 | Totals in cents, immutability, add/remove/update, the limit of 10, `insertAt`, JSON |
| `cart_cubit_test.dart` | new, 23 | Every method, no-change checks (unseeded), the limit, `restore`, saving through a store, the deferred guard |
| `cart_screen_test.dart` | new, 16 | Lines, totals, `+`/`−`, swipe, delete button, Undo (also after the last line), empty state, large text |
| `add_to_cart_test.dart` | new, 14 | The selector's quantity, the three messages, snackbar above the button, View cart, leaving the screen, cards on Home/category/search |
| `wishlist_test.dart` | new, 14 | Toggle, newest first, remove, JSON |
| `wishlist_button_test.dart` | new, 10 | Toggle, tooltips, `isSelected`, one heart rebuilds, the drawn color |
| `cart_local_store_test.dart` | new, 9 | Round trip across a restart, the key, unreadable data, repair, failing save |
| `cart_item_test.dart` | new, 8 | Snapshot, line total, `withQuantity`, JSON |
| `wishlist_screen_test.dart` | new, 8 | Newest first, prices, remove, empty state, opens in the Profile tab |
| `wishlist_cubit_test.dart` | new, 7 | Toggle, remove (unseeded), starting from and saving to a store |
| `accessibility_test.dart` | 17 → 25 | Cart with lines, wishlist, light and dark |
| `cart_badge_test.dart` | new, 6 | Count, "9+", what a screen reader hears, rebuilds only the badge |
| `wishlist_local_store_test.dart` | new, 6 | Round trip, unreadable data, keys only `{wishlist}` |
| `wishlist_item_test.dart` | new, 5 | Snapshot, JSON |
| `cart_provider_test.dart` | new, 3 | Same cart everywhere, shared changes, closed with the app |
| `price_text_test.dart` | new, 3 | Text, style kept, equal-width digits |
| `persistence_test.dart` | new, 2 | The real app survives closing; the first frame shows the saved badge |
| `wishlist_provider_test.dart` | new, 2 | Same wishlist everywhere; closed with the app |
| `price_formatter_test.dart` | 7 → 9 | Commas; every price up to $10,000; huge totals |
| `router_test.dart`, `quantity_selector_test.dart` | +2 | `/profile/wishlist`; `onChanged` |

### Techniques new in Phase 6

| Technique | Use |
|---|---|
| **Unseeded tests** | `seed` counts as a first emit, so a no-change check needs a test that starts from the constructor |
| `same(...)` across screens | Prove one cubit is shared |
| `debugOnRebuildDirtyWidget` | Count which widgets rebuild |
| Reading the drawn `RichText` style | Check the color or font features the user really sees |
| Comparing `tester.getRect` of two widgets | "The snackbar is entirely above the button" |
| `GoRouterState.of(element).uri` | Check the address a screen opened at, when two look the same |
| `FakeCartStore` / `FakeWishlistStore` (`implements`) | Record every save; start from any saved cart |
| `useInMemoryDeviceStorage` + opening again | A real store over fake storage; opening again is "after a restart" |
| A failing fake platform | `setString` throws `PlatformException`, to test a full disk |
| `pumpWidget(SizedBox())` then relaunch | Close the whole app, then start it again |
| `pumpAppAt(tester, location)` | Start the real router at any page |
| **Probe every guard** | 48 probes this phase. Two found weak tests (Undo after the last line, the Profile-tab address), two found code that did nothing (`return this` in `add`, the Task 4 `added == 0` guard), and one found a test that could never fail |

---

## M. Debugging stories and lessons

| What happened | Cause | Lesson |
|---|---|---|
| `clear()` on a new cubit emitted | Bloc skips equal states only after the first emit | Unseeded tests for no-change checks |
| A `remove` probe passed at first | Seeded tests: `seed` is a first emit | Same |
| `if (updated == current) return this;` failed nothing when removed | `_withLine` already builds an equal cart | Remove code that changes nothing |
| The "read early" probe passed at first | `ListView.builder` passes the list's context, alive while lines remain | Test the last line: the list leaves the tree |
| `ValueKey(index)` | The next row inherits the dismissed row's key | Key by product |
| The cart footer grew to ~1,000 px | A `Row` squeezed "Subtotal" to one letter per line | `Wrap`; test small phones with large text |
| A snackbar covered "Add to cart" | Snackbars show in the outermost Scaffold | The screen's own `ScaffoldMessenger` |
| The first snackbar test passed the broken layout | It tested the wrong thing | Write the real rule: entirely above |
| The `added == 0` guard failed nothing (Task 4) | The cubit always started empty | Removed, then **back in Task 6** with a saved start |
| Saved hearts were grey (app bar, list) | `AppBar` and `ListTile` force one button color | The icon sets its own color; test the drawn color |
| The "opens in Profile" test passed with `/product/1` | Both addresses look the same | Check `GoRouterState.uri` |
| "Not found → no heart" could never fail | A heart needs a loaded product, so the types guarantee it | Removed the test |
| First Android build failed: "different roots" | Kotlin's incremental cache breaks when the pub cache (C:) and the project (D:) are on different drives | `kotlin.incremental=false` |
| The truncation probe showed $19.98 for $19.99 | `1999 / 100` is 19.98999… | Round when formatting; test every price |
| `adb` typed "maacbook" | A known emulator input glitch | Read the field before trusting the result |
| `screencap` gave white images | This emulator's GPU surface isn't captured | Check the accessibility tree (`uiautomator dump`) instead |

**Corrections I made to my own explanations:**
- **Task 1:** `3 * 9.99` does **not** come out wrong as a double (it's `29.97`); `5 * 19.99` does.
- **Task 3:** the row's `context` doesn't die with the row; `ListView.builder` passes the list's. The danger is the last line.
- **Task 4:** `select(itemCount)` saves nothing over `watch` today; the separate widget does.

---

## N. Git in Phase 6

- **One branch**, `phase-6-cart-wishlist`, with **8 commits** before this review: one per task, plus Q2 on its own.
- **`git push -u origin phase-6-cart-wishlist`** on the first push, then `git push`.
- **Generated files are committed** with the model change that produced them (`cart.g.dart`, `wishlist.g.dart`, …). `build_runner` once rewrote the existing `.g.dart` files with different line endings only; those were restored, so the commit showed only real changes.
- **Plugin files** (`generated_plugins.cmake`, `GeneratedPluginRegistrant.swift`) changed because of `flutter pub add`, and were committed with the package.
- **No secrets:** the stores hold the cart and wishlist only. Checked before every commit.
- **Every commit** was verified read-only after "Done": `git status -sb`, `git log`, `git show --stat`, `git rev-parse HEAD @{u}`.

---

## O. Phase 6 completion checklist

| Criterion | Status | Evidence |
|---|---|---|
| Totals always correct, no floating-point artifacts | ✅ | `cart_test` (cents, `5 × 19.99` = 9995), `cart_screen_test`, `price_formatter_test` (every price to $10,000) |
| Killing and reopening the app restores the cart and wishlist | ✅ | `persistence_test`, store round trips; emulator `am force-stop` + relaunch: badge 2, heart still selected, $19.98 |
| Badge, cart screen and details button stay in sync | ✅ | `cart_badge_test`, `add_to_cart_test`, `cart_provider_test`; emulator: from 9 items to 10, the badge went to "9+", and "View cart" showed 10 × mascara, $99.90 |
| Undo after swipe-delete restores the item with its quantity | ✅ | `cart_screen_test` (including after the last line); emulator: palette back in the middle, MacBook stayed at 10 |
| `CartItem` snapshot and immutable `Cart` with totals | ✅ | Task 1 |
| `CartCubit` above the router, max quantity per item | ✅ | Task 2, Q2 |
| Cart screen: quantity, swipe + Undo, subtotal, checkout button, empty state | ✅ | Task 3 (checkout says "coming soon" until Phase 8) |
| Badge + "Add to cart" on cards and details, with a snackbar | ✅ | Task 4 |
| Wishlist: hearts on cards and details, screen, empty state | ✅ | Task 5 |
| Local stores, load at startup, save on change, snapshot-price rule written down | ✅ | Task 6 |
| `intl` formatting through `PriceText` | ✅ | Task 7 |
| Unit tests for `Cart` math and `CartCubit` with a fake store | ✅ | 34 + 23 tests |
| Knowledge check | ✅ | Q1 and Q3 answered during the tasks. **Q2 ("max 10 per item"): the four decisions are yours, the code was written by Claude** (`9b60c48`), checked by tests and 4 probes |
| Merged into `main` and tagged `phase-6` | ⏳ | Next step after this file is committed |

---

## P. Carried forward

| Item | Where it goes |
|---|---|
| `get_it` for a growing set of services | **Phase 7** start (decision) |
| Is the wishlist behind login too? | **Phase 7** (protected `/profile`) |
| Cart on logout: keep it as a guest cart | **Phase 7** (roadmap task 8) |
| Merging the guest cart into the server cart on login | **Phase 9** |
| The server prices the order; `unitPriceCents` is ignored | **Phase 9** |
| The checkout button | **Phase 8** |
| An order copies the cart lines, prices included; `clear()` after placing it | **Phase 8** |
| A plan for old saved data when a saved model's JSON changes | Whenever `CartItem` or `WishlistItem` changes |
| Snackbars cover the cart's checkout button for ~4 s (standard Material); a floating snackbar is an option | Optional polish |
| Prices in the phone's locale | Only if the app is translated |
| `kotlin.incremental=false` | Remove if the pub cache moves to the same drive (`PUB_CACHE`) |
| Windows Developer Mode for plugins | Only to build the Windows desktop app |
| `leak_tracker`, `BlocObserver`, the `QuantitySelector` lifecycle logs | **Phase 10** |

---

## Q. Knowledge check

Answer each one **before** opening the Answer Key. Questions 1–3 are the roadmap's; 4–10 cover the rest of the phase.

1. Why can't the app's subtotal be trusted by a server?
2. 🧑‍💻 Implement "max 10 per item" and its tests yourself.
3. Where exactly is `CartCubit` provided, and what would break if you moved it under the `/cart` route?
4. Why does `Cart`'s constructor wrap the list in `List.unmodifiable`? Write the two-line `CartCubit` bug it prevents.
5. Why does `add` cap at 10, while `updateQuantity(1, 11)` throws?
6. Why does `_removeWithUndo` read the cubit and the messenger **before** removing the line? Which case would crash otherwise?
7. Snackbars covered the details screen's "Add to cart" even in `bottomNavigationBar`. Why, and what fixed it?
8. You save the mascara on Home. How many `WishlistButton`s rebuild with `context.select`, and how many with `context.watch`? Why doesn't `ProductCard` rebuild?
9. Why does saving happen in `onChange`, and why did the `added == 0` guard have to come back in Task 6?
10. `formatPrice` divides cents by 100 into a double. Why is that safe, and why is the currency fixed while the locale is only a choice?

---

## R. Readiness for Phase 7 (Forms & Authentication)

### Phase 6 concepts you'll use right away

| Phase 6 concept | How it appears in Phase 7 |
|---|---|
| App-wide cubit above the router | `AuthCubit`, provided the same way; the router's `redirect` listens to it |
| A state that is just a value vs sealed states | `AuthCubit` needs sealed states again: `Unknown` → `Authenticated` / `Unauthenticated` |
| Loading stored data before `runApp` | Reading the tokens at startup; but checking them with `/auth/me` is a network call, so a splash state while `Unknown` |
| Local stores behind a class | `TokenStorage` over `flutter_secure_storage`: tokens are secret, so **not** `shared_preferences` |
| Catch only expected errors | The refresh interceptor: catch 401, let bugs surface |
| Reading `context` before an `await` or a later tap | Login: show errors and navigate after the request returns (`mounted`) |
| `ArgumentError` vs ignoring | Form validators vs server errors |
| The snapshot-price rule | The trust boundary again: the server decides who you are, as it decides prices |
| Decision: `get_it` | Revisit with `TokenStorage`, the interceptor and the auth repository sharing `ApiClient` |

### Self-assessment checklist

- [ ] I can make an immutable value class with `Equatable` and an unmodifiable list.
- [ ] I can explain why money is int cents, and where a double is allowed.
- [ ] I can say where an app-wide cubit is provided, and what changes if it moves.
- [ ] I can explain bloc's first-emit rule and why unseeded tests matter.
- [ ] I can build swipe-to-delete with Undo and say why the key is the product.
- [ ] I can explain when to read `context` before a callback runs.
- [ ] I can use `context.select` and say when it really saves rebuilds.
- [ ] I can save state in `onChange` and load it before `runApp`.
- [ ] I can decide what to do with saved data that is wrong or unreadable.
- [ ] I can test a real store with in-memory device storage.

---

## Answer Key

<details>
<summary><strong>Click to show answers</strong> (try the questions first!)</summary>

**1. Trusting the subtotal**
It's computed on the user's device from prices the device stored, so it can be old or changed. A line keeps its price from when it was added (maybe last week), and a modified app or a direct API call can send any number. The server must price the order from its own products table (Phase 9's `place_order`).

**2. Max 10 per item**
Done in `9b60c48`: **your four decisions, code by Claude.** The rule is in `Cart`, with one constant, `maxQuantityPerItem`. `add` caps (8 + 4 → 10), `updateQuantity` throws outside 1–10, and `CartCubit.increment` returns at the limit before asking for 11. Tests: `increment` at 10 changes nothing; `add` at 10 adds nothing; 8 + 4 gives 10; exactly 10 is allowed; `updateQuantity(…, 11)` throws.

**3. Where `CartCubit` lives**
In `ShopLiteApp`'s `MultiBlocProvider`, above `MaterialApp.router`, with `create`. Under `/cart`, only the Cart tab's own screens could find it. Home's "Add to cart", the details screen and the badge in the tab bar are outside that route, so they would fail with `ProviderNotFoundException`. And the cart would be created and closed with that page, instead of living as long as the app.

**4. `List.unmodifiable`**
So nothing can change a cart in place. The bug: `state.items.add(CartItem.fromProduct(p)); emit(state);`. `emit` gets the same object, which is equal to itself, so once the cubit has emitted, bloc skips it and the screen doesn't change until something else rebuilds it. `onChange` doesn't run either, so nothing is saved. With the unmodifiable list, the first line throws right away. The copy also stops a list you passed in from changing the cart later.

**5. Cap vs throw**
Tapping "Add to cart" again is a normal user action, so `add` adds what still fits. `updateQuantity` is only called by `+` and `−`, which step by one and are disabled at the limits, so asking for 11 is always a bug in our code, and a bug should be loud.

**6. Reading before removing**
Undo is tapped later. When the **last** line is removed, the screen switches to the empty state and the list leaves the tree. Its `context` is then deactivated, and reading the cubit or messenger from it at Undo time throws "Looking up a deactivated widget's ancestor is unsafe".

**7. The snackbar over the button**
With nested Scaffolds, `ScaffoldMessenger.of(context)` finds the app's messenger, which shows snackbars in the outermost Scaffold: the tab shell's, just above the tabs, which is on top of the details screen's bottom bar. Giving the details screen its own `ScaffoldMessenger` makes its snackbars show in its own Scaffold, above its bottom bar, and they go away with the screen.

**8. Hearts and rebuilds**
With `select`, **one**: only the mascara's heart, because only its "is it saved?" answer changed. With `watch`, every `WishlistButton` on the screen rebuilds, because each would depend on the whole wishlist. `ProductCard` doesn't rebuild in either case, because the subscription is inside `WishlistButton`. The card was given the heart as a ready-made widget and doesn't read the wishlist itself.

**9. `onChange` and the deferred guard**
`onChange` runs after every real emit, so one override saves every change from every method, including future ones, and saves the cart that was really emitted (`change.nextState`). The guard: bloc skips an equal state only after the first emit. Before Task 6, a full line could only exist after some emits. A cubit started from a saved cart can have a full line before any emit, so `add` at the limit would emit an equal cart: pointless rebuilds and a pointless save.

**10. Dividing by 100**
No arithmetic is done with the double: it's made once, then rounded to whole cents while formatting, and its error is far below half a cent. A test checks every price up to $10,000. (Truncating instead of rounding shows $19.99 as $19.98.) The currency is a fact about the data: DummyJSON prices are dollars, so showing € would show a wrong price. The locale only decides how the number is written (`1,999.99` or `1.999,99`), which is a display preference we can change if the app is translated.

</details>
