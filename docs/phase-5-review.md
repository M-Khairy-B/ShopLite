# Phase 5 Review: Catalog Features

> **How to use this file**
> Read one section at a time. Before reading an explanation, try to explain the concept **out loud** using our ShopLite code. Say what the user does, which state the cubit is in, and what goes over the network. If you can do that, you understand it.
>
> Labels used below:
> - **[Essential]**: you will use this in every remaining phase.
> - **[Useful]**: good to know now; depth can come later.

**State of the branch at the end of Phase 5** (verified from the Git history):

```
* 42574d9 feat: sort the catalog by title (A to Z)
* 93b5468 refactor: read the API's JSON with json_serializable
* e08b38e feat: search the catalog as you type
* 17d4215 refactor: share the repository error rule; retry the chips with the catalog
* b4a2915 feat: load more products while scrolling
* 7ebe870 feat: load the catalog page by page
* 0a67677 feat: filter and sort Home through the API
* 00d1d86 feat: choose the catalog category and sort through the API
* a213a5b feat: show categories from the API
* 105928d feat: load category products from the API
* f9516e4 feat: load product categories from the API
*   24a465e (main, tag: phase-4) Merge phase-4-state-management: state management with Cubit
```

On `phase-5-catalog-features`: `flutter analyze` reports **No issues found**; `flutter test` reports **282/282 passed** (162 at the end of Phase 4). 62 files changed, +3812 −531 (before this review file).

**How we worked:** the same loop as Phase 4.
- **Test-first:** a stub first, then a test that fails for the right reason, then the code.
- **Probes:** every guard was proven by removing it, watching the right test fail, and putting it back. In Task 6 a probe caught a test that was passing **without testing anything** (section H).
- **Emulator:** every screen change was checked with the console captured, including airplane mode, fast flings, and typing through `adb`.

---

## A. What we built

### The tasks

| # | Task | Main concept | Commit(s) |
|---|---|---|---|
| 1 | Categories data | `ProductCategory`, `getJsonList`, a cache whose lifetime is the session | `f9516e4` |
| 2 | Category products from the API | Optional named parameter, encoded path segment, `ValueKey` on a provider | `105928d` |
| 3 | The Categories tab from the API | `CategoriesCubit`, `titleFromSlug`, the mock data leaves `lib/` | `a213a5b` |
| 4a | The cubit learns category and sort | `ProductsQuery` in every state, the server sorts, **stale-answer guard** | `00d1d86` |
| 4b | Home's UI uses the cubit's choices | "Page provides, view builds", `context.select`, chips that fail quietly | `0a67677` |
| 5a | The cubit learns paging | `limit`/`skip`, `hasMore` from the server's numbers, `loadMore` guards, duplicate filter | `7ebe870` |
| 5b | Infinite scroll in the UI | `ScrollController`, slivers, `TickerMode`, keys + `findChildIndexCallback` | `b4a2915` |
| — | Clean-up | `RepositoryErrors` mixin (third copy), chips retry with the catalog | `17d4215` |
| 6 | Search as you type | `Timer` debounce, out-of-order answers, `close()`, `TextEditingController` | `e08b38e` |
| 7 | `json_serializable` | `build_runner`, `@JsonKey`, `checked: true`, committed `.g.dart` files | `93b5468` |
| Q3 | Sort by title (A to Z) | One enum value; exhaustive `switch`es find every place; titles compared ignoring case | `42574d9` |

### The layers now

```
main.dart                      creates ApiClient + DummyJsonProductsRepository
   │
ShopLiteApp                    RepositoryProvider<ProductsRepository>.value
   │
Screens                        BlocProvider(create: ... context.read<ProductsRepository>() ...)
   │   Home: ProductsCubit + CategoriesCubit     Categories / CategoryProducts / Search / Details
   ▼
Cubits (with RepositoryErrors)  emit states; guards: isClosed, stale query, loadMore, debounce
   │
ProductsRepository             getProducts(skip, limit, category, sort) · searchProducts · getProduct · getCategories (cached)
   │
ApiClient → dio → DummyJSON    /products · /products/category/<slug> · /products/search?q= · /products/categories
```

### Where the code lives (new in Phase 5 marked ★)

