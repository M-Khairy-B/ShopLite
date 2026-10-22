# "ShopLite": Flutter E-commerce Learning Roadmap

## Context

You know some Flutter basics and want to get confident by building one realistic project rather than watching courses. This roadmap is the guide for all our future sessions. We'll go through it one phase at a time, and we won't move to the next phase until the current phase meets its completion criteria.

**Current state of the workspace** (`e_commerce_learn`): it's a fresh `flutter create` project. It has Flutter 3.47.5 and Dart SDK ^3.13, only the counter template in `lib/main.dart`, and the only dependencies are `cupertino_icons` and `flutter_lints`. It isn't a git repository yet. We start from zero.


---

## Part A: Project definition

### A.1 The app

**ShopLite** is a small mobile store for Android (and iOS if you have a Mac). It's built in two stages:

1. **Mock stage (Phases 0–8).** The app uses the free public **DummyJSON** API (`https://dummyjson.com`). It provides products, categories, search, pagination, sorting, and **real JWT login with access and refresh tokens**. That's enough to learn networking and authentication properly without writing a backend. Anything DummyJSON can't persist (orders, registration) is **simulated locally and clearly labeled as fake**.
2. **Real-backend stage (Phase 9).** The data sources are swapped for **Supabase** (hosted Postgres, Auth, and Row Level Security). This provides real registration, a per-user cart stored on the server, and orders that the **server prices and authorizes**. You won't write a custom backend. You'll write a few SQL tables, security policies, and one database function.

The switch from mock to real is a deliberate lesson. If the architecture is right, swapping the data source changes the data layer only. Screens and state logic should barely change.

### A.2 Scope

