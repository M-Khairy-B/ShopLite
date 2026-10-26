# Phase 4 Review: State Management with Cubit

> **How to use this file**
> Read one section at a time. Before reading an explanation, try to explain the concept **out loud** using our ShopLite code. If you can say which state the cubit is in, what the user sees, and what happens next, you understand it.
>
> Labels used below:
> - **[Essential]**: you will use this in every remaining phase.
> - **[Useful]**: good to know now; depth can come later.

**State of the branch at the end of Phase 4** (verified from the Git history):

```
* 345adfa feat: pull to refresh the home catalog
* 718bbc6 feat: refresh the catalog while keeping the loaded products
* 87c8c22 refactor: provide the products repository through the widget tree
* 387d0dd feat: load the home catalog through its cubit
* cd836af feat: add products cubit for the home catalog
* 5d007a3 refactor: drive product details from its cubit
* 6b46df6 feat: add product details cubit
*   322ef52 (main, tag: phase-3) Merge phase-3-data-layer: data layer and networking
```

On `phase-4-state-management`: `flutter analyze` reports **No issues found**; `flutter test` reports **162/162 passed** (138 at the end of Phase 3).

**How we worked:** test-first again (red for the right reason, then green). Every guard we added was proven with a **probe**: we removed it, watched the right test fail, and put it back. Each screen change was checked on the emulator with the console captured, including **airplane mode** for errors and failed refreshes.

---

## A. What we built

### The six tasks

| # | Task | Main concept | Commit(s) |
|---|---|---|---|
| 1 | Warm-up (learning file, not committed) | `ValueNotifier`, `ValueListenableBuilder`, `InheritedNotifier`, watch vs. read | — |
| 2 | `ProductDetailsCubit` | Cubit, `emit`, sealed states, `Equatable`, `bloc_test`, `isClosed` | `6b46df6` |
| 3 | Details screen uses its cubit | `BlocProvider`, `BlocBuilder`, object patterns, `ValueKey` | `5d007a3` |
| 4 | `ProductsCubit` for Home | `Empty` state, unmodifiable lists, UI state vs. data | `cd836af`, `387d0dd` |
| 5 | Provide the repository through the tree | `RepositoryProvider`, `.value`, `ProviderNotFoundException` | `87c8c22` |
| 6 | Pull-to-refresh | `RefreshIndicator`, `refreshError`, `BlocConsumer`, one-off side effects | `718bbc6`, `345adfa` |

### The layers now

```
main.dart                      creates ApiClient + DummyJsonProductsRepository (composition root)
   │
ShopLiteApp                    RepositoryProvider<ProductsRepository>.value  (above MaterialApp)
   │
HomeScreen / ProductDetailsScreen
   │  BlocProvider(create: ... context.read<ProductsRepository>() ...)
   ▼
ProductsCubit / ProductDetailsCubit      plain Dart: emit(states), no BuildContext
   │  constructor injection
   ▼
ProductsRepository → ApiClient → dio → DummyJSON          (unchanged since Phase 3)
```

### Where the code lives (new in Phase 4 marked ★)

```
lib/
  app/app.dart                                     + RepositoryProvider above MaterialApp
  app/router.dart                                  no longer passes anything to screens
  features/products/presentation/
    cubits/product_details_state.dart            ★ Loading / Loaded / Error
    cubits/product_details_cubit.dart            ★ load()
    cubits/products_state.dart                   ★ Loading / Loaded(+refreshError) / Empty / Error
    cubits/products_cubit.dart                   ★ load(), refresh()
    screens/product_details_screen.dart            StatelessWidget + BlocProvider + BlocBuilder
    screens/home_screen.dart                       BlocProvider + BlocConsumer + RefreshIndicator
test/
  features/products/presentation/cubits/         ★ 21 cubit tests, no widgets
  helpers/pump_app.dart                            + withProductsRepository(...)
  helpers/fake_products_repository.dart            error: Object?, products replaceable
```

New packages (constraints in `pubspec.yaml`): `flutter_bloc: ^9.1.1` (brings `bloc`, 9.2.1 resolved, and `provider`), `equatable: ^3.0.0`, and the dev dependency `bloc_test: ^10.0.0`.

---

## B. The warm-up: what Cubit is built on [Essential]