```
lib/
  app/router.dart                                  + /search and /search/product/:id inside the Home tab
  core/errors/repository_errors.dart             ★ mixin: callRepository (the shared bug rule)
  core/utils/read_json.dart                      ★ CheckedFromJsonException → FormatException
  core/network/api_client.dart                     + getJsonList, shared private _get
  features/products/data/
    models/product.dart (+ .g.dart)                @JsonSerializable, @JsonKey(name:, fromJson:)
    models/product_category.dart (+ .g.dart)     ★ slug + name
    models/products_page.dart (+ .g.dart)          + hasMore
    products_repository.dart                       + category, sort, searchProducts, getCategories
    dummy_json_products_repository.dart            + endpoints above, sort parameters, category cache
  features/products/presentation/
    cubits/products_state.dart                     + ProductsQuery; Loaded gets hasMore/isLoadingMore/loadMoreError
    cubits/products_cubit.dart                     + selectCategory, changeSort, loadMore, retryLoadMore
    widgets/product_grid.dart                      StatefulWidget: ScrollController, slivers, keys, footer
    widgets/paged_product_grid.dart              ★ grid + "loading more" / "Try again" footer
    screens/home_screen.dart                       HomeScreen (providers) + _HomeView; search button
  features/categories/presentation/
    cubits/categories_{state,cubit}.dart         ★ + reloadIfFailed
    screens/categories_screen.dart                 from the API (24 real categories)
    screens/category_products_screen.dart          from the API, infinite scroll
  features/search/presentation/                  ★ search_state, search_cubit, search_screen
build.yaml                                       ★ json_serializable: checked: true, create_to_json: false
test/helpers/
  mock_products.dart                               moved here from lib/ (+ generatedProducts)
  fake_catalog.dart (+ test)                     ★ what the fake "server" does: filter, sort
  fake_products_repository.dart                    + categories, categoriesError, sort, search, requestedPages
```

**Deleted from `lib/`:** `mock_products.dart` (moved to `test/helpers/`) and `product_catalog.dart` (local filtering; the server does it now).

**New packages** (constraints in `pubspec.yaml`):
- **App:** `json_annotation: ^4.12.0`.
- **Dev:** `json_serializable: ^6.15.2`, `build_runner: ^2.16.1`, `fake_async: ^1.3.3`.

---

## B. Let the server do the work [Essential]

### Category and sort became request parameters

Phase 4's test question was *"does changing it need a new request?"* In Phase 5 the answer became **yes**, so the choices moved from the widget into the cubit.

```dart
// DummyJsonProductsRepository
final path = category == null
    ? '/products'
    : '/products/category/${Uri.encodeComponent(category)}';
queryParameters: {'skip': skip, 'limit': limit, 'select': _fields, ..._sortParameters(sort)},
```

- **Why the server sorts:** the cheapest product, "Lemon" (id 31, $0.79), is **one place outside** the first page of 30. Sorting the loaded page locally would show a $0.99 product first, which is wrong. Only the server sees everything.
- **Optional named parameters** (`String? category`, `ProductSort sort = featured`): existing callers kept working unchanged, and combinations come for free.
- **`Uri.encodeComponent`:** the slug comes from a URL the user could type. Without encoding, `../carts` is normalized away ("dot-segment removal") and reaches **another endpoint**. Encoded, it stays one opaque segment.

### Every state knows its query

```dart
final class ProductsQuery extends Equatable {
  const ProductsQuery({this.category, this.sort = ProductSort.featured});
  ...
}
sealed class ProductsState extends Equatable {
  const ProductsState({required this.query});
  final ProductsQuery query;
  @override
  List<Object?> get props => [query];
}
```

- The screen can show the selected chip and sort **even while loading or after an error**.
- Subclasses use **`...super.props`**. Otherwise two states that differ only in their query look equal. That would weaken tests, and it would merge states in flows without a `Loading` in between, like load-more.

### The stale-answer guard [Essential]

```dart
Future<void> _show(ProductsQuery query) async {
  emit(ProductsLoading(query: query));
  final result = await _fetchFirstPage(query);
  if (isClosed || state.query != query) return;   // closed, or the user chose something else
  emit(result);
}
```

**The emitted state is the record of what the user currently wants.** The same comparison is used in four places:

| Where | What arrives late |
|---|---|
| `selectCategory` / `changeSort` (4a) | The Laptops page after the user tapped Beauty |
| `refresh` | A refresh answer after the user changed category |
| `_loadNextPage` (5a) | Page 2 of the old category |
| `SearchCubit._search` (6) | "mac" results after "phone" was sent, or after the field was cleared |

---

## C. Categories [Essential]

- **`ProductCategory`, not `Category`:** `material.dart` already exports a `Category`, and the two names would clash.
- **The cache lives in the repository:**
  ```dart
  List<ProductCategory>? _categories;
  Future<List<ProductCategory>> getCategories() async {
    final cached = _categories;
    if (cached != null) return cached;
    final json = await _apiClient.getJsonList('/products/categories');
    final categories = _parse(() => ProductCategory.listFromJson(json));
    return _categories = List.unmodifiable(categories);
  }
  ```
  - **Lifetime:** a cubit lives as long as its screen. The repository lives for the whole session, which is exactly how long "fetch once per session" should last. **Keep data where its lifetime matches how long it stays valid.**
  - **Only successes are cached.** A failed request throws before the last line, so no extra `if` is needed.
