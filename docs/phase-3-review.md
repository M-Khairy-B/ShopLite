# Phase 3 Review: Async, Networking & the Data Layer

> **How to use this file**
> Read one section at a time. Before reading an explanation, try to explain the concept **out loud** using our ShopLite code. If you can predict what happens when something fails (no internet, a slow server, bad data), you understand it.
>
> Labels used below:
> - **[Essential]**: you will use this in every remaining phase.
> - **[Useful]**: good to know now; depth can come later.

**State of the branch at the end of Phase 3** (verified from the Git history):

```
* 665804e feat: load the home catalog from the API
* e49dc3b refactor: add product catalog helpers and remove dead mock lookup
* 1b60263 feat: load product details from the API
* 3ba5546 feat: add shared loading and error views
* a4a5678 feat: add products repository backed by DummyJSON
* 4d8df5d test: share fake HTTP helpers between tests
* cd92176 feat: map network failures to typed app errors
* 2260f9c feat: add API client with environment config
* 9a03166 feat: parse products from DummyJSON API responses
*   49781ef (main, tag: phase-2) Merge phase-2-navigation: app shell and navigation
```

On `phase-3-data-layer`: `flutter analyze` reports **No issues found**; `flutter test` reports **138/138 passed** (89 at the end of Phase 2).

**How we worked:** every task was **test-first** (red for the right reason, then green). Network code was tested with a **fake network**, then confirmed with short-lived **probes against the real API**, and finally checked on the emulator **with the console captured**, including **airplane mode**.

**Running the app now requires the env file:**
- VS Code: the **"ShopLite (dev)"** launch configuration
- Terminal: `flutter run --dart-define-from-file=env/dev.json`

---

## A. What we built

### The seven tasks

| # | Task | Main concept | Commit(s) |
|---|---|---|---|
| 1 | JSON → models | HTTP basics, `fromJson`, map patterns, fixtures | `9a03166` |
| 2 | Env config + `ApiClient` | `async`/`await`, dio, timeouts, `--dart-define-from-file` | `2260f9c` |
| 3 | Typed errors | Sealed `AppException`, translating dio's errors | `cd92176` |
| 4 | Repository | Interface + implementation, constructor injection | `4d8df5d`, `a4a5678` |
| 5 | `LoadingView` + `ErrorView` | Exhaustive `switch` over errors, Retry | `3ba5546` |
| 6 | Details loads from the API | `FutureBuilder`, `initState`, `didUpdateWidget`, composition root | `1b60263` |
| 7 | Home loads from the API | Data + user choices, waiting test helpers | `e49dc3b`, `665804e` |

### The layers, end to end

```
HomeScreen / ProductDetailsScreen        FutureBuilder: loading / error / data
        │ depends on
ProductsRepository (interface)           "give me page / product"   — only AppExceptions leave it
        ▲ implemented by
DummyJsonProductsRepository              ApiClient + fromJson + FormatException → UnexpectedResponseException
        │ uses
ApiClient                                dio, base URL, timeouts, DioException → AppException
        │
dio → network → https://dummyjson.com    (base URL from env/dev.json)
```

### Where the code lives (new in Phase 3 marked ★)

```
env/dev.json                                    ★ {"API_BASE_URL": "https://dummyjson.com"}
.vscode/launch.json                             ★ "ShopLite (dev)" passes the env file
lib/
  main.dart                                       composition root: ApiClient + repository
  app/app.dart, app/router.dart                   pass the repository down
  core/
    config/env.dart                             ★ Env.apiBaseUrl
    network/api_client.dart                     ★ the only HTTP code
    errors/app_exception.dart                   ★ the sealed error family
    widgets/loading_view.dart, error_view.dart  ★
  features/products/data/
    models/product.dart                           + Product.fromJson
    models/products_page.dart                   ★ one page of results
    products_repository.dart                    ★ the interface
    dummy_json_products_repository.dart         ★ the DummyJSON implementation
    product_catalog.dart                        ★ categoriesOf, productsInCategory
test/
  fixtures/products_page.json, product.json     ★ real API responses
  helpers/fake_http.dart                        ★ fake network for ApiClient tests
  helpers/fake_products_repository.dart         ★ fake repository for screen tests
  helpers/pump_app.dart                         ★ build + wait until loaded
```