| Category | Features |
|---|---|
| **Required** | Product grid with infinite-scroll pagination · categories · product details · search · filter by category and sort by price/rating · wishlist (local) · cart (add/remove/change quantity, totals, persisted locally) · login/logout · session that survives app restarts · automatic token refresh · protected screens · checkout (shipping form → order summary → place order) · order history · profile screen · loading/empty/error/retry states on every data screen · consistent theme |
| **Required in Phase 9 (real backend)** | Registration · server-side cart per user · server-created orders with trusted pricing · per-user authorization (RLS) |
| **Optional** (do these if you have time; each teaches one extra thing) | Dark mode · pull-to-refresh · product image carousel · showing product reviews (DummyJSON has them) · profile avatar with `image_picker` (teaches permissions) · tablet two-column layout · Arabic localization + RTL |
| **Postponed / out of scope** | Real payments (Stripe etc.) · push notifications · admin panel · inventory management · coupons · social login · analytics · CI/CD · deep links from outside the app |
| **Simulated when no real backend** | Registration (DummyJSON `/users/add` accepts the request but doesn't persist anything) · order creation and history (stored locally in the mock stage) · payment (always a fake "Cash on delivery / Test card" step, even in Phase 9) |

### A.3 What the frontend must never be trusted with

Flutter code runs on the user's device. A determined user can modify the app or call the API directly. So:

- **Prices and totals** computed in the app are **for display only**. The server must recompute the order total from its own product table (Phase 9).
- **Authorization** ("can this user see this order?") is enforced by the **server** (Supabase RLS). Hiding a button in Flutter is UX, not security.
- **Payments** need a backend and a payment provider. A Flutter app must never hold a secret payment key. We simulate payment and explain the real flow.
- **Secrets**: no private API keys in the app. The Supabase *anon/publishable* key is designed to be public. RLS is what protects the data. The *service_role* key must never be in the app.

### A.4 Technology stack (one consistent stack, no switching)

| Concern | Choice | Why |
|---|---|---|
| State management | **Cubit** (`flutter_bloc`) + `equatable` | Every state is an explicit class (loading / loaded / empty / error), which fits this app's screens exactly. Logic stays outside widgets and is very testable (`bloc_test`). It's built on Dart Streams, so you learn a core Dart concept along the way, and it's widely used in industry. It also has less "magic" than Riverpod, which suits a learner. We use **Cubit only**; the full Bloc (event-based) API isn't needed. |
| Navigation | **go_router** | Official package. URL-style routes with parameters (`/product/42`), bottom-nav shell, and a central `redirect` for login protection. |
| HTTP | **dio** | Interceptors (attaching tokens, refreshing them, logging), timeouts, typed errors, query parameters. Token refresh is much cleaner with dio than with `http`. |
| Dependency injection | **get_it** (composition root only) + `BlocProvider` | `get_it` creates long-lived services (API client, storage, repositories) once. `BlocProvider` places cubits in the widget tree where screens need them. No DI framework beyond that. |
| JSON | Manual `fromJson` first (Phase 3), then **json_serializable** (Phase 5) | Write mapping by hand first to understand it, then automate it once you know what the generated code does. |
| Lightweight storage | **shared_preferences** | Cart, wishlist, simple settings |
| Secure storage | **flutter_secure_storage** | Tokens only (Android Keystore / iOS Keychain) |
| Images | **cached_network_image** | Disk and memory caching, placeholders, error widgets |
| Formatting | **intl** | Currency and date formatting |
| Config | `--dart-define-from-file` + `String.fromEnvironment` | No extra package. Separate `dev`/`prod` base URLs. |
| Testing | `flutter_test`, **mocktail**, **bloc_test**, `integration_test` | Standard, no code generation needed for mocks |
| Real backend | **supabase_flutter** (Phase 9) | Auth, Postgres, RLS, and server functions without writing a server |
| Lints | `flutter_lints` (already present) | |

Install packages with `flutter pub add` **when the phase needs them**, not all on day one.

### A.5 Project structure (feature-first, "Clean Architecture lite")

```
lib/
  main.dart                 # bootstraps: env, DI, runApp
  app/
    app.dart                # MaterialApp.router
    router.dart             # go_router config + auth redirect
    di.dart                 # get_it registrations (composition root)
    theme/                  # ColorScheme, TextTheme, spacing tokens
  core/
    config/                 # Env (base URL, flags)
    network/                # ApiClient (dio), interceptors
    errors/                 # AppException hierarchy, error→message mapping
    storage/                # wrappers over prefs & secure storage
    utils/                  # Money formatting, validators, debouncer
    widgets/                # shared UI: AppButton, LoadingView, ErrorView, EmptyView, PriceText
  features/
    products/   data/ (models, remote data source, repository)  presentation/ (cubits, screens, widgets)
    cart/       ...
    wishlist/   ...
    auth/       ...
    checkout/   ...
    orders/     ...
    profile/    ...
test/                       # mirrors lib/
integration_test/
env/                        # dev.json, prod.json (dev.json committed with public values only)
```

**Is full Clean Architecture necessary?** No. For an app this size we use **two layers per feature: data and presentation**. A separate domain layer with use-case classes would mostly add files that just pass calls through. What we keep from Clean Architecture is the idea that matters: **widgets don't talk to dio, and cubits don't know whether data comes from DummyJSON or Supabase**. Repositories are `abstract interface class`es **only where we will actually swap implementations** (products, auth, cart, orders in Phase 9). That's real, earned abstraction, not ceremony.

**Error strategy:** repositories catch `DioException` (and later Supabase exceptions) and throw our own typed `AppException` subclasses (`NetworkException`, `TimeoutException`, `UnauthorizedException`, `ServerException`, `NotFoundException`). Cubits catch them and emit error states. Widgets map errors to user messages. This is simpler for learners than `Either`/`Result` types and is still disciplined.

**Money:** prices are stored as **integer cents** (`int priceCents`), converted at the JSON boundary and formatted with `intl` only in the UI. Never add up `double`s for money.

---

## Part B: How we learn

- **Understanding vs. copying.** You've *copied* code if it works but you can't predict what happens when you change it. You *understand* it when you can (1) explain why each line exists, (2) predict the result of a change before running it, (3) rebuild it from a blank file with only the docs, and (4) debug it when it breaks. Every phase's **Knowledge Check** tests these four things, not memorization.
- **Session workflow.** I explain the goal briefly → we list the concepts → we split the work into small tasks → for each task I either guide you or **ask you to write it first** (I'll mark these "🧑‍💻 You implement") → I review → we commit to git.
- **Learn concepts when the project needs them.** Each concept appears in the phase where a feature first needs it.
- **Testing is part of every phase from Phase 3 on**, not left to the end. Phase 10 only hardens and fills gaps.
- **Concept tiers** are used throughout: **[E] Essential** (must understand now) · **[U] Useful** (learn it, depth can come later) · **[P] Postpone** (know it exists).

Effort estimates assume roughly 1–2 hour sessions. They're rough, so go at your own pace.

---

## Part C: Phases

### Phase 0: Setup, tooling & Git (≈1 session)

**Learning objectives:** a working dev loop, version control habits, and how a Flutter project is organized on disk.

**Practical tasks**
1. Check the environment with `flutter doctor`. Run the app on an Android emulator or a physical device.
2. Learn the dev loop: hot reload vs. hot restart vs. full restart (and when each is required).
3. `git init`, look at `.gitignore`, make the first commit, create a GitHub repo, and push.
4. Agree on Git habits: one branch per phase (`phase-1-static-catalog`), small commits, clear messages.
5. Read `pubspec.yaml` and `analysis_options.yaml`. Enable a few stricter lints (e.g. `prefer_const_constructors`, `always_declare_return_types`).
6. Replace the counter template with an empty `MaterialApp` and create the `app/`, `core/`, `features/` folder skeleton.
7. Open Flutter DevTools once (Widget Inspector) just to see the widget tree of the empty app.

**Concepts to understand:** [E] `flutter run`, debug vs. profile vs. release modes · [E] hot reload preserves `State`, hot restart doesn't · [E] what `pubspec.yaml` controls · [E] Git: commit, branch, merge, push, `.gitignore` · [U] lints and `flutter analyze`.

**Dependencies:** Flutter SDK installed (already done), Android Studio or an emulator, a GitHub account.

**Expected deliverables:** an empty app runs; the repo is on GitHub; the folder skeleton is committed.

**Completion criteria**
- [ ] `flutter analyze` reports no issues
- [ ] You can explain when hot reload is not enough
- [ ] Repo pushed; you've made a branch and merged it back at least once

**Common mistakes:** committing `build/` or secret files · huge "did everything" commits · skipping `flutter analyze` warnings.

**Knowledge check:** (1) You change `main()`. Does hot reload pick it up? Why? (2) What does `.gitignore` *not* do for a file that was already committed? (3) Where does `uses-material-design: true` matter?

---

### Phase 1: UI foundations with a static catalog (≈3–4 sessions)

**Learning objectives:** think in widgets, compose layouts, understand stateless vs. stateful and the State lifecycle, and use assets, fonts, and a basic theme. **No networking yet.** Data is a hard-coded Dart list.

**Practical tasks**
1. A `Product` model (id, title, description, priceCents, thumbnail, rating, category) and a hard-coded list of about 8 products.
2. A `ProductCard` widget (image, title, price, rating, favorite icon), reused in a `GridView.builder`.
3. A `HomeScreen` with an `AppBar`, a horizontal category chip row (`ListView` with horizontal scroll), and the grid.
4. A `ProductDetailsScreen` opened with `Navigator.push` (deliberately the plain Navigator, so you see the underlying stack before go_router hides it).
5. A `QuantitySelector` **StatefulWidget** (− / count / +) on the details screen. Log every lifecycle method to the console and watch the order.
6. Add a local asset (logo/placeholder image) and a custom font in `pubspec.yaml`.
7. Create an app `ThemeData` from `ColorScheme.fromSeed` and use `Theme.of(context).textTheme` instead of hard-coded styles.
8. Make the grid responsive: column count from `LayoutBuilder` constraints (2 on phones, 3–4 on wide screens).

**Concepts to understand**
- [E] Everything is a widget; widgets are immutable **configurations**. Widget tree vs. Element tree vs. RenderObject (practical level: widgets are cheap blueprints, Elements keep things alive between builds).
- [E] `StatelessWidget` vs. `StatefulWidget`; why `State` is a separate object; `setState` marks the element dirty and schedules a rebuild.
- [E] **State lifecycle**: `createState` → `initState` → `didChangeDependencies` → `build` → `didUpdateWidget` → `setState` → `deactivate` → `dispose`.
- [E] **BuildContext** = this widget's location in the tree. `Theme.of(context)` looks *upward* from that location.
- [E] Layout rule: *constraints go down, sizes go up, parent sets position*. `Row`/`Column`/`Expanded`/`Flexible`/`Stack`/`Padding`/`SizedBox`. Reading and fixing **overflow errors**.
- [E] `ListView.builder` / `GridView.builder` build items lazily.
- [E] `const` constructors and why they matter.
- [U] `MediaQuery.sizeOf`, `SafeArea`, `AspectRatio`.
- [P] Custom `RenderObject`s, `InheritedWidget` internals (seen briefly in Phase 4).

**Dependencies:** Phase 0.

**Expected deliverables:** a good-looking static catalog with grid, category chips, details screen, and a working quantity selector; responsive on phone and tablet sizes.

**Completion criteria**
- [ ] No yellow/black overflow stripes at any common screen size or with large system font
- [ ] `ProductCard` is one reusable widget with no duplicated layout code
- [ ] You can explain the lifecycle log you produced, line by line
- [ ] No hard-coded colors or text styles outside the theme (except during experiments)

**Common mistakes:** putting everything in one 400-line `build` method · using `StatefulWidget` everywhere · `Expanded` outside a `Row`/`Column`/`Flex` · nesting scrollables without bounded height (`ListView` inside `Column` without `Expanded`) · using `double` for prices · putting heavy work inside `build`.

**Knowledge check:** (1) Why is `setState` after `dispose` an error? (2) What happens to `QuantitySelector`'s count when you hot reload? On hot restart? (3) 🧑‍💻 Build a `RatingStars` widget from scratch without looking at any reference. (4) Why does `Theme.of(context)` fail if `context` is *above* `MaterialApp`?

---

### Phase 2: App shell, navigation & mini design system (≈2–3 sessions)

**Learning objectives:** real app navigation, a tab shell, reusable UI building blocks, and user-feedback patterns.

**Practical tasks**
1. Add **go_router**. Routes: `/` (home), `/categories`, `/cart`, `/profile`, `/product/:id`, `/login` (placeholder).
2. A bottom navigation bar with `StatefulShellRoute` so each tab keeps its own scroll position and navigation stack.
3. Replace the Phase 1 `Navigator.push` with `context.push('/product/42')`. Pass the **id** in the path, not the whole object.
4. Mini design system in `core/widgets` and `app/theme`: spacing constants, `AppButton` (primary / secondary / loading), `PriceText`, and three state views: `LoadingView`, `EmptyView(icon, message, action)`, `ErrorView(message, onRetry)`.
5. UX feedback patterns: a `SnackBar` ("Added to wishlist"), a confirmation `AlertDialog`, and a `showModalBottomSheet` (sort options placeholder).
6. Accessibility basics: `tooltip`/semantic labels on icon buttons, 48dp tap targets, test with largest system font.
7. (Optional) Dark theme + system theme mode.

**Concepts to understand:** [E] declarative routing vs. imperative push/pop · [E] `go` vs. `push` (replace the stack vs. add to it) · [E] path and query parameters · [E] why routes take IDs instead of objects (deep links, restoration, the screen loads its own data) · [E] **BuildContext pitfalls**: `ScaffoldMessenger.of(context)` and `Navigator.of(context)` need the right ancestor · [U] nested navigation in shells · [U] `Semantics` · [P] route transitions, typed routes (`go_router_builder`).

**Dependencies:** Phase 1.

**Expected deliverables:** a tab-based app shell; every screen reachable by route; shared widgets used consistently.

**Completion criteria**
- [ ] Switching tabs keeps each tab's scroll position
- [ ] The Android back button behaves correctly inside tabs and from details
- [ ] Every data-screen placeholder uses `LoadingView` / `EmptyView` / `ErrorView`
- [ ] Icon-only buttons have semantic labels

**Common mistakes:** using `go` when you meant `push` (back button "breaks") · passing large objects through `extra` · creating the `GoRouter` inside `build` (it gets recreated every rebuild) · showing a SnackBar with a context that has no Scaffold.

**Knowledge check:** (1) Draw the navigation stack after: Home → Product 3 → Product 7 (related) → back. (2) Why does go_router recommend IDs in paths? (3) 🧑‍💻 Add a `/category/:slug` route yourself.

---

### Phase 3: Async Dart, networking & the data layer (≈3–4 sessions)

**Learning objectives:** Futures and async/await properly; HTTP fundamentals; a clean, testable data layer talking to DummyJSON.

**Practical tasks**
1. Async warm-up in a scratch file: `Future`, `async`/`await`, `then` vs. `await`, `try/catch/finally`, `Future.wait`, a `Stream` from `Stream.periodic` (Streams matter for Cubit later).
2. **HTTP fundamentals** with DummyJSON in a browser or Postman/curl first: the anatomy of a request and response, methods (GET/POST/PUT/PATCH/DELETE: what each means, which DummyJSON supports and simulates), status codes (2xx/4xx/5xx), headers, query params (`?limit=20&skip=0`).
3. Env config: `env/dev.json` with `API_BASE_URL`; run with `--dart-define-from-file`; an `Env` class reading `String.fromEnvironment`. Set up a VS Code launch config.
4. `ApiClient` wrapping **dio**: base URL, connect/receive timeouts, JSON headers, `LogInterceptor` in debug only.
5. `AppException` hierarchy + a single function mapping `DioException` → `AppException`.
6. Response models: `Product.fromJson`, `ProductsPage` (`products`, `total`, `skip`, `limit`) written **by hand**. Convert `price` → `priceCents` here.
7. `ProductsRemoteDataSource` (raw HTTP) and a `ProductsRepository` (abstract) with a `DummyJsonProductsRepository` implementation.
8. **Temporary**: show products with a `FutureBuilder` on Home to *feel* the raw async UI problem: no retry, refetching on rebuild, messy state. This motivates Phase 4.
9. 🧪 First tests: `Product.fromJson` with a fixture JSON file; the price-to-cents conversion; the error mapper.

**Concepts to understand:** [E] the event loop at a practical level (why `await` doesn't freeze the UI) · [E] `Future` states (uncompleted / value / error) · [E] unhandled async errors · [E] JSON → `Map<String, dynamic>` → typed model; null-safety when fields are missing · [E] timeouts and no-internet errors · [E] checking `mounted` after `await` before using `context` · [E] data source vs. repository responsibilities · [U] isolates/`compute` for huge JSON (not needed here) · [P] HTTP caching headers, GraphQL.

**Dependencies:** Phase 2. A basic idea of what JSON is.

**Expected deliverables:** Home shows real products from DummyJSON (via the temporary FutureBuilder); airplane mode shows an error instead of a crash; the first passing unit tests.

**Completion criteria**
- [ ] No widget imports `dio`
- [ ] Turning off the network gives a readable error, not a red screen or crash
- [ ] Base URL comes from the env file, not a string literal in code
- [ ] Model and mapper tests pass (`flutter test`)

**Common mistakes:** `as String` casts that crash on null · catching `Exception` and swallowing it silently · calling the API inside `build` · using `context` after `await` without checking `mounted` · creating a new `Dio()` per request · leaking `DioException` into UI code.

**Knowledge check:** (1) Why does the FutureBuilder version refetch on rebuilds, and what's the fix? (2) What status code does DummyJSON return for `/products/99999`, and which `AppException` should that become? (3) 🧑‍💻 Write `Category.fromJson` and its test yourself. (4) Explain timeout vs. no-connection vs. 500 to a non-developer.

---

### Phase 4: State management with Cubit (≈3 sessions)

**Learning objectives:** what state management is and why it's needed; local vs. shared state; how Cubit works internally; DI.

**Practical tasks**
1. **Understand before using:** a 20-minute exercise building a tiny counter with `ValueNotifier` + `ValueListenableBuilder`, then reading how `InheritedWidget` lets descendants find data with `context`. This is what `flutter_bloc`/`provider` build on.
2. Add `flutter_bloc`, `equatable`, `get_it`. Create `di.dart` that registers `ApiClient` and repositories as lazy singletons.
3. `ProductsCubit` with a **sealed** state: `ProductsInitial`, `ProductsLoading`, `ProductsLoaded(products)`, `ProductsEmpty`, `ProductsError(exception)`.
4. Home uses `BlocProvider` + `BlocBuilder` with an exhaustive `switch` over the sealed state; delete the temporary FutureBuilder. A retry button calls `cubit.load()` again.
5. `ProductDetailsCubit` loading `/products/:id` for the details route.
6. Pull-to-refresh (`RefreshIndicator`) that keeps showing old data while refreshing.
7. 🧪 `bloc_test` + `mocktail`: loading→loaded, loading→empty, loading→error, retry-after-error.

**Concepts to understand:** [E] **local UI state** (a quantity counter, a text field) stays in `StatefulWidget`; **shared/app state** (cart, auth, product lists) goes in cubits · [E] Cubit = class with a `Stream<State>` and `emit()`; `BlocBuilder` subscribes and rebuilds · [E] `context.read` (one-off calls in callbacks) vs. `context.watch` / `BlocBuilder` (rebuild on change) · [E] `BlocBuilder` vs. `BlocListener` (side effects like snackbars and navigation) vs. `BlocConsumer` · [E] state equality: why `equatable` matters and why emitting an "equal" state doesn't rebuild · [E] sealed classes + exhaustive `switch` · [E] where a cubit is created determines how long it lives · [U] `buildWhen`, `context.select` · [U] service locator vs. constructor injection: we use **both**, `get_it` only at the composition root · [P] Bloc events/transformers, `HydratedBloc`.

**Dependencies:** Phase 3.

**Expected deliverables:** Home and details are driven by cubits; every state is visible and handled; cubit tests pass.

**Completion criteria**
- [ ] No business or network logic inside widgets
- [ ] Every screen visibly handles loading, empty, error (with retry), and success
- [ ] All cubit tests pass, and you wrote at least one yourself
- [ ] You can explain the "ProviderNotFound" error and how to cause and fix it

**Common mistakes:** calling `context.watch` inside callbacks · creating a cubit inside `build` · mutating a list inside the state and re-emitting it (no rebuild, because equality didn't change) · navigation or snackbars inside `BlocBuilder` instead of `BlocListener` · calling `GetIt.I` from deep inside widgets everywhere.

**Knowledge check:** (1) Why didn't the UI update when you did `state.products.add(x); emit(state)`? (2) Is the quantity selector's count local or shared state? What about the cart badge count? (3) 🧑‍💻 Write `ProductDetailsCubit` and its tests yourself. (4) What happens to a cubit when its `BlocProvider` leaves the tree?

---

### Phase 5: Catalog features: categories, pagination, search, filter, sort (≈3–4 sessions)

**Learning objectives:** realistic list behaviors and data-heavy screens; code generation.

**Practical tasks**
1. Categories screen from `/products/categories`; `/category/:slug` shows `/products/category/{slug}`. In-memory cache categories in the repository (fetch once per session).
2. **Infinite scroll pagination** using `limit` & `skip`: `ScrollController` listener near the bottom triggers `loadMore()`. State carries `items`, `hasMore`, `isLoadingMore`, `loadMoreError`. A footer shows a loader or a retry.
3. **Search** with `/products/search?q=`: a search field with **debounce** (`Timer`, cancelled on each keystroke and in `close()`), ignore out-of-order responses, and empty-query and no-results states.
4. **Sort and filter**: a bottom sheet with sort (`sortBy=price|rating`, `order=asc|desc`) + category. These become query parameters; the selection persists while the screen lives.
5. Product details polish: image carousel (`PageView`) [optional], `CustomScrollView` + `SliverAppBar` [useful], reviews [optional].
6. Switch models to **json_serializable** + `build_runner`. Read the generated `.g.dart` and compare it with your hand-written version.
7. `ValueKey` on grid items; see why keys matter when lists re-order.
8. 🧪 Tests: pagination (first page, load more, end of list, load-more failure keeps existing items), search debounce (using `fakeAsync`).

**Concepts to understand:** [E] offset pagination (`limit`/`skip`) vs. cursor pagination (concept only) · [E] debounce and race conditions in async search · [E] disposing controllers and timers (`dispose` / `close`) · [E] query parameter building · [U] keys (`ValueKey`, when needed) · [U] slivers · [U] code generation: what `build_runner` does, `part` files, committing generated code or not · [P] `freezed`, Bloc event transformers.

**Dependencies:** Phase 4.

**Expected deliverables:** smooth infinite catalog, category browsing, debounced search, sort/filter sheet; generated JSON models.

**Completion criteria**
- [ ] Fast scrolling never requests the same page twice
- [ ] Typing "phone" quickly sends one request, not five
- [ ] A load-more error doesn't wipe the visible list
- [ ] No `TextEditingController`, `ScrollController`, or `Timer` leaks (all disposed)

**Common mistakes:** firing `loadMore` repeatedly while a request is in flight · resetting `skip` incorrectly on filter change · showing stale search results from a slower earlier request · forgetting to rerun `build_runner` · putting the `ScrollController` in the cubit.

**Knowledge check:** (1) Walk through what happens when the user scrolls to the bottom with the network off, then turns it on and taps retry. (2) Why must the search timer be cancelled in `close()`? (3) 🧑‍💻 Add "sort by title" yourself end-to-end.

---

### Phase 6: Cart & wishlist: shared state + local persistence (≈3 sessions)

**Learning objectives:** app-wide state used by many screens; correct money handling; persisting data on the device.

**Practical tasks**
1. `CartItem` (product snapshot: id, title, thumbnail, unitPriceCents, quantity) and a `Cart` value object with computed `subtotalCents`, `itemCount`. **Immutable**: every change returns a new cart.
2. `CartCubit` provided **above** the router (app-wide): add, remove, increment/decrement, clear; max quantity per item.
3. Cart screen: list with quantity controls, swipe-to-delete (`Dismissible`) with **Undo** snackbar, subtotal, "Proceed to checkout" button, empty-cart state.
4. A cart badge on the bottom-nav tab that updates live; an "Add to cart" button on cards and details, with a snackbar.
5. `WishlistCubit` (set of product ids + snapshots) with heart toggles on cards and details, a wishlist screen, and the empty state.
6. **Persistence**: a `CartLocalStore` / `WishlistLocalStore` on `shared_preferences` (serialized JSON). Load on startup and save on change. Decide and document the snapshot-price policy (what happens if a price changes later; real answer in Phase 9).
7. `intl` currency formatting via `PriceText`.
8. 🧪 Unit tests for `Cart` math (including quantity edge cases) and `CartCubit` with a fake store.

**Concepts to understand:** [E] shared state across screens and where to provide it · [E] immutability and value equality · [E] money as integer minor units; rounding; formatting vs. storing · [E] `shared_preferences` is for **small, non-sensitive** data (not a database, not secure) · [E] async app startup (load stored state before showing UI, or show loading) · [U] `context.select` to rebuild only the badge · [U] **caching** basics: what's cached (cart, categories), when it's stale · [P] local databases (`drift`, `isar`), offline-first sync.

**Dependencies:** Phase 5 (product model and details), Phase 4.

**Expected deliverables:** a fully working cart and wishlist that survive app restarts.

**Completion criteria**
- [ ] Totals are always correct (verified by tests), with no floating-point artifacts like `29.990000001`
- [ ] Killing and reopening the app restores the cart and wishlist
- [ ] The badge, cart screen, and details button stay in sync
- [ ] Undo after swipe-delete restores the item with its quantity

**Common mistakes:** `double` math for totals · providing `CartCubit` inside a route (each screen gets a different cart) · storing whole `Product` JSON with large descriptions · storing tokens or personal data in `shared_preferences` · saving to disk on every rebuild instead of on change.

**Knowledge check:** (1) Why can't the app's subtotal be trusted by a server? (2) 🧑‍💻 Implement "max 10 per item" and its tests yourself. (3) Where exactly is `CartCubit` provided, and what would break if you moved it under the `/cart` route?

---

### Phase 7: Forms & authentication (DummyJSON JWT) (≈4 sessions)

**Learning objectives:** forms and validation; the full token lifecycle; secure storage; auth-aware navigation.

**Practical tasks**
1. **Login screen**: `Form` + `TextFormField` validators, `FocusNode`/`textInputAction` to move between fields, password visibility toggle, a loading button, disabled double-submit, and server error display.
2. **Registration screen UI** with validation (email format, password rules, confirm password). Submit to DummyJSON `/users/add` and **label it simulated** (it doesn't persist, so you can't log in with it). Real registration comes in Phase 9.
3. `AuthRepository`: `login` (`POST /auth/login` with a test user, e.g. `emilys`/`emilyspass`, with a short `expiresInMins` so you can test expiry), `getMe` (`GET /auth/me`), `refresh` (`POST /auth/refresh`), `logout` (clear local tokens).
4. `TokenStorage` over **flutter_secure_storage** (access + refresh tokens).
5. `AuthCubit` (`Unknown` → `Authenticated(user)` / `Unauthenticated`). On startup: read tokens → validate with `/auth/me` → decide. A splash/loading state while `Unknown`.
6. dio **AuthInterceptor**: attach the `Authorization: Bearer` header; on **401** → refresh **once** (concurrent requests wait on a single refresh) → retry the original; if refresh fails → clear tokens → `AuthCubit` → `Unauthenticated` with a "Session expired" message.
7. **Protected routes**: go_router `redirect` + `refreshListenable` driven by `AuthCubit`. `/checkout`, `/orders`, `/profile` need login; after login, return to the page the user was trying to reach (`?from=`).
8. Logout from profile with a confirmation dialog; cart policy on logout (decide: keep it as a guest cart).
9. App lifecycle: an `AppLifecycleListener` that rechecks the session when the app resumes after a long time in the background.
10. 🧪 Tests: validators, `AuthCubit` startup paths, interceptor refresh (fake 401 → refresh → retry; refresh failure → logout).

**Concepts to understand:** [E] `Form`/`GlobalKey<FormState>`/validators; controllers and disposal · [E] authentication (who are you) vs. authorization (what you may do) · [E] access token (short-lived) vs. refresh token (long-lived); what a JWT contains (decode one at jwt.io and see it's **not encrypted**) · [E] secure storage vs. shared_preferences and why · [E] centralized auth redirect vs. checks scattered in screens · [E] the refresh race condition with concurrent requests · [U] app lifecycle states (resumed/inactive/paused/detached) · [U] basic authorization in the UI (hide what you can't use; the server still enforces) · [P] OAuth/social login, biometrics.

**Dependencies:** Phases 2 (router), 3 (ApiClient), 4 (Cubit).

**Expected deliverables:** login, persistent session, auto-refresh, session-expiry handling, protected screens, logout.

**Completion criteria**
- [ ] Log in, kill the app, reopen → still logged in, with no login screen flash
- [ ] With `expiresInMins: 1`, waiting and then making a request silently refreshes
- [ ] A corrupted refresh token → clean logout with a message, no infinite loop
- [ ] Opening `/orders` while logged out → login → lands back on orders
- [ ] Tokens appear nowhere except secure storage (not in logs in release)

**Common mistakes:** refresh loops (refresh endpoint itself returning 401 → refresh again) · parallel requests each triggering their own refresh · navigating from inside the repository or interceptor · validating only in the UI · logging tokens · the router not reacting to auth changes (missing `refreshListenable`).

**Knowledge check:** (1) Draw the sequence diagram for "access token expired, three requests in flight". (2) If someone steals the access token, what limits the damage? The refresh token? (3) 🧑‍💻 Write the password validator and its tests. (4) Why does hiding the "Orders" tab not protect anyone's orders?

---

### Phase 8: Checkout, orders & profile (simulated) (≈3 sessions)

**Learning objectives:** a multi-step flow; complex forms; designing an order model; clearly separating simulated parts from real ones.

**Practical tasks**
1. **Checkout flow** (protected): Step 1 shipping address form (name, phone, street, city, postal code: validators, keyboard types, autofill hints) → Step 2 payment method (Cash on delivery / "Test card", a **simulated** step with a visible note) → Step 3 **order summary** (items, subtotal, shipping fee rule, total) → Place order.
2. `CheckoutCubit` holding the flow state; the address is remembered for next time (local).
3. `OrdersRepository` (abstract) + `LocalOrdersRepository` (the **simulated** order store in `shared_preferences`): creates an order with id, timestamp, status `placed`, and copies the line items and totals. Clears the cart on success.
4. Order success screen → Order history list (newest first) → Order details screen. Dates formatted with `intl`.
5. Profile screen: user info from `/auth/me`, saved address, logout, (optional) avatar with **image_picker**: camera/gallery **permissions**, denied-permission handling.
6. Edge cases: empty cart → no checkout; double-tap "Place order" → one order; failure → stay on the summary with an error.
7. 🧪 Tests: address validators, `CheckoutCubit` steps, order creation clears the cart.

**Concepts to understand:** [E] multi-step flows and where their state lives · [E] idempotency/double-submit protection · [E] order = immutable snapshot of prices at purchase time · [E] what's simulated here and why it's unsafe in production (the client decides the price) · [U] permissions model (runtime requests, permanently denied → settings) · [U] `PopScope` (confirm leaving checkout) · [P] real payment flows (PaymentIntent on the server, client SDK confirms, webhook confirms the order).

**Dependencies:** Phases 6 (cart) and 7 (auth).

**Expected deliverables:** a complete end-to-end shopping flow in the mock stage; order history; profile.

**Completion criteria**
- [ ] Full flow works: browse → add → cart → login (if needed) → checkout → order → history
- [ ] Every simulated feature is labeled in code comments and in a `SIMULATED.md` list
- [ ] Rapid double-tap creates exactly one order
- [ ] You can explain the real payment flow even though we don't build it

**Common mistakes:** one giant checkout widget · losing form input when going back a step · trusting client totals "because it's just a demo" without writing down why it's wrong · not handling permission denial.

**Knowledge check:** (1) List three ways a malicious user could cheat this simulated checkout. (2) 🧑‍💻 Implement the shipping-fee rule (free above X) with tests. (3) Why does an order store prices instead of product ids only?

---

### Phase 9: Real backend with Supabase (≈4–5 sessions)

**Learning objectives:** what a real backend adds (identity, persistence, authorization, trusted computation) and how good architecture makes the swap cheap.

**Practical tasks**
1. Create a Supabase project. Tables: `products` (seeded from DummyJSON data with a small script/CSV), `categories`, `cart_items (user_id, product_id, quantity)`, `orders`, `order_items`, `profiles`.
2. **Row Level Security** policies: anyone reads products; users read and write **only their own** cart items, orders, and profile. Test that user A can't read user B's orders.
3. A Postgres function **`place_order(address, payment_method)`**, called via RPC: reads *the server's* cart and *the server's* prices, computes totals, creates the order + items in one transaction, clears the cart, and returns the order. The client never sends prices.
4. Flutter: add `supabase_flutter`; env holds the URL + publishable/anon key; store the session in secure storage via a custom storage adapter.
5. **Swap implementations** behind existing interfaces: `SupabaseAuthRepository` (real registration, login, logout, session restore: compare with what you built manually in Phase 7), `SupabaseProductsRepository` (pagination with `range`, search with `ilike`, filtering), `SupabaseCartRepository` (guest cart local → merge into server cart on login), `SupabaseOrdersRepository`.
6. Change DI registrations to switch mock ↔ real with one env flag (`BACKEND=mock|supabase`).
7. 🧪 Repository tests with mocked clients; a manual RLS verification checklist.

**Concepts to understand:** [E] client vs. server responsibilities (trust boundary) · [E] authorization enforced at the data layer (RLS) · [E] server-side pricing and transactions · [E] public vs. secret keys · [E] the payoff of the repository pattern: cubits and screens unchanged · [U] SQL basics (select, insert, join, foreign keys) · [U] guest-to-user cart merge strategies · [P] Edge Functions + Stripe test mode for real payments, realtime subscriptions, storage buckets for avatars.

**Dependencies:** Phase 8 complete (all repositories behind interfaces).

**Expected deliverables:** the same app running on a real backend: real accounts, a cart synced across devices, server-priced orders, protected data.

**Completion criteria**
- [ ] Register on device A, log in on device B (or after reinstall) → same cart and orders
- [ ] Changing a product price in the database changes the next order's total, not old orders
- [ ] Attempting to read another user's orders (via a tweaked query) returns nothing
- [ ] Flipping `BACKEND=mock` still runs the app
- [ ] The diff to screens and cubits for the swap is tiny, and you can show it

**Common mistakes:** RLS disabled "temporarily" · putting the service_role key in the app · sending totals from the client · forgetting the cart merge on login (guest items vanish) · leaking Supabase types into cubits.

**Knowledge check:** (1) Explain why `place_order` belongs on the server, in two sentences. (2) 🧑‍💻 Write the RLS policy for `orders` yourself. (3) What did the Supabase SDK do automatically that you wrote by hand in Phase 7?

---

### Phase 10: Quality: testing, debugging, performance, accessibility (≈3 sessions)

**Learning objectives:** confidence that the app works and stays working; professional debugging and profiling.

**Practical tasks**
1. **Widget tests**: `ProductCard`, the state views, the cart screen (mock cubit states → correct UI), the login form validation messages.
2. **Integration test** (`integration_test`): happy path on the mock backend (open → search → add to cart → login → checkout → see the order).
3. Fill gaps in unit tests; run `flutter test --coverage` and look at uncovered *logic* (don't chase a percentage).
4. **Debugging drills**: read three real stack traces (null check, setState after dispose, unbounded height) and fix them; breakpoints and stepping in VS Code; DevTools Widget Inspector, Network tab, Logging view.
5. **Performance**: profile mode + the DevTools Performance view on the catalog; find and fix one jank source; `const` audit; `buildWhen`/`select` for over-rebuilding widgets; image sizing (`memCacheWidth`) for thumbnails; verify no unbounded lists.
6. **Logging**: a small `AppLogger` (`dart:developer` `log`) with levels; no logs of tokens or personal data; quieter in release.
7. **Accessibility audit**: screen reader pass (TalkBack), large fonts, contrast, semantic labels; add `Semantics` where needed.
8. Global error handling: `FlutterError.onError` and `PlatformDispatcher.instance.onError` to log uncaught errors; a friendly fallback for the red error screen in release.

**Concepts to understand:** [E] unit vs. widget vs. integration test, and what each is good for · [E] reading stack traces (first frame in *your* code) · [E] debug vs. profile mode for performance · [U] golden tests (concept) · [U] the frame budget (16 ms), raster vs. UI thread · [P] crash reporting services (Sentry/Crashlytics), CI pipelines.

**Dependencies:** Phases 1–8 (Phase 9 recommended).

**Expected deliverables:** a test suite (unit + widget + one integration test) passing; known performance issues fixed; an accessibility checklist done.

**Completion criteria**
- [ ] `flutter test` and the integration test pass
- [ ] No jank in profile mode when scrolling the catalog on a mid-range device or emulator
- [ ] The app is usable with TalkBack and at 200% font size
- [ ] You can diagnose a new error from its stack trace without help

**Common mistakes:** testing implementation details instead of behavior · measuring performance in debug mode · tests that hit the real network · ignoring flaky tests.

**Knowledge check:** (1) Which test type would catch a broken route redirect? (2) 🧑‍💻 Write the widget test for the empty cart state. (3) Why is debug mode slow, and why doesn't it matter for users?

---

### Phase 11: Release preparation (≈2 sessions)

**Learning objectives:** turning a dev project into a shippable build.

**Practical tasks**
1. Environments: `env/dev.json` and `env/prod.json`; make sure the prod build uses the prod config. (Full flavors are [P].)
2. App identity: app name, package id (`applicationId`), app icon (`flutter_launcher_icons`), native splash (`flutter_native_splash`).
3. Versioning (`version: x.y.z+build`) and what each part means for the stores.
4. Android release signing (keystore **kept out of git**), `flutter build appbundle`, `--obfuscate --split-debug-info`, check app size (`--analyze-size`).
5. Permissions review: only what the app needs (internet; camera/photos only if the avatar feature exists), with usage descriptions on iOS.
6. **Security checklist**: no secrets in code or git history, tokens only in secure storage, HTTPS only, no sensitive logs, RLS on, dependencies up to date (`flutter pub outdated`).
7. README: setup, env, run, test, architecture overview, a list of simulated features; screenshots.
8. (Optional) Internal testing track on Google Play.

**Concepts to understand:** [E] debug vs. release builds · [E] signing and why the key must never be lost or leaked · [U] obfuscation and symbol files · [U] app bundle vs. APK · [P] CI/CD, store listing, flavors.

**Dependencies:** Phase 10.

**Expected deliverables:** a signed release build that installs and runs on a real device; a polished README.

**Completion criteria**
- [ ] The release build runs against the prod config on a physical device
- [ ] `git log -p | grep` finds no keys, keystores, or passwords
- [ ] A new developer could clone, configure, and run the app from the README alone

**Common mistakes:** committing the keystore or `key.properties` · shipping the dev base URL · forgetting to bump the build number · leaving debug logging on.

**Knowledge check:** (1) What happens if you lose the upload keystore? (2) Why is obfuscation not a security boundary?

---

## Part D: Wrap-up

### D.1 Complete list of concepts this project teaches

| Area | Essential [E] | Useful [U] | Postponed [P] |
|---|---|---|---|
| Flutter core | widgets, widget/element tree, Stateless/Stateful, State lifecycle, BuildContext, layout constraints, scrolling lists/grids, const, theming, assets/fonts | keys, slivers, InheritedWidget internals, responsive breakpoints, dark mode | custom RenderObjects, custom painters, animations beyond basics |
| Dart | null safety, classes/immutability, collections, Futures, async/await, error handling, Streams (basic), sealed classes + pattern matching | records, extension methods, isolates | generics-heavy APIs, FFI |
| Navigation | go_router, go vs. push, path/query params, shell routes, auth redirect | nested navigation, PopScope | typed routes, deep links from outside |
| Architecture | feature-first structure, data/presentation separation, models & mapping, data source vs. repository, DI at the composition root, typed errors | interface-based swapping, code generation | full Clean Architecture use cases, modularization |
| State | local vs. shared state, Cubit, sealed states, BlocBuilder/Listener, equality, provider scope/lifetime | buildWhen/select, ValueNotifier | Bloc events/transformers, HydratedBloc |
| Networking | HTTP methods/status/headers/query, JSON, dio client, timeouts, error mapping, pagination, search + debounce, auth headers, env base URLs | logging interceptor, in-memory caching | HTTP caching, GraphQL, websockets |
| Auth | login/logout, access + refresh tokens, JWT anatomy, secure storage, refresh interceptor, session persistence, protected routes, authN vs. authZ | lifecycle-based session check | OAuth/social, biometrics |
| Persistence | shared_preferences, secure storage, startup restore, when a backend is required | cache staleness | local DBs (drift/isar), offline sync |
| Backend concepts | trust boundary, server pricing, RLS authorization, transactions, public vs. secret keys | basic SQL, cart merge | Edge Functions, payments, realtime |
| UX | loading/empty/error/retry, snackbars, dialogs, bottom sheets, form validation, accessibility basics | carousel, pull-to-refresh, RTL | complex animations |
| Quality | unit, cubit, and widget tests, mocking, stack traces, DevTools inspector, logging | integration tests, profiling, coverage | golden tests, CI |
| Delivery | Git/GitHub workflow, env config, versioning, signing, release build | obfuscation, permissions, icons/splash | flavors, store publishing, CD |

### D.2 Final application features

Browse a paginated catalog · browse by category · search (debounced) · sort/filter · product details (gallery, reviews optional) · wishlist · cart with quantities, live badge, totals, persistence · register/login/logout · persistent session with silent refresh and session-expiry handling · protected checkout/orders/profile · 3-step checkout with validated address and simulated payment · server-priced order creation · order history and details · profile · polished loading/empty/error states, responsive and accessible UI · tests (unit, widget, integration) · signed release build. Runs on **mock (DummyJSON)** or **real (Supabase)** data via one switch.

### D.3 Dependency map

```
Phase 0 Setup & Git
   │
Phase 1 UI Foundations (static)
   │
Phase 2 Navigation & Design System
   │
Phase 3 Async + Networking + Data layer
   │
Phase 4 State Management (Cubit, DI)
   │
   ├──────────────────────────┐
Phase 5 Catalog features      │
   │                          │
Phase 6 Cart & Wishlist       Phase 7 Forms & Auth  (needs 2,3,4; can run in parallel with 5–6)
   │                          │
   └────────────┬─────────────┘
          Phase 8 Checkout, Orders, Profile (simulated)
                │
          Phase 9 Real Backend (Supabase)
                │
          Phase 10 Quality hardening   (testing has been woven in since Phase 3)
                │
          Phase 11 Release
```

Phase 7 can be done before Phase 5/6 if auth interests you more, but the default order is 5 → 6 → 7.

### D.4 Definition of "project complete"

The project is done when **all** of these are true:
1. Every required feature in A.2 works end-to-end on the **Supabase** backend, and the app still runs on the mock backend via the switch.
2. Every phase's completion checklist is ticked.
3. No widget contains networking, storage, or business logic; all repositories are behind interfaces where they're swapped.
4. Order totals are computed by the server; RLS prevents cross-user access (verified).
5. The test suite (unit + cubit + widget + 1 integration) passes, and `flutter analyze` is clean.
6. A signed release build runs on a physical device with the prod config.
7. The README explains setup, architecture, and simulated parts.
8. **The understanding test:** you can (a) explain the architecture on a whiteboard, (b) add a new small feature (e.g. "recently viewed products") across data → cubit → UI → test **without help**, and (c) debug a new runtime error from its stack trace.

### D.5 Recommended starting point (first session)

**Phase 0 in full, then the first half of Phase 1.**

Agenda for session 1:
1. Run `flutter doctor` and launch the current template on your emulator or device.
2. `git init`, first commit, create the GitHub repo, push; create branch `phase-1-static-catalog`.
3. Clean `main.dart` down to an empty `MaterialApp`; create the folder skeleton; stricter lints.
4. Start Phase 1: define the `Product` model together, then **🧑‍💻 you build `ProductCard` first**, and I review it.

**Before the session, have ready:** a working emulator or physical Android device, a GitHub account, and roughly how many hours per week you can spend (so we can size the sessions).