- **`getJsonList` + a shared `_get`:** the `try` / `on DioException` wiring exists once. Phase 7's `post` will reuse it.
- **`titleFromSlug`** turns `home-decoration` into "Home Decoration" for the app bar. It was checked against all 24 real categories, so a deep link needs no `extra`.
- **The mock catalog left `lib/`.** Everything in `lib/` should be app code, and from `test/` the app *can't* import it by mistake. (Correction from Task 3: unused code would most likely be tree-shaken from a release build anyway, so "dead weight in the app" was not the real reason.)
- **The "N products" line was dropped.** It would need 24 requests per visit. If a screen needs N requests to show one list, the API is missing an endpoint. In Phase 9 that becomes one SQL `count(*) … group by`.

---

## D. Home: page provides, view builds [Essential]

```dart
class HomeScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final repository = context.read<ProductsRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProductsCubit(repository: repository)..load()),
        BlocProvider(create: (context) => CategoriesCubit(repository: repository)..load()),
      ],
      child: const _HomeView(),
    );
  }
}
```

- **Every `context` inside `_HomeView` is below both providers.** That fixes Phase 4's "State's own context is above the provider" problem for good.
- **The chips sit outside the catalog's loading/error `switch`**, so they stay visible while another category loads.
- **`context.select((ProductsCubit c) => c.state.query.category)`** rebuilds the chip row only when the selected category changes. `BlocBuilder(buildWhen: …)` would work too; `context.watch` would rebuild on every Loading/Loaded.
- **Chips are a shortcut, not the content.** If the categories fail, there are simply no chips, and the catalog still shows.
- **Retry together (clean-up):** "Try again" and pull-to-refresh also call `CategoriesCubit.reloadIfFailed()`. It only reloads after an error, because reloading loaded chips would hide them for a moment. Both requests run at the same time with `Future.wait`.
- **Local filtering and sorting moved to `test/helpers/fake_catalog.dart`**, where the fake repository plays the server.

---

## E. Pagination in the cubit [Essential]

```dart
bool get hasMore => products.isNotEmpty && skip + products.length < total;   // ProductsPage
```

- **Offset pagination** (`limit` = 30, `skip` = how many already shown). The server's `total` says how long the list is. **Cursor pagination** ("give me what comes after id X") exists too and survives inserts better. DummyJSON doesn't offer it.
- **`hasMore` comes from the server's `skip`**, not from how many products the app kept, because the app may drop duplicates.
- **`products.isNotEmpty &&`:** an empty page always means the end. Otherwise a server that miscounts makes the app ask forever.

### One `ProductsLoaded`, three more fields

`ProductsLoaded(products, {hasMore, isLoadingMore, loadMoreError, refreshError, query})`. During "load more" the products **stay on screen** and only the footer changes, which is the same reasoning as `refreshError` in Phase 4.

### `loadMore` is safe to call often

```dart
Future<void> loadMore() async {
  final current = state;
  if (current is! ProductsLoaded || !current.hasMore || current.isLoadingMore ||
      current.loadMoreError != null) return;
  await _loadNextPage(current);
}
Future<void> _loadNextPage(ProductsLoaded current) async {
  emit(ProductsLoaded(current.products, hasMore: true, isLoadingMore: true, query: current.query));
  final result = await _withNextPage(current);
  if (isClosed || state.query != current.query) return;
  emit(result);
}
```

| Detail | Why |
|---|---|
| `emit(isLoadingMore: true)` **before** the first `await` | The second of ten quick calls already sees "loading more" and returns. That's how fast scrolling asks once |
| `loadMoreError != null` → return | After a failure, scrolling alone must not send request after request while offline. Only `retryLoadMore()` (the button) tries again |
| Duplicate filter by id | If the catalog shifts between pages, page 2 can repeat a product. Showing it twice looks broken and gives two cards the same key |
| `return await` inside `try` | Without `await`, the Future's error would arrive after the `try` had finished |

---

## F. Infinite scroll in the UI [Essential]

### The `ScrollController` belongs to the widget

```dart
class _ProductGridState extends State<ProductGrid> {
  final _scrollController = ScrollController();          // created with the State
  initState:  addListener(_reportIfNearEnd); _reportIfNearEndAfterLayout();
  didUpdateWidget: if (widget.products.length != oldWidget.products.length) _reportIfNearEndAfterLayout();
  dispose:    _scrollController.dispose();                // also removes the listener
}
void _reportIfNearEnd() {
  if (widget.onEndReached == null || !_scrollController.hasClients) return;
  if (_scrollController.position.extentAfter < _nearEndDistance) widget.onEndReached!();
}
```

- **Not in the cubit:** scrolling is how this widget works, not what the app knows.
- **Not in `build`:** a new controller every build jumps to the top on every page and leaks the old ones.
- **`extentAfter`:** how much is left to scroll below what's visible. 600 dp is about two rows.
- **`addPostFrameCallback`:** when 2 products don't fill the screen there is nothing to scroll, so the check must also run **after layout**, and again when the count changes.

### The cubit is the source of truth, because the widget can be one frame old

A fling's ballistic animation ticks **before** the rebuild in the same frame. So the scroll listener can run while the widget still has the **previous** state's config. A stack trace proved it: `BallisticScrollActivity._tick` called the listener before `build`. Hiding `onEndReached` after an error therefore wasn't enough, so the "no retry after failure" rule moved into `loadMore()`. **Guards belong in the cubit.**