---

## B. HTTP and JSON

### A request and a response [Essential]

```
GET https://dummyjson.com/products?limit=2&skip=0&select=title,...

HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{ "products": [ {...}, {...} ], "total": 194, "skip": 0, "limit": 2 }
```

| Part | Meaning |
|---|---|
| **Method** | `GET` reads; `POST` creates; `PUT` replaces; `PATCH` changes part; `DELETE` removes |
| **Query parameters** | After `?`, joined by `&`: page size, offset, which fields |
| **Status code** | **2xx** success · **4xx** the request was wrong (404 not found, 401 not logged in) · **5xx** the server failed |
| **Body** | The data, here JSON |

An error is **a normal response with an error status**. `GET /products/99999` returns `404` with `{"message": "Product with id '99999' not found"}`, not a crash.

### `Product.fromJson`: validate at the boundary [Essential]

```dart
factory Product.fromJson(Map<String, dynamic> json) {
  return switch (json) {
    {
      'id': final int id,
      'title': final String title,
      'description': final String description,
      'price': final num price,
      'rating': final num rating,
      'category': final String category,
      'thumbnail': final String thumbnail,
    } =>
      Product(
        ...
        // The API sends dollars as a decimal (19.99). Convert once, here,
        // and round: 19.99 * 100 is 1998.9999999999998 in floating point.
        priceCents: (price * 100).round(),
        rating: rating.toDouble(),
        ...
      ),
    _ => throw FormatException('Not a valid product: $json'),
  };
}
```
- **`jsonDecode`** gives plain Dart values: objects → `Map<String, dynamic>`, arrays → `List<dynamic>`. `dynamic` means "could be anything", so `fromJson` is where untyped data becomes **typed**, **once**.
- **A map pattern** checks, for each key: it **exists**, it has the **right type**, and it gets **bound** to a typed variable. Extra keys are ignored.
- **`num`**, because JSON doesn't distinguish `10` from `10.0`. On a phone, `20` decodes as an `int`, and an `int` is never a `double`.
- **`.round()`**: `19.99 * 100` is `1998.9999999999998`; `.toInt()` would give 1998.
- **`FormatException`** fails **loudly at the boundary**, with the JSON in the message, instead of a mysterious null crash in the UI later.
- **`factory`** constructor: runs code first, and can return an object **or throw**.

### `ProductsPage`
`products`, `total`, `skip`, `limit`: the API sends products **in pages**. Items are parsed with a **type-test pattern** (`final Map<String, dynamic> json =>`), which rejects `[42]` with a `FormatException` instead of a vague `TypeError`.

### Fixtures [Useful]
`test/fixtures/*.json` are **real API responses saved as files**. Tests read them with `readFixture(...)`: fast, offline, and realistic.

---

## C. Environment config and `ApiClient`

### `async` / `await` with a real request [Essential]
- **`Future<T>`** is a value **later** (or an error).
- **`await`** pauses **only this function**. Flutter keeps drawing frames, so spinners spin and taps work.
- **Errors travel through `await`.** A failed request **rethrows** at the `await`, so `try`/`catch` works.

### Configuration from a file [Essential]

```dart
abstract final class Env {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL is not set. Run the app with '
          '--dart-define-from-file=env/dev.json ...');
    }
    return _apiBaseUrl;
  }
}
```
- **`String.fromEnvironment`** is baked in **at build time** (so it must be `const`).
- **Fail fast with instructions:** a missing env file is a **programmer error** (`StateError`), reported immediately and clearly.
- ⚠️ **Configuration is not a vault.** Anything in an app can be extracted. A public URL is fine; **secret keys belong on a server**, never in the app or in `env/dev.json`.

### `ApiClient`: the only place that talks HTTP [Essential]

```dart
ApiClient({required String baseUrl, HttpClientAdapter? httpClientAdapter})
  : _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    ) { ... }
```