| Plain Flutter (Task 1) | flutter_bloc |
|---|---|
| `ValueNotifier<int>` holds a value, tells listeners | **`Cubit<State>`** holds a state; `emit()` tells listeners |
| `.value = 2` twice → the second is ignored | **equal states are skipped** |
| `ValueListenableBuilder` rebuilds only its builder | **`BlocBuilder`** |
| `InheritedNotifier` shares an object with everything below | **`BlocProvider`** / **`RepositoryProvider`** |
| `dependOnInheritedWidgetOfExactType` vs. `getInheritedWidgetOfExactType` | **`context.watch`** (rebuild me) vs. **`context.read`** (just give it to me) |
| `FlutterError("No CounterScope found…")` | **`ProviderNotFoundException`** |
| `notifier.dispose()` | **`cubit.close()`**, done by `BlocProvider` for what it created |

**The rule:** use `watch` in `build()` and `read` in callbacks like `onPressed`.

---

## C. Cubits and sealed states [Essential]

### The states

```dart
sealed class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object?> get props => [];
}
final class ProductsLoading extends ProductsState { ... }
final class ProductsLoaded extends ProductsState {
  ProductsLoaded(List<Product> products, {this.refreshError}) : products = List.unmodifiable(products);
  final List<Product> products;
  final AppException? refreshError;
  @override
  List<Object?> get props => [products, refreshError];
}
final class ProductsEmpty extends ProductsState { ... }
final class ProductsError extends ProductsState { final AppException error; ... }
```

- **`sealed`** means a `switch` over the states must handle every one, and adding a state breaks every such `switch` until it's handled. This is the same idea as `AppException` in Phase 3.
- **`Equatable` + `props`** compares states **by value**. That makes `blocTest`'s `expect` work, and it's how bloc decides that a state is "equal, so skip it".
- **`List.unmodifiable`**: a state's list can never be changed after it's emitted. `add` throws instead of silently breaking equality.
- **No `Initial` state:** these screens start loading immediately, so "initial" would never be visible. **No `NotFound` state:** it's `Error(NotFoundException())`, and the screen chooses the view.
- **`Empty`** is its own state because the screen needs a different view for it (not chips above a blank grid).

### The cubit

```dart
class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit({required this._repository, required this._productId})
    : super(const ProductDetailsLoading());

  Future<void> load() async {
    emit(const ProductDetailsLoading());
    final result = await _fetchProduct();
    if (isClosed) return;
    emit(result);
  }

  Future<ProductDetailsState> _fetchProduct() async {
    try {
      return ProductDetailsLoaded(await _repository.getProduct(_productId));
    } on AppException catch (error) {
      return ProductDetailsError(error);
    } catch (error, stackTrace) {
      if (!isClosed) addError(error, stackTrace);   // a bug: report it
      return const ProductDetailsError(UnknownException());
    }
  }
}
```

| Line | Why |
|---|---|
| `super(const ProductDetailsLoading())` | A cubit always has a state, from the start |
| `required this._repository` | *Private named parameter* (newer Dart): callers write `repository:` |
| `emit(Loading)` at the start | Makes **retry** go back to the spinner. bloc lets the first emit through even though it's equal to the starting state (`_emitted` in its source) |
| `if (isClosed) return;` | The cubit's version of `mounted`. Without it, a late answer → `Bad state: Cannot emit new states after calling close` (proven by probe) |
| `_fetchProduct()` returns a state | Dart rejected a `final result` assigned in both `try` and `catch`. Returning from each branch is clearer anyway |
| `addError` | Sends bugs to `BlocObserver.onError` instead of hiding them; Phase 10 will log them |

**Repeated code, on purpose:** both cubits share about 15 lines of this shape. We'll extract a helper on the **third** copy, after Phase 5 has reshaped `ProductsCubit`.

---

## D. The details screen: `BlocProvider`, `BlocBuilder`, keys [Essential]

```dart
BlocProvider(
  key: ValueKey(productId),
  create: (context) => ProductDetailsCubit(
    repository: context.read<ProductsRepository>(),
    productId: productId,
  )..load(),
  child: Scaffold(
    appBar: AppBar(),
    body: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
      builder: (context, state) => switch (state) {
        ProductDetailsLoading() => const LoadingView(),
        ProductDetailsLoaded(:final product) => _ProductDetailsBody(product: product),
        ProductDetailsError(error: NotFoundException()) => EmptyView(... 'Back to home' ...),
        ProductDetailsError(:final error) => ErrorView(
          error: error,
          onRetry: () => context.read<ProductDetailsCubit>().load(),
        ),
      },
    ),
  ),
)
```