### Slivers [Useful]

```dart
CustomScrollView(controller: _scrollController, slivers: [
  SliverPadding(sliver: SliverGrid(delegate: SliverChildBuilderDelegate(...))),
  if (footer != null)
    SliverLayoutBuilder(builder: (context, constraints) => SliverToBoxAdapter(
      child: TickerMode(enabled: constraints.remainingCacheExtent > 0, child: footer))),
])
```

- A `CustomScrollView` scrolls several slivers as **one** list: the grid, then the footer.
- **`SliverToBoxAdapter` always builds its child**, even far below the screen, and a built spinner redraws every frame. That made `pumpAndSettle` time out. `TickerMode` stops its animation until it's near the screen.
- **The spinner shows whenever `hasMore`**, not only while loading. A footer that appeared only once loading started would grow in below the screen, where nobody sees it.

### Keys [Useful]

```dart
ProductCard(key: ValueKey(product.id), ...)
SliverChildBuilderDelegate(..., findChildIndexCallback: _indexOfCard)
```

| Setup | When the order changes |
|---|---|
| No keys | Flutter reuses elements **by position**, so product 1's state ends up on product 2's card |
| Keys only | In a lazy sliver, Flutter can't find a moved key, so it builds a new element |
| Keys + `findChildIndexCallback` | Flutter finds the card's new index and **moves** the element (test: `same(before)`) |

Duplicate keys trigger a framework assertion in debug builds (confirmed by probe), which is one more reason for the duplicate filter.

**Device check (5b):**
- 8 fast flings: pages 30 and 60 were each requested once.
- Offline at the end: all 90 products stayed, the error footer showed, and 20 more flings sent no requests.
- "Try again" loaded page 4 once.
- End of the catalog (194/194): no spinner and no extra request.

---

## G. One place for the bug rule [Essential]

Three cubits had copied the same `catch`, so the third copy triggered an extraction:

```dart
mixin RepositoryErrors<S> on BlocBase<S> {
  Future<T> callRepository<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AppException {
      rethrow;                                         // expected: offline, 404…
    } catch (error, stackTrace) {
      if (!isClosed) addError(error, stackTrace);      // a bug: report it
      throw const UnknownException();
    }
  }
}
class ProductsCubit extends Cubit<ProductsState> with RepositoryErrors<ProductsState> { ... }
```

- **A mixin adds methods without being the parent.** `on BlocBase<S>` lets it use `isClosed` and `addError`. `addError` is `@protected`, so a top-level function couldn't call it cleanly.
- **Each cubit still chooses its own error state** in its own `on AppException catch`.
- **Two layers together guarantee "never throws":** each cubit catches only `AppException`, and the mixin makes sure nothing else arrives. That's why `Future.wait` in `_reload` needs no `try`.
- **Without `on AppException { rethrow; }`,** an offline user would see "Something went wrong" instead of "You're offline", and every offline moment would be logged as a bug.

---

## H. Search as you type [Essential]

```dart
void queryChanged(String text) {
  _debounceTimer?.cancel();                         // first, always
  final query = text.trim();
  if (query == state.query) return;                 // e.g. a trailing space
  if (query.isEmpty) { emit(const SearchIdle()); return; }
  _debounceTimer = Timer(debounce, () => _search(query));   // 400 ms
}
@override
Future<void> close() {
  _debounceTimer?.cancel();
  return super.close();
}
```

| Rule | What breaks without it |
|---|---|
| Cancel **before** the "same text" check | Type "phonex", then delete the x: the "phonex" timer still fires, and the screen says "No results for phonex" while the field says "phone" |
| `state.query` changes when a search **starts** | (Not a guard, a fact.) An answer arriving during the next pause is still shown, because it answers the newest search actually sent |
| Stale guard in `_search` | "mac" answering after "phone" replaces the newer results |
| `close()` cancels the timer | Leaving mid-pause: the timer fires, `emit(SearchLoading…)` throws `StateError` on the closed cubit. The throw happens **before** the request |
| `submit` (keyboard button) cancels the timer | The user said they're done typing, so the search goes now and the waiting one is dropped |

- **`SearchIdle` exists**, unlike Phase 4's "no `Initial` state" rule, because this screen **waits for the user**.
- **The screen owns the `TextEditingController`** (created and disposed with the `State`), like the grid's `ScrollController`. The clear button uses `ValueListenableBuilder`, because the controller *is* a `ValueNotifier` (Phase 4 warm-up). `controller.clear()` doesn't call `onChanged`, so `_clear` tells the cubit.
- **Scope:** search shows the first 30 results, plus "Showing the first 30 of 45 results. Type more to narrow them down." when more match. It has no infinite scroll and no sort.
- **Device check:** typing "phone" fast sent **one** request. Leaving before the pause ended sent none and logged no error.

### `fakeAsync` [Useful]