| Piece | Why |
|---|---|
| One class for HTTP | Nothing else in the app imports dio |
| **Initializer list** `: _dio = Dio(...)` | Sets a `final` field before the constructor body runs |
| **Timeouts** | Never wait forever. Connect = establishing the connection; receive = waiting for the answer. |
| `LogInterceptor` in **debug only**, **without headers** | Helpful logs while developing; never leak login tokens (Phase 7) |
| `get<Object?>` + a pattern check | Don't trust the body's shape |
| `queryParameters` | dio encodes values (`,` becomes `%2C`); never glue URLs together by hand |

---

## D. Typed errors

### The family [Essential]

```dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}
```

| Type | When | Message for the user |
|---|---|---|
| `NetworkException` | Can't reach the server | No internet connection. Check your connection and try again. |
| `RequestTimeoutException` | Too slow (10 s) | The connection is too slow right now. Please try again. |
| `NotFoundException` | 404 | We couldn't find what you were looking for. |
| `ServerException(statusCode)` | Other error statuses | Something went wrong on our side. Please try again later. |
| `UnexpectedResponseException` | Data in the wrong shape | We received data we could not read. Please try again later. |
| `UnknownException` | Anything else | Something went wrong. Please try again. |

- **`sealed`**: a closed family, so a `switch` over it is **exhaustive**. A new type makes every such `switch` **fail to compile** until it's handled.
- **`Exception` vs. `Error`:** an `Exception` is an expected, recoverable problem from the outside world. An `Error` (like `Env`'s `StateError`) is a **bug** to fix in code.
- `statusCode` is kept **for logs**, never shown to users.

### The translation [Essential]

```dart
AppException _toAppException(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const RequestTimeoutException(),
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => const NetworkException(),
    DioExceptionType.badResponse => switch (error.response?.statusCode) {
      404 => const NotFoundException(),
      final statusCode => ServerException(statusCode),
    },
    DioExceptionType.cancel => const UnknownException(),
    DioExceptionType.unknown => switch (error.error) {
      SocketException() => const NetworkException(),
      FormatException() => const UnexpectedResponseException(),
      _ => const UnknownException(),
    },
  };
}
```
- **Logical-or patterns** (`A || B`), **constant patterns** (`404`), **binding patterns** (`final statusCode`), **type patterns** (`SocketException()`).
- **Exhaustive over all 9 dio types**, read from dio's installed source. That's how the newer `transformTimeout` couldn't be missed.
- **Verified against the real network:** a real 404 → `NotFoundException`; an unreachable host → dio's `connectionError` → `NetworkException`.

---

## E. The repository and dependency injection

### The interface [Essential]

```dart
abstract interface class ProductsRepository {
  Future<ProductsPage> getProducts({required int skip, required int limit});
  Future<Product> getProduct(int id);
}
```
Screens depend on **what** they can ask for, never **how** it's fetched. This pays off:
- **in tests**, with `FakeProductsRepository`;
- **in Phase 9**, with `SupabaseProductsRepository implements ProductsRepository`.

### The DummyJSON implementation

```dart
class DummyJsonProductsRepository implements ProductsRepository {
  DummyJsonProductsRepository(this._apiClient);   // constructor injection
  ...
  @override
  Future<Product> getProduct(int id) async {
    final json = await _apiClient.getJson('/products/$id', queryParameters: {'select': _fields});
    return _parse(() => Product.fromJson(json));
  }
}

T _parse<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException {
    throw const UnexpectedResponseException();
  }
}
```
- **`select`** asks only for the 6 fields we read (`id` always comes back), so responses stay small.
- **`_parse<T>`** is a **generic** helper. It takes a **function** so the parsing runs **inside** its `try` (arguments are evaluated before a call).
- **Contract:** only `AppException`s ever leave a repository.
- **No separate "data source" class:** `ApiClient` already is the shared raw-HTTP layer.

### The composition root [Essential]

```dart
void main() {
  final apiClient = ApiClient(baseUrl: Env.apiBaseUrl);
  final productsRepository = DummyJsonProductsRepository(apiClient);
  runApp(ShopLiteApp(productsRepository: productsRepository));
}
```
`main.dart` creates the **real** pieces; everything else **receives** them. **The cost:** passing the repository by hand touched ~25 places. Phase 4 makes providing dependencies easier.

---

## F. Loading and error views

```dart
const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading'));
```
```dart
final (icon, title) = switch (error) {
  NetworkException() => (Icons.wifi_off, "You're offline"),
  RequestTimeoutException() => (Icons.timer_off_outlined, 'That took too long'),
  NotFoundException() => (Icons.search_off, 'Not found'),
  ServerException() => (Icons.cloud_off_outlined, 'Server problem'),
  UnexpectedResponseException() ||
  UnknownException() => (Icons.error_outline, 'Something went wrong'),
};
return EmptyView(icon: icon, title: title, message: error.message, action: FilledButton.icon(...'Try again'));
```
- **The exhaustive `switch`** is the payoff of `sealed`. A **record** `(icon, title)` returns two values at once.
- **The message comes from the exception**; the **icon and title come from the view**; **what "Try again" does** comes from the **screen** (`onRetry`).
- `ErrorView` **reuses `EmptyView`**: the same look, and the same 200%-text safety.

---

## G. Showing async data on screen

### `FutureBuilder` [Essential]

```dart
late Future<Product> _product;

@override
void initState() {
  super.initState();
  _product = widget.repository.getProduct(widget.productId);   // once
}

void _retry() {
  setState(() { _product = widget.repository.getProduct(widget.productId); });
}

FutureBuilder<Product>(
  future: _product,
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
    final error = snapshot.error;
    if (error != null) { ... ErrorView / EmptyView ... }
    return _ProductDetailsBody(product: snapshot.requireData);
  },
)
```

| Rule | Why |
|---|---|
| **Create the `Future` in `initState`**, never in `build()` | `build()` runs often, so each run would send a **new request** and flash the spinner. Tested: "loads only once, even when the screen rebuilds". |
| **Retry = a new `Future` in `setState`** | `FutureBuilder` sees a different future → loading → result |
| **`didUpdateWidget`** reloads when `productId` changes | Flutter may reuse the `State`, and `initState` won't run again |
| `Scaffold` + `AppBar` outside the builder | The back button exists during loading and errors too |

### Choosing the right view for each error

| Error | Screen shows | Why |
|---|---|---|
| `NotFoundException` on details | `EmptyView` "Product not found" + **Back to home** | Retrying won't make it exist |
| Any other `AppException` | `ErrorView` + **Try again** | The network may come back |
| Not an `AppException` (a bug) | `ErrorView(UnknownException)` | The user still gets a way out |

### Data vs. user choices (Home)
Home **stores** the user's choices (`_selectedCategory`, `_sort`) as `State` fields and **derives** the visible list from the **loaded** products on every build: filter, then sort. Choices survive retries. The chips come from `categoriesOf(loaded)`.

### Where `FutureBuilder` strains → Phase 4
Two screens now repeat the same pattern ("future in a field, retry, connection-state checks, `AppException` fallback"). The logic lives **inside widgets**, is testable only by **building widgets**, and the data can't be **shared**. Phase 4's **Cubit** fixes all three.

---

## H. Dart concepts new in Phase 3

| Concept | Example | Remember |
|---|---|---|
| `factory` constructor | `Product.fromJson` | Runs code first; may return or throw |
| Map pattern | `{'id': final int id, ...}` | Key exists + type + binding; extra keys ignored |
| Type-test pattern | `final Map<String, dynamic> json =>` | Safer than `as` |
| `num` | `final num price` | Parent of `int` and `double` |
| `Future` / `async` / `await` | `await _dio.get(...)` | A value later; errors rethrow at `await` |
| `try` / `on X catch (e)` | `on DioException catch (error)` | Catch **only** what you can handle |
| Definite assignment | `final Response<Object?> response;` assigned in `try` | Dart proves it's set before use |
| Initializer list | `ApiClient(...) : _dio = Dio(...)` | Sets `final` fields before the body |
| `sealed` / `final class` | `AppException` family | Closed set → exhaustive `switch` |
| Logical-or, constant, binding patterns | `A \|\| B =>`, `404 =>`, `final statusCode =>` | Expressive error mapping |
| `abstract interface class` | `ProductsRepository` | Implement, don't extend |
| Generics | `T _parse<T>(T Function() parse)` | One helper, many types |
| Records | `(repository: ..., network: ...)`, `(icon, title)` | Small bundles of values; destructure with patterns |
| `late` / `late final` | `late Future<Product> _product;` | Assigned later, before use |
| `Completer` | `FakeProductsRepository(gate: Completer<void>())` | A `Future` you complete by hand |
| `String.fromEnvironment` | `Env` | Build-time configuration |
| `Iterable` parameters | `categoriesOf(Iterable<Product> products)` | Ask for the least you need |

---

## I. Important decisions

| Decision | Why | Revisit when |
|---|---|---|
| Parse and validate JSON by hand first | Understand what code generation will do | Phase 5 (`json_serializable`) |
| Prices to cents with `.round()` at the boundary | Exact money everywhere else | — |
| dio only inside `ApiClient` | One place to change; nothing else depends on dio | — |
| 10-second timeouts | Never wait forever; long enough for slow networks | If timeouts become frequent |
| Our own sealed error family with user messages | Screens never see HTTP details | Phase 7 (401 → expired login) |
| No separate data source class | `ApiClient` already fills that role | If a feature combines sources (cache + API) |
| Fake repository built at its first use (Task 6) | Shaped by a real need | — |
| Details before Home | Every commit stays working | — |
| Repository passed by hand from `main.dart` | Simple and explicit | Phase 4 |
| Waiting test helpers (`pumpShopLiteApp`, `pumpHomeScreen`) | The right way becomes the easy way | — |
| Delete dead code (`findMockProductById`) | Unused code costs reading time; Git keeps history | Always |

---

## J. Testing

### What Phase 3 added (138 tests in total; 89 at the end of Phase 2)

| File | Tests | Protects |
|---|---|---|
| `features/products/data/models/product_test.dart` | 6 | Real fixture, rounding, whole numbers, extra fields, missing/wrong fields |
| `features/products/data/models/products_page_test.dart` | 3 | Real page, bad `products`, non-object items |
| `core/network/api_client_test.dart` | 12 | URL + query, body, timeouts, and **every failure → its `AppException`** |
| `features/products/data/dummy_json_products_repository_test.dart` | 7 | Requests, models, "only `AppException`s" |
| `core/widgets/loading_view_test.dart` | 2 | Spinner + "Loading" for screen readers |
| `core/widgets/error_view_test.dart` | 9 | Icon and title per error type (6 generated), Retry, guidelines, 200% |
| `features/products/data/product_catalog_test.dart` | 4 | Categories and filtering on any list |
| `features/products/presentation/screens/product_details_screen_test.dart` | 5 (+3) | Loading → product, not found, error + retry, loads once, id change |
| `features/products/presentation/screens/home_screen_test.dart` | 9 (+5) | Loading → products, first page, error + retry, loads once, chips from data |
| `features/products/data/mock_products_test.dart` | 3 (−2) | Dead-code tests removed |

### Techniques new in Phase 3

| Technique | Use |
|---|---|
| **Fixtures** + `readFixture(...)` | Real API responses as test input |
| **`FakeHttpAdapter`** | A fake network under a real `ApiClient`: answers, failures, and recorded requests |
| `DioException.connectionTimeout(...)` thrown by the fake | Simulate timeouts and lost connections on demand |
| `isA<T>().having(getter, name, value)` | Check a property of a thrown error |
| **`FakeProductsRepository`** (`error`, `gate`, call counters, `requestedPages`) | Screen tests without any network |
| `await expectLater(future, throwsA(...))` | Async error expectations |
| **Waiting helpers** (`pumpShopLiteApp`, `pumpHomeScreen`) | Never check a screen that's still loading |
| **Presence checks next to absence checks** | `takeException() isNull` **and** `find.byType(GridView)` |
| **Probes** against the real API (deleted afterwards) | Confirm the fakes match reality |
| Relative imports for test helpers | `package:` only reaches `lib/` |

---

## K. Debugging stories and lessons

| What happened | Cause | Lesson |
|---|---|---|
| First online launch: **"That took too long"** | The emulator took > 10 s to **connect** (`[connection timeout]` in the log) | Networks are unreliable; every data screen needs a way out. The handling worked exactly as designed. |
| A screenshot showed only Flutter's **launch screen** | Debug builds start slowly; my taps landed too early | Check the log (errors? process alive?) **before** concluding anything |
| `containsSemantics` deprecated (Phase 2) / `transformTimeout` (Phase 3) | APIs evolve | Read the **installed** source and docs, not memory |
| Some tests would have **passed silently** after loading became async | They checked only for the absence of problems | Wait for content; add presence checks |
| The fake network could have been built on wrong assumptions | Fakes only encode what we *believe* | Confirm with a real-network probe |
| A test helper refactor missed one line (`readFixture` count 0) | A script pattern didn't match the formatted code | Verify script results (counts, analyzer), then fix |
| Commit 2 was staged but not committed | The command sequence stopped after `git add` | Check `git status` and `ahead`/`behind` after every Git step |

---

## L. Git in Phase 3

- **Branch created from the uncommitted work** (`git switch -c` keeps changes), so nothing landed on `main`.
- **`test:` commits** for test-only refactors (shared helpers), separate from `feat:`.
- **`refactor:` before `feat:`** again (catalog helpers), with each commit working on its own.
- **`env/dev.json` is committed** (public values only); `env/*.local.json` stays ignored.
- **`.vscode/launch.json` is committed**, so anyone opening the project gets the right run configuration.

---

## M. Phase 3 completion checklist

| Criterion | Status | Evidence |
|---|---|---|
| No widget imports `dio` | ✅ | `package:dio` only in `lib/core/network/` |
| Network off → readable error, not a crash | ✅ | Airplane mode: "You're offline" + Try again → loaded; real timeout: "That took too long" → Try again → loaded |
| Base URL from the env file | ✅ | `Env.apiBaseUrl`; clear `StateError` without the file (probe) |
| Model and mapper tests pass | ✅ | 6 + 3 model tests; 12 `ApiClient` tests covering every dio error type |
| All seven tasks tested and committed | ✅ | Section A; 138/138 |
| Phase 3 knowledge check | ✅ | All six answered; refinements on rounding certainty and the error path |
| Merged into `main` and tagged `phase-3` | ⏳ | Next step after this file is committed |

---

## N. Carried forward

| Item | Where it goes |
|---|---|
| `FutureBuilder` loading logic repeated in two screens | **Phase 4**: Cubit |
| Repository passed by hand through constructors | **Phase 4** |
| Only the first page (30 products); local categories and sorting | **Phase 5**: pagination, `/products/categories`, API sorting |
| Categories tab still uses the mock list | **Phase 5** |
| Hand-written `fromJson` | **Phase 5**: `json_serializable` |
| One automatic retry for timeouts | **Phase 10** (optional) |
| Isolates for parsing huge JSON | Not needed at our sizes |

---

## O. Knowledge check

Answer each one **before** opening the Answer Key.

1. Name the four parts of an HTTP request and the three parts of a response. What does a `404` mean, and is it a crash?
2. Why does `Product.fromJson` use `'price': final num price` and `(price * 100).round()`? What happens with `{"price": "19.99"}`?
3. Why is the base URL in `env/dev.json`? Could a secret API key go there?
4. What does `connectTimeout` measure, and what does `receiveTimeout` measure? Which one fired on the emulator?
5. Why does the app have its own `AppException` family instead of letting `DioException` reach the screens? Name two benefits.
6. Why is `AppException` `sealed`? What happens to `ErrorView` when a new error type is added?
7. Why does `_parse<T>` take a function instead of an already-parsed value?
8. What is the composition root, and why do tests never use it?
9. Why must a `Future` for `FutureBuilder` be created in `initState`? What does `didUpdateWidget` add?
10. A test checks only `expect(tester.takeException(), isNull)` on a screen that loads data. What can go wrong, and how do our tests prevent it?

---

## P. Readiness for Phase 4

### Phase 3 concepts you'll use right away

| Phase 3 concept | How it appears in Phase 4 |
|---|---|
| `ProductsRepository` interface | The Cubit receives it; tests give it a fake |
| Loading / error / data with `FutureBuilder` | Becomes explicit **states**: `ProductsLoading`, `ProductsError`, `ProductsLoaded` |
| `AppException` | Stored in the error state; `ErrorView` shows it |
| Retry = a new request | `cubit.load()` again |
| `FakeProductsRepository` | Cubit unit tests with `bloc_test`, no widgets needed |
| Composition root | Where real dependencies are created; Phase 4 provides them to the tree |
| Waiting helpers | Still useful for widget tests |

### Self-assessment checklist

- [ ] I can read an HTTP request and response and name their parts.
- [ ] I can write a `fromJson` with a map pattern that rejects bad data.
- [ ] I can explain why money is converted with `.round()` at the boundary.
- [ ] I can run the app with the env file and explain why it's needed.
- [ ] I can explain what each `AppException` means and which dio error leads to it.
- [ ] I can explain the repository interface and constructor injection.
- [ ] I can write a test with a fake network or a fake repository.
- [ ] I can show async data with `FutureBuilder` without refetching on rebuild.
- [ ] I can choose between `ErrorView` and `EmptyView` for an error.
- [ ] I check that a test really reaches the state it claims to test.

---

## Answer Key

<details>
<summary><strong>Click to show answers</strong> (try the questions first!)</summary>

**1. HTTP parts**
Request: **method**, **URL**, **query parameters**, **headers** (and sometimes a body). Response: **status code**, **headers**, **body**. `404` means "not found". It's **not a crash**, just a normal response with an error status, which our app turns into `NotFoundException`.

**2. `num` and `.round()`**
JSON doesn't distinguish `10` from `10.0`; on a phone `20` decodes as an `int`, and `double` wouldn't match it. `19.99 * 100` is `1998.9999999999998`: `.round()` gives 1999, `.toInt()` gives 1998. `{"price": "19.99"}` is a **string**, so the pattern doesn't match and a `FormatException` is thrown (the repository turns it into `UnexpectedResponseException`).

**3. The env file**
To keep configuration out of code and allow different environments (dev, prod, Supabase in Phase 9) without code changes. **No secrets:** anything in the app can be extracted; secrets belong on a server.

**4. Timeouts**
`connectTimeout`: how long establishing the connection may take. `receiveTimeout`: how long waiting for the answer may take. On the emulator, the **connect** timeout fired: the connection wasn't established within 10 seconds, so the server never saw the request.

**5. Our own errors**
dio stays inside `ApiClient` (one place to change); screens get **user-friendly messages**; screens can **decide by type** (not found vs. offline); fakes can simply throw them.

**6. `sealed`**
Dart knows the complete list of subtypes, so `ErrorView`'s `switch` needs no default case. Adding a type makes that `switch` **fail to compile** until it has an icon and title.

**7. `_parse<T>` takes a function**
Arguments are evaluated **before** a function is called. `_parse(Product.fromJson(json))` would parse before `_parse`'s `try` starts, and the `FormatException` would escape. The closure delays parsing until it runs **inside** the `try`.

**8. The composition root**
`main.dart`, the one place where the **real** implementations are created and connected (`ApiClient` → `DummyJsonProductsRepository` → `ShopLiteApp`). Tests build `ShopLiteApp` (or screens) with **fakes** instead, so they never touch the real network or the env file.

**9. `initState` and `didUpdateWidget`**
`build()` can run many times; creating the `Future` there sends a new request and resets the screen to loading on every rebuild. `initState` runs once. `didUpdateWidget` handles a **reused** `State` that receives a new `productId`: `initState` won't run again, so it starts the new request there.

**10. Silent passes**
While the screen is still loading, nothing can overflow, so "no exception" is trivially true, and the test passes without testing the real content. Our helpers (`pumpShopLiteApp`, `pumpHomeScreen`) **always wait** until loaded, and those tests also check that the content exists (`expect(find.byType(GridView), findsOneWidget)`).

</details>