- **`create` runs once** (it replaces `initState`). **`..load()`** (cascade) starts loading and still returns the **cubit**. Without it, the spinner would show forever; with `.load()` (a single dot), the code wouldn't compile.
- **`BlocProvider` closes what it created** when it leaves the tree.
- **`ValueKey(productId)` replaces `didUpdateWidget`.** A new id gives a new key, so the old provider is removed (its cubit closed) and a new one loads the new product. Proven by probe: without the key, only "loads the new product when the id changes" fails.
- **Object patterns:** `Loaded(:final product)` checks the type and pulls out the field. `Error(error: NotFoundException())` **nests** a pattern. The **specific case comes first**; swapping them gives the analyzer warning `unreachable_switch_case`.
- **No `_ =>` default:** the cubit already turned "anything else" into `UnknownException`, so the four cases are exhaustive.

---

## E. Home: data in the cubit, choices in the widget [Essential]

| Kind | Example | Lives in | Why |
|---|---|---|---|
| **Data from outside** | the catalog | `ProductsCubit` | Loading, errors, retry, refresh, all testable without widgets |
| **UI state** | `_selectedCategory`, `_sort` | `_HomeScreenState` | Only this screen cares, and changing it needs **no request** |
| **Local widget state** | the quantity | `QuantitySelector` | One widget, read once on tap |

- **The test question:** *"Does changing it need a new request?"* Today it doesn't, so the choices stay in the widget. In Phase 5 they become query parameters, so they move to the cubit.
- **`BlocProvider` inside a `State`'s `build`:** `setState` (sorting) rebuilds, but `create` **doesn't** run again, because the provider's **element** survives. Verified on the device: sorting sent **no** request.
- **`sortProducts` copies before sorting** (`[...products]`), which is why the unmodifiable list is safe, and why "Featured" and **Undo** can always restore the original order.

---

## F. Providing dependencies [Essential]

```dart
// ShopLiteApp.build
return RepositoryProvider<ProductsRepository>.value(
  value: widget.productsRepository,
  child: MaterialApp.router(...),
);

// in a screen
create: (context) => ProductsCubit(repository: context.read<ProductsRepository>())..load(),
```

| Rule | Why |
|---|---|
| Provide **above `MaterialApp`** | Every route, the shell, and root-navigator sheets are below it |
| Declare the **interface type** `<ProductsRepository>` | Lookups match the **exact** declared type, never subtypes |
| **`.value`** for what you're handed, **`create:`** for what you build | Ownership: `create` closes what it made; `.value` never disposes |
| `context.read` **only in widgets** | Cubits get dependencies through constructors: plain Dart, fast tests, clean layers (widgets → cubits → repositories) |

**What disappeared:** the repository used to pass through `ShopLiteApp` → `createAppRouter` → `_productDetailsRoute` → screens. Now the router passes **nothing**.

### `ProviderNotFoundException`: caused twice, on purpose