```dart
fakeAsync((async) {
  cubit.queryChanged('phone');
  async.elapse(SearchCubit.debounce - const Duration(milliseconds: 1));
  expect(repository.searchQueries, isEmpty);
  async.elapse(const Duration(milliseconds: 1));
  expect(repository.searchQueries, ['phone']);
});
```

**The trap the probe found:** a `Completer` created **outside** `fakeAsync` delivers its answer through the real event loop, which `flushMicrotasks()` never runs. The answer never arrived, so "clearing drops the answer" passed even with the guard removed. **Create Completers inside the fake zone.** (`testWidgets` bodies already run in one.)

---

## I. Generated JSON code [Useful]

```dart
@JsonSerializable()
class Product {
  factory Product.fromJson(Map<String, dynamic> json) => readJson(() => _$ProductFromJson(json));
  @JsonKey(name: 'price', fromJson: _centsFromDollars)
  final int priceCents;
  @JsonKey(name: 'thumbnail')
  final String thumbnailUrl;
  ...
}
int _centsFromDollars(num dollars) => (dollars * 100).round();
```

- **`part 'product.g.dart';`** holds `_$ProductFromJson`, written by `dart run build_runner build`. It's the same type checks as the hand-written `switch`.
- **`checked: true` (in `build.yaml`):** every failure becomes one `CheckedFromJsonException` that names the class and the key. Without it, bad data throws a bare `TypeError` that `_parse` doesn't catch. It would reach the mixin as a "bug", be logged as **ours**, and show "Something went wrong".
- **`readJson`** turns that into the `FormatException` our `fromJson` promises, so repositories don't depend on json_serializable.
- **The proof of a safe refactor:** every existing model test passed **unchanged**. The only new behaviour is a better message, for example `Could not read ProductsPage: … "products". (… Product: … "price" …)`.
- **Committed `.g.dart` files:** a fresh clone builds, and reviews show generated changes. **The risk is stale files.** A new `required` field fails to compile, which is the friendly case. A new **nullable** field, or a renamed `@JsonKey`, compiles and is **silently ignored**. While editing models, run `dart run build_runner watch`.
- **A small difference:** whole numbers are read as `(v as num).toInt()`, so `2.0` (or `2.7` → 2) is accepted where the old code wanted an exact `int`. It's harmless with DummyJSON, and no test covers it.

---

## J. Dart and Flutter concepts new in Phase 5

| Concept | Example | Remember |
|---|---|---|
| Mixin with `on` | `mixin RepositoryErrors<S> on BlocBase<S>` | Adds methods; may use the `on` type's members, even `@protected` ones |
| Generic method + function parameter | `Future<T> callRepository<T>(Future<T> Function() call)` | A method reference works too: `callRepository(_repository.getCategories)` |
| `Timer` | `Timer(debounce, () => _search(query))` | Not owned by anything: cancel it yourself |
| `Future.wait` | `await Future.wait([a, b])` | Runs together; done when all are done |
| `return await` in `try` | `_fetchPage` | Catches the Future's own error |
| Record types in tests | `({int skip, int limit, String? category, ProductSort sort})` | `requestedPages` entries |
| `ScrollController` / `extentAfter` | `ProductGrid` | Owned by the `State`; dispose it |
| `addPostFrameCallback` | `_reportIfNearEndAfterLayout` | Run after layout; check `mounted` |
| Slivers | `CustomScrollView`, `SliverGrid`, `SliverToBoxAdapter`, `SliverLayoutBuilder` | One scrollable made of parts |
| `TickerMode` | footer spinner | Stops animations below it |
| `findChildIndexCallback` | `_indexOfCard` | Lets a lazy sliver move keyed children |
| `ValueListenableBuilder` on a controller | clear button | A `TextEditingController` is a `ValueNotifier` |
| `context.select` | selected category | Rebuild for one value only |
| `part` / `part of` | `product.g.dart` | Generated code in the same library (sees private names) |
| `@JsonKey(name:, fromJson:)` | `priceCents` | Rename a key; plug in a conversion |

---

## K. Important decisions

| Decision | Why | Revisit when |
|---|---|---|
| Category, sort, paging and search done by the server | Only the server sees all 194 products | — |
| One `getProducts` with optional `category` and `sort` | Combinations for free; old callers unchanged | — |
| Categories cached in the repository | Its lifetime is the session | Phase 9 (Supabase) |
| Mock catalog only in `test/` | `lib/` is app code; can't be imported by mistake | — |
| No product counts on the Categories tab | 24 requests per visit | Phase 9: one SQL query |
| Load-more state inside `ProductsLoaded` | The products stay visible; only the footer changes | — |
| Spinner footer whenever `hasMore` | A footer that appears late grows in off-screen | — |
| "No retry after failure" rule in the cubit | The widget's config can be one frame old | — |
| `RepositoryErrors` mixin | Third copy of the same rule | — |
| Chips retry only after an error | Reloading loaded chips hides them for a moment | — |
| `SearchCubit` separate from `ProductsCubit` | Needs an idle state, a timer and no paging | If search needs paging or sort |
| Search shows the first 30 + a note | Honest and simple; "phone" matches 23 | If users need more |
| Debounce 400 ms in a `Timer` (no Bloc event transformers) | Cubit is enough | — |
| `checked: true` + `readJson` | Keeps the `FormatException` promise and names the field | — |
| `create_to_json: false` project-wide | Nothing is sent yet | **Phase 6** (cart) |
| Commit `.g.dart` files | Fresh clones build; reviews show changes | If a CI check is added |
| `get_it` still postponed | Nothing new needed it | **Phase 6** |

---

## L. Testing

### What Phase 5 added (282 tests in total; 162 at the end of Phase 4)

| File | Tests (Phase 4 → now) | Protects |
|---|---|---|
| `products_cubit_test.dart` | 14 → 36 | Category, sort, stale answers, paging, load-more guards, duplicates, retry |
| `home_screen_test.dart` | 12 → 22 | Chips from the API, loading more, failures, retry, chips coming back |
| `search_cubit_test.dart` | new, 17 | Debounce, trim, same text, submit, clearing, out-of-order, retry, close |
| `search_screen_test.dart` | new, 11 | Typing, one request, keyboard button, states, clear button, the note, in-app navigation, leaving mid-pause |
| `dummy_json_products_repository_test.dart` | 7 → 21 | Endpoints, encoding, sort parameters (one test per sort), search, category cache, wrong shapes |
| `categories_cubit_test.dart` | new, 9 | Load, empty, retry, bug, close, `reloadIfFailed` |
| `product_grid_test.dart` | new, 8 | End reached (top, near end, short list, more arrive), footer, ticker, keys |
| `fake_catalog_test.dart` | new, 11 | The fake server's filter and sort (moved from deleted app tests); title order, ignoring case |
| `home_sort_test.dart` | 6 → 8 | The sort sheet reorders the grid, including "Title: A to Z" |
| `repository_errors_test.dart` | new, 5 | Answer, AppException passes through, bug reported, sync throw, closed cubit |
| Models, API client, router, categories screens, text format | +14 | `ProductCategory`, `getJsonList`, `/search` routes, error messages that name the field |
| `accessibility_test.dart` | +2 cases | The search screen, light and dark |

### Techniques new in Phase 5

| Technique | Use |
|---|---|
| `fakeAsync` + `async.elapse` / `flushMicrotasks` | Debounce timing without waiting |
| Completer gates, set per request | Make answers arrive in the wrong order on purpose |
| `generatedProducts(n)` | Lists long enough to scroll and page |
| `requestedPages` / `searchQueries` | Assert exactly what went over the "network" |
| `scrollProductGridToEnd` | Shared "user scrolls to the bottom" helper |
| `tester.binding.hasScheduledFrame` | Prove an off-screen animation is stopped |
| `same(before)` on `tester.element` | Prove an element was moved, not rebuilt |
| `ensureVisible` + `pumpAndSettle` before `tap` | Tap something that was scrolled into view |
| `tester.testTextInput.receiveAction(TextInputAction.search)` | Press the keyboard's search button |
| `isA<FormatException>().having(...)` | Check part of an error message |
| **Probe every guard** | 6 search probes, 5 grid/cubit probes, 3 JSON probes, 2 title-sort probes, and more |
| Test data made for one rule | The 8 mock titles sort the same with or without case, so a test with its own titles (`iPhone 5s` among `Ice Cream`, `Juice`, `Zipper Bag`) guards the case rule. Without `toLowerCase()`, only that test failed |

---

## M. Debugging stories and lessons

| What happened | Cause | Lesson |
|---|---|---|
| Scrolling retried after a failed load-more | The fling's ballistic tick ran the listener before the rebuild (old config) | Guards belong in the cubit, the source of truth |
| The error footer "wasn't there" in a test | It was built below the viewport | Changed the UX: spinner whenever `hasMore` |
| `pumpAndSettle` timed out at startup | The always-built footer spinner animated off-screen | `SliverLayoutBuilder` + `TickerMode` |
| `tap` missed "Try again" | `ensureVisible` hadn't been laid out yet | `pumpAndSettle` between scrolling and tapping |
| A guard test passed with the guard removed | Its `Completer` was made outside `fakeAsync` | Create async test objects inside the fake zone |
| A JSON error named `description`, not `price` | The test data lacked **two** fields | Make broken test data broken in exactly one way |
| ANR dialogs, frozen app | The emulator's sensors service at ~90% CPU (older snapshot) | Cold boot: `emu kill` + `-no-snapshot-load` |
| "Typing quickly" searched "ph" | `adb` typed at ~385 ms per letter, about the debounce | Send all keys in one `input keyevent` |
| Typed letters disappeared | The keyboard's stylus tutorial took them | Look at a screenshot before trusting logs |
| BACK didn't leave search | The first BACK closes the keyboard | Two BACKs, or the app bar's back button |
| Categories missing after an offline start | Nothing retried them | Fixed in the clean-up (`reloadIfFailed`) |
| Two `uri:` lines per request | `LogInterceptor` logs the request and the response | Count pairs, as in Phase 4 |
| How does DummyJSON order `iPhone`? | Asked the real API before writing the fake: it ignores case (`Ice Cream`, `iPad`, `iPhone`, `Iron`) and compares numbers by value (`iPhone 6` before `iPhone 12`) | Check the real server's behaviour before copying it into a fake |
| `adb pull /sdcard/ui.xml` failed | Git Bash rewrote `/sdcard/...` into a Windows path | `MSYS_NO_PATHCONV=1` before `adb` commands |