| Probe | Cause | Fix |
|---|---|---|
| Task 5 | `MaterialApp(home: HomeScreen())` with **no provider at all** | Put `RepositoryProvider<ProductsRepository>` above (in tests: `withProductsRepository(...)`) |
| Task 6 | `this.context` (the **State's**, above the `BlocProvider` it builds) | Use the **builder's** `context`, which is below the provider |

A third way (discussed, not caused): providing `DummyJsonProductsRepository` but reading `ProductsRepository`.

**How to read the message:** *which type* wasn't found and *from where*. Remember the hint: providers added in `main` need a **hot restart**.

### `get_it`: postponed (decision)
`main.dart` builds just two objects, and `RepositoryProvider` already solved the pass-through problem. **Revisit in Phase 6**, when storage and auth services arrive with dependencies and `async` setup.

---

## G. Pull-to-refresh and one-off side effects [Essential]

```dart
Future<void> refresh() async {
  final current = state;
  if (current is! ProductsLoaded) return;
  emit(ProductsLoaded(current.products));          // clear the previous refresh error
  final result = await _fetchFirstPage();
  if (isClosed) return;
  emit(switch (result) {
    ProductsError(:final error) => ProductsLoaded(current.products, refreshError: error),
    _ => result,
  });
}
```

- **`RefreshIndicator` owns the spinner:** it spins until the `Future` from `onRefresh` completes. So there's no loading state and no "refreshing" flag, and the grid stays visible.
- **A failed refresh keeps the data:** `Loaded(products, refreshError: …)`, not `Error`. **Show a full-screen error only when there's nothing better to show.**
- **Clear first:** without it, the **second** failure in a row emits an equal state, which is skipped, so no snackbar. With nothing to clear, the clear emit is itself equal and skipped. Real sequences:
  ```text
  1st failed pull:  Loaded(p) → Loaded(p, refreshError)
  2nd failed pull:  Loaded(p, refreshError) → Loaded(p) → Loaded(p, refreshError)
  ```
- **`is!` promotion:** after `if (current is! ProductsLoaded) return;`, `current` is known to be `ProductsLoaded`.

### Builder vs. listener

```dart
BlocConsumer<ProductsCubit, ProductsState>(
  listener: (context, state) {
    if (state case ProductsLoaded(:final refreshError?)) { /* show snackbar */ }
  },
  builder: (context, state) => switch (state) { ... },
)
```

| Widget | Job | Runs |
|---|---|---|
| `BlocBuilder` | **What to show** | Whenever it rebuilds (also from a parent's `setState`) |
| `BlocListener` | **What to do once**: snackbars, dialogs, navigation | Once per **new** state from the cubit |
| `BlocConsumer` | Both | — |

In a builder, the snackbar would come back on **every chip tap or sort** while `refreshError` is still set.

---

## H. Dart concepts new in Phase 4

| Concept | Example | Remember |
|---|---|---|
| Private named parameters | `ProductsCubit({required this._repository})` | Callers write `repository:` |
| Cascade `..` | `ProductsCubit(...)..load()` | Calls a method, returns the **object** |
| Object patterns | `ProductsLoaded(:final products)` | Type check + field extraction |
| Nested patterns | `Error(error: NotFoundException())` | Patterns inside patterns |
| Null-check pattern | `ProductsLoaded(:final refreshError?)` | Matches only non-null; binds non-null |
| If-case | `if (state case ProductsLoaded(...)) { }` | A pattern in an `if` |
| `is!` + type promotion | `if (current is! ProductsLoaded) return;` | Afterwards `current` is that type |
| `List.unmodifiable` | `ProductsLoaded(...)` | Changes throw `UnsupportedError` |
| Super parameters (warm-up) | `required ValueNotifier<int> super.notifier` | Pass straight to the parent, even narrowing the type |
| Definite assignment limits | `final result;` in try + catch | A catch may run after the try assigned |
| `unreachable_switch_case` | general case before specific | The analyzer catches wrong order |

---

## I. Important decisions

| Decision | Why | Revisit when |
|---|---|---|
| Cubit only, no full Bloc | Every state explicit, less ceremony | If events need debouncing/transformers (maybe Phase 5 search) |
| No `Initial`, no `NotFound` state | Never visible / already expressed by `AppException` | A screen that waits for the user (search) |
| `Empty` as its own state | Different view than an empty grid | — |
| Unmodifiable lists in states | Mutation throws instead of silently breaking equality | — |
| Category and sort stay in the widget | UI state, no request | Phase 5 (server-side filter/sort) |
| `ValueKey(productId)` on the provider | Replaces `didUpdateWidget`; can't forget a comparison | — |
| `RepositoryProvider.value` above `MaterialApp` | Everyone can read it; `main.dart` owns it | — |
| **`get_it` postponed** | Two objects don't need a service locator | **Phase 6** |
| **`mocktail` not added** | The hand-written fake covers everything | When a dependency is hard to fake by hand |
| No `copyWith` | One optional field; the constructor is enough | When states grow more fields |
| Refresh error kept inside `Loaded` | Don't hide good data | Phase 5 load-more uses the same idea |
| Duplicate fetch shape in two cubits | Extract on the third copy | After Phase 5 |
| Shared fake plays "buggy repository" (`error: Object?`) | One helper instead of a private class per test file | — |

---

## J. Testing

### What Phase 4 added (162 tests in total; 138 at the end of Phase 3)

| File | Tests | Protects |
|---|---|---|
| `cubits/product_details_cubit_test.dart` | 7 | Start state, loaded, not found, error, retry, bug → unknown + reported, close while loading |
| `cubits/products_cubit_test.dart` | 14 | Same as details + first page + empty + unmodifiable list + **6 refresh tests** (replace, keep on failure, twice, empty, only when loaded, close while refreshing) |
| `screens/home_screen_test.dart` | 12 (+3) | Empty catalog view, pull to refresh, failed refresh keeps products + snackbar |
| Existing screen, router, accessibility, layout tests | unchanged | Proved the refactors kept the behaviour |

### Techniques new in Phase 4

| Technique | Use |
|---|---|
| `blocTest(build:, act:, expect:)` | The list of emitted states, compared with `Equatable` |
| `seed:` | Start from a given state without emitting it (refresh tests) |
| `setUp:` inside `blocTest` | A fresh fake per test, shared with `act`/`verify` |
| `verify:` | Check things after `act`, e.g. `requestedPages` |
| `errors:` | Check what was reported with `addError` |
| `expect: () => <ProductsState>[]` | "Emits nothing" |
| `Completer` gate + `close()` | Prove the `isClosed` guard |
| `tester.fling(find.byType(GridView), Offset(0, 300), 1000)` | A pull-to-refresh gesture |
| `withProductsRepository(...)` | Tests provide dependencies the way the app does |
| **Refactor under unchanged tests** | Tasks 3 and 5: same tests, new internals |
| **Probe a guard by removing it** | `isClosed` ×2, `ValueKey`, the State's `context` |

---

## K. Debugging stories and lessons

| What happened | Cause | Lesson |
|---|---|---|
| Two `uri:` lines for one product | dio's `LogInterceptor` logs the request **and** the response | Read the lines around a log line before concluding "double request" |
| First retry still failed on the device | Tapped ~1 s after airplane mode off; DNS wasn't up yet (`Failed host lookup`) | Correct behaviour (Loading → Error); networks need a moment |
| The sort sheet "did nothing" | adb taps lost or landing during animation | Read real positions with `uiautomator dump`; confirm the widget tests first |
| No snackbar in a screenshot | Taken after the 4-second snackbar had gone | Time the screenshot to the log event |
| `final result` rejected | A `catch` can run after the `try` assigned | Return from each branch |
| Scripted edits partly missed | Files with Windows line endings (`\r\n`) | Use the Edit tool for multi-line changes; check `git diff --stat` |
| A command hung | A stray `python3` call waited for input | Stopped it; verified nothing changed |

---

## L. Git in Phase 4

- **`refactor:`** for the two changes that kept behaviour identical (Tasks 3 and 5), proven by **unchanged tests**.
- **Two commits per task** when a task had two halves (cubit, then screen), with each commit working on its own.
- **`git push -u`** on the branch's first push sets the upstream.
- **Staged but not committed (Task 5):** caught by checking `git log` after "Done", same as Phase 3. Always check `git status` after each step.
- The CRLF notices are Git's normal Windows line-ending handling.

---

## M. Phase 4 completion checklist

| Criterion | Status | Evidence |
|---|---|---|
| No business or network logic inside widgets | ✅ | No `FutureBuilder`; repository calls only in cubits; remaining `setState` is UI state |
| Every screen handles loading, empty, error (with retry), success | ✅ data screens | Home and details handle all of them. The Categories tab still uses mock data (Phase 5) |
| All cubit tests pass | ✅ | 21 cubit tests; 162/162 in total |
| …and you wrote at least one yourself | ⏸️ **Deferred** | Your decision B: our workflow has Claude implementing; revisit if you want hands-on practice |
| You can explain `ProviderNotFoundException` and how to cause and fix it | ✅ | Caused twice by probes; explained in the knowledge check |
| Phase 4 knowledge check | ✅ | All six answered; corrections on which two causes we triggered and the skipped clear emit |
| Merged into `main` and tagged `phase-4` | ⏳ | Next step after this file is committed |

---

## N. Carried forward

| Item | Where it goes |
|---|---|
| `get_it` for a growing set of services | **Phase 6** (decision) |
| Category and sort as API parameters (move into the cubit) | **Phase 5** |
| Pagination ("load more" that keeps loaded pages on failure) | **Phase 5** |
| Categories tab on the API instead of mock data | **Phase 5** |
| Extract the shared cubit fetch shape (third copy) | After Phase 5 |
| `BlocObserver` to log `addError` reports | **Phase 10** |
| Writing a cubit test yourself | Optional, any time |

---

## O. Knowledge check

Answer each one **before** opening the Answer Key.

1. What does `emit` do, and when does it do **nothing**?
2. Why does `load()` emit `Loading` at the start, even though the cubit starts in `Loading`?
3. What does `if (isClosed) return;` protect against? Does it cancel the request?
4. Why does `BlocProvider(create: ...)` need `..load()`, and what would `.load()` do?
5. How does `ValueKey(productId)` replace `didUpdateWidget`?
6. Which state lives in `ProductsCubit`, and which stays in `_HomeScreenState`? What's the test question?
7. Why `RepositoryProvider<ProductsRepository>.value(...)` (both the type and `.value`)?
8. Why does the cubit get the repository through its constructor, while the screen uses `context.read`?
9. Why does a failed refresh keep `ProductsLoaded`, and why clear `refreshError` first?
10. Why is the snackbar in a `listener` and not in the `builder`?

---

## P. Readiness for Phase 5

### Phase 4 concepts you'll use right away

| Phase 4 concept | How it appears in Phase 5 |
|---|---|
| `ProductsCubit` + sealed states | Grows `hasMore`, `isLoadingMore`, `loadMoreError` for pagination |
| `refreshError` (keep data on failure) | A load-more error must not wipe the list |
| UI state vs. data | Category and sort become request parameters, so they move to the cubit |
| `seed:` / `act:` / `expect:` | Pagination and search tests |
| `isClosed` | Still needed; search adds a `Timer` to cancel in `close()` |
| `BlocListener` | Load-more failure messages |
| Keys | `ValueKey` on grid items when lists reorder |

### Self-assessment checklist

- [ ] I can write a cubit with sealed, `Equatable` states, and test it with `blocTest`.
- [ ] I can explain why equal states are skipped and how that can hide a change.
- [ ] I can place a `BlocProvider` and explain how long its cubit lives.
- [ ] I know when to use `BlocBuilder`, `BlocListener` and `BlocConsumer`.
- [ ] I can decide whether a piece of state is local or belongs in a cubit.
- [ ] I can provide a dependency with `RepositoryProvider` and read it with `context.read`.
- [ ] I can cause and fix `ProviderNotFoundException`.
- [ ] I can explain which `context` is above or below a provider.
- [ ] I can keep good data on screen when an update fails.

---

## Answer Key

<details>
<summary><strong>Click to show answers</strong> (try the questions first!)</summary>

**1. `emit`**
It stores the new state and notifies listeners (`BlocBuilder`, `BlocListener`). It does **nothing** when the new state equals the current one (`==`, via `Equatable`), except for the very first emit. It **throws** after the cubit is closed.

**2. `Loading` at the start**
For retry: after an error, `load()` must take the screen back to the spinner. On the very first call it's equal to the starting state, but bloc still lets the first emit through.

**3. `isClosed`**
A closed cubit (its `BlocProvider` left the tree) throws on `emit`. The guard drops a late answer instead. It does **not** cancel the request; the answer arrives and is ignored.

**4. `..load()`**
`create` must return the cubit. The cascade calls `load()` and returns the cubit. Without it, nothing loads (spinner forever). `.load()` would return a `Future<void>`, which doesn't compile as a cubit.

**5. `ValueKey(productId)`**
Same type and same key mean Flutter keeps the element (and its cubit). A new id gives a new key, so the old provider is removed (cubit closed) and a new one created (new cubit, new request). Nothing to compare by hand.

**6. Cubit vs. widget**
The catalog (loaded from outside) lives in the cubit; the selected category and sort (UI choices) stay in the State. Test question: *does changing it need a new request?* Not yet, so the widget. In Phase 5, yes.

**7. `RepositoryProvider<ProductsRepository>.value`**
The type: lookups match the exact declared type, and screens ask for the interface. `.value`: `main.dart` created the repository; the provider shares it without owning (or disposing) it.

**8. Constructor vs. `context.read`**
Cubits are plain Dart with no `BuildContext`: tests pass a fake directly, with no widgets. Only the widget layer looks things up in the tree. Dependencies flow widgets → cubits → repositories.

**9. Failed refresh**
The products are still good, so hiding them behind a full-screen error would be worse for the user; `refreshError` rides along. Clearing first makes each failure a new state; otherwise the second failure in a row is equal to the current state and skipped (no snackbar).

**10. Listener vs. builder**
A builder runs on every rebuild, including Home's `setState` for chips and sorting, so the snackbar would reappear. A listener runs once per **new** state from the cubit.

</details>