**Corrections I made to my own explanations:**
- **Task 3:** tree-shaking, not dead weight, decides what ships in a release build.
- **Task 4a:** missing `...super.props` wouldn't hurt *today's* Home flows (a `Loading` sits in between). It would weaken tests and break load-more.

---

## N. Git in Phase 5

- **One branch**, `phase-5-catalog-features`, with **11 commits** before this review. Two tasks were split into a cubit commit and a UI commit (4a/4b, 5a/5b), and each commit works on its own.
- **`refactor:`** for the two commits that kept behaviour identical: the clean-up and json_serializable. The proof is that the existing tests passed without changes.
- **`git add -A lib test`** when files were deleted or moved (Tasks 3 and 4b), then `git status` to check the expected counts of deleted, new and modified files.
- **Generated files are committed** together with the model change that produced them.
- **Every commit** was verified read-only after "Done": `git status -sb`, `git log`, `git show --stat`.

---

## O. Phase 5 completion checklist

| Criterion | Status | Evidence |
|---|---|---|
| Fast scrolling never requests the same page twice | ✅ | Cubit test "does nothing while the next page is already loading", screen test "fast scrolling asks for each page only once", 8 flings on the device |
| Typing "phone" quickly sends one request, not five | ✅ | Cubit + screen tests; one `q=phone` request on the device |
| A load-more error doesn't wipe the visible list | ✅ | Tests; airplane mode on the device kept all 90 products |
| No `TextEditingController`, `ScrollController` or `Timer` leaks | ✅ Timer / ⚠️ controllers | The timer cancel is proven by probe. Both controllers are disposed in `dispose()`, but no test proves it (Phase 10 `leak_tracker`) |
| Categories screen + category products from the API, cached | ✅ | Tasks 1–3 |
| Sort and filter as query parameters, kept while the screen lives | ✅ | Task 4 (sort sheet + chips) |
| `json_serializable` + `build_runner`, generated code read and compared | ✅ | Task 7 |
| `ValueKey` on grid items, and why keys matter | ✅ | Task 5b: three-case table, probe |
| Optional product details polish (carousel, `SliverAppBar`, reviews) | ⏭️ Skipped | Marked optional/useful in the roadmap |
| Knowledge check | ✅ | Q1 and Q2 answered during the tasks. Q3 ("sort by title"): your plan was correct; the code was **done by Claude at your request** (`42574d9`), checked by tests, 2 probes and the real API |
| Merged into `main` and tagged `phase-5` | ⏳ | Next step after this file is committed |

---

## P. Carried forward

| Item | Where it goes |
|---|---|
| The fake orders numbers in titles by character (`iPhone 12` before `iPhone 6`); DummyJSON orders them by value | Only if a test ever needs such titles |
| `get_it` for a growing set of services | **Phase 6** (decision) |
| `toJson` for saved models (`createToJson: true` per class) | **Phase 6** (cart) |
| `leak_tracker` to prove controllers are disposed | **Phase 10** |
| `BlocObserver` to log `addError` reports | **Phase 10** |
| Categories with product counts in one request | **Phase 9** (SQL) |
| Dismiss the keyboard when scrolling search results | Optional polish |
| Search paging or sort | If needed |
| Product details polish (carousel, `SliverAppBar`, reviews) | Optional, any time |
| Writing a cubit test yourself (from Phase 4) | Optional, any time |

---

## Q. Knowledge check

Answer each one **before** opening the Answer Key. Questions 1–3 are the roadmap's; 4–10 cover the rest of the phase.

1. Walk through what happens when the user scrolls to the bottom with the network off, then turns it on and taps "Try again".
2. Why must the search timer be cancelled in `close()`?
3. 🧑‍💻 Add "sort by title" yourself, end to end (enum value, API parameters, sheet label, tests).
4. Why does the server sort, and not the app? Give the concrete ShopLite example.
5. What is `state.query != query` protecting against? Name two places it's used.
6. Why is the categories cache in the repository and not in `CategoriesCubit`?
7. Ten `loadMore()` calls arrive while page 2 is loading. Why is only one request sent?
8. Why does the "no retry after a failure" rule live in the cubit, not in the grid widget?
9. Why does a lazy grid need both `ValueKey`s **and** `findChildIndexCallback` to keep a card's state when the order changes?
10. What does `checked: true` change, and what would the user see without it when the API sends `"price": "19.99"`?

---

## R. Readiness for Phase 6 (Cart & Wishlist)

### Phase 5 concepts you'll use right away

| Phase 5 concept | How it appears in Phase 6 |
|---|---|
| Page provides, view builds | `CartCubit` provided **above the router**, so every tab shares one cart |
| `context.select` | The cart badge rebuilds only when the item count changes |
| `RepositoryErrors` mixin | Cubits that call the local stores |
| `json_serializable` | `CartItem` gets `toJson` (`createToJson: true`) to be saved in `shared_preferences` |
| Unmodifiable lists, `Equatable` | An immutable `Cart` value object; every change returns a new cart |
| Keys | Swipe-to-delete (`Dismissible`) needs a key per item |
| Owning and disposing | Same rule for anything that listens or keeps resources |
| Decision: `get_it` | Revisit when storage services arrive with `async` setup |

### Self-assessment checklist

- [ ] I can explain why a choice that needs a request belongs in the cubit.
- [ ] I can write the stale-answer guard and say what it protects.
- [ ] I can build offset pagination: `hasMore`, a safe `loadMore`, failures that keep the list.
- [ ] I can own a `ScrollController` or `TextEditingController` correctly.
- [ ] I can explain why a widget's config can be one frame old.
- [ ] I can debounce with a `Timer` and cancel it in `close()`.
- [ ] I can test timing with `fakeAsync`, and I know the Completer trap.
- [ ] I can explain when keys matter and what `findChildIndexCallback` adds.
- [ ] I can add a field to a `@JsonSerializable` model and regenerate.

---

## Answer Key

<details>
<summary><strong>Click to show answers</strong> (try the questions first!)</summary>

**1. Offline at the bottom, then "Try again"**
Near the end, `onEndReached` calls `loadMore()`. The guards pass, and the cubit emits `Loaded(isLoadingMore: true)` before any `await`. The request fails with `NetworkException`, and the cubit emits `Loaded(products, hasMore: true, loadMoreError: NetworkException)`. The products stay, and the footer shows the message and "Try again". More scrolling calls `loadMore()`, which returns at `loadMoreError != null`, so no requests are sent. With the network back, the tap calls `retryLoadMore()`, which clears the error by emitting `isLoadingMore: true`. Page N arrives, duplicates are filtered, and `hasMore` is recomputed from the server's numbers.

**2. Cancelling the timer in `close()`**
A `Timer` isn't owned by the cubit, so closing the cubit doesn't stop it. If the user leaves during the pause, the timer still fires and calls `_search`. Its first line, `emit(SearchLoading…)`, throws `StateError: Cannot emit new states after calling close`, uncaught inside a timer callback. The `isClosed` check in `_search` comes after the `await`, too late for that first emit.

**3. Sort by title**
Done in `42574d9` (by Claude, at your request). The pieces: a new `ProductSort` value; `_sortParameters` → `{'sortBy': 'title', 'order': 'asc'}`; `sortLabel`; the fake's `sortProducts`; a repository test for the parameters, a cubit or screen test for the order, and the sheet's option list. The exhaustive `switch`es tell you every place to update, except the repository test's map, which isn't a `switch`, so write that test first. Titles are compared ignoring case, as DummyJSON does, so `iPhone` sorts with the I's.

**4. Server-side sorting**
The app only has the loaded page. The cheapest product, Lemon at $0.79 (id 31), is just outside the first 30, so a local sort would show $0.99 first. Only the server sees all 194 products.

**5. `state.query != query`**
An older, slower answer replacing what the user chose since. The emitted state records the current choice. It's used in `_show` (category/sort), `refresh`, `_loadNextPage`, and `SearchCubit._search`.

**6. Where the categories cache lives**
Lifetime. A cubit dies with its screen; the repository lives for the whole session, which is how long "fetch once per session" should last. It also serves both Home's chips and the Categories tab.

**7. Ten `loadMore()` calls**
The first call passes the guards and emits `isLoadingMore: true` **before** its first `await`. The other nine read the new state, see `isLoadingMore`, and return.

**8. The rule in the cubit**
A fling's ballistic animation runs the scroll listener before the frame's rebuild, so the grid can still hold the previous state's `onEndReached`. Only the cubit always knows the current state.

**9. Keys + `findChildIndexCallback`**
Without keys, elements are matched by position, so the wrong product keeps the state. With keys alone, a lazy sliver can't find where a key moved and builds a new element. The callback returns the key's new index, so the existing element is moved.

**10. `checked: true`**
Every failure becomes one `CheckedFromJsonException` naming the class and key, which `readJson` turns into a `FormatException`. The repository then reports `UnexpectedResponseException`: "We received data we could not read." Without `checked`, a bare `TypeError` gets past `_parse`. The mixin treats it as a bug (logged as ours) and throws `UnknownException`, so the user sees "Something went wrong".

</details>
