# Phase 2 Review: App Shell, Navigation & Mini Design System

> **How to use this file**
> Read one section at a time. Before reading an explanation, try to explain the concept **out loud** using our ShopLite code. If you can predict what happens when the code changes, you understand it. If you can only repeat it, you've memorized it.
>
> Labels used below:
> - **[Essential]**: you will use this in every remaining phase.
> - **[Useful]**: good to know now; depth can come later.

**State of the branch at the end of Phase 2** (verified from the Git history):

```
* 81e36af feat: improve screen reader support and add dark theme
* 8ea2e5b feat: add sort bottom sheet with undo snackbar
* 14c2b2e feat: add spacing tokens and shared EmptyView
* 82c6480 feat: add categories tab with category product pages
* 0c91e35 refactor: extract product grid and shared catalog helpers
* 1ba001c feat: add bottom navigation shell with four tabs
* be2ab64 feat: add go_router with product routes by id
* 0809ce8 docs: add phase 1 review
*   0937650 (main, tag: phase-1) Merge phase-1-product-ui: static catalog UI
```

On `phase-2-navigation`: `flutter analyze` reports **No issues found**; `flutter test` reports **89/89 passed** (25 at the end of Phase 1).

**How we worked:** Claude implemented each task **test-first** (tests written before the code, watched failing, then passing), explained it, and asked learning-check questions. You studied the code, answered, and approved every Git action. Every task ended with an emulator check **and a search of the console output for exceptions**.

---

## A. What we built

### The six tasks

| # | Task | Main concept | Commit(s) |
|---|---|---|---|
| 1 | go_router, product routes by id | Declarative routing, path parameters, not-found pages | `be2ab64` |
| 2 | Bottom-navigation shell with 4 tabs | `StatefulShellRoute`, one navigator per tab | `1ba001c` |
| 3 | Categories tab + `/categories/:category` | Refactor first, then feature; the URL decides the tab | `0c91e35`, `82c6480` |
| 4 | Mini design system | Spacing tokens, `EmptyView`, empty states that lead somewhere | `14c2b2e` |
| 5 | Feedback patterns | Bottom sheet that returns a result, snackbar with Undo | `8ea2e5b` |
| 6 | Accessibility + dark theme | Semantics tree, automated guidelines, `ThemeMode.system` | `81e36af` |

### Where the code lives (new in Phase 2 marked ★)

```
lib/
  main.dart
  app/
    app.dart                         ShopLiteApp (now Stateful: owns the router)
    router.dart                    ★ the route table
    app_shell.dart                 ★ Scaffold + NavigationBar around the tabs
    theme/
      app_theme.dart                 buildAppTheme({brightness})
      app_spacing.dart             ★ AppSpacing.xs … xl
  core/
    utils/price_formatter.dart
    utils/text_format.dart         ★ capitalize, ratingSemanticsLabel
    widgets/empty_view.dart        ★ the shared empty / not-found view
  features/
    products/
      data/
        models/product.dart
        mock_products.dart           + mockCategories, findMockProductById, findMockProductsByCategory
        product_sort.dart          ★ ProductSort + sortProducts
      presentation/
        screens/home_screen.dart     chips + grid + sort button
        screens/product_details_screen.dart   receives an id
        widgets/product_grid.dart  ★ extracted from HomeScreen
        widgets/sort_options_sheet.dart  ★ the "Sort by" sheet + sortLabel
        widgets/ (product_card, product_image, category_chips, quantity_selector)
    categories/presentation/screens/
      categories_screen.dart       ★
      category_products_screen.dart ★
    cart/presentation/screens/cart_screen.dart        ★ (empty state until Phase 6)
    profile/presentation/screens/profile_screen.dart  ★ (placeholder until Phase 7)
```

---

## B. Routing with go_router

### Declarative routing [Essential]

In Phase 1, navigation was **imperative**: "push this screen object now". With go_router it's **declarative**: every screen has an **address**, described once in a route table, and you navigate by location.

```
/                                  → HomeScreen
/product/:id                       → ProductDetailsScreen          (Home tab)
/categories                        → CategoriesScreen
/categories/:category              → CategoryProductsScreen
/categories/:category/product/:id  → ProductDetailsScreen          (Categories tab)
/cart                              → CartScreen
/profile                           → ProfileScreen
anything else                      → "Page not found"
```

### Nesting decides the back stack [Essential]

```dart
GoRoute(
  path: '/',
  builder: (context, state) => const HomeScreen(),
  // Nested under '/', so opening '/product/78' directly
  // still puts the home screen underneath it.
  routes: [_productDetailsRoute()],
),
```
Opening `/product/78` **directly** builds the stack **[Home, Details]**, even though nobody pushed Home. A **top-level** product route would build only **[Details]**: no back arrow, and the system back would leave the app. We proved both versions with a probe.

### Path parameters come from outside, so validate them [Essential]

```dart
GoRoute _productDetailsRoute() {
  return GoRoute(
    path: 'product/:id',
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id']!);
      if (id == null) {
        return const _PageNotFoundScreen();
      }
      return ProductDetailsScreen(productId: id);
    },
  );
}
```
- Path parameters are always **strings**.
- `int.tryParse('abc')` returns **`null`**; `int.parse('abc')` would **throw**, showing the red error screen.
- An id can be valid but unknown (`/product/999999`), so the details screen handles "not found" too.
- Unknown paths go to `errorBuilder`.
- `_productDetailsRoute()` is a **function**, used in two branches, so the parsing logic exists once.

### The router lives as long as the app [Essential]

```dart
class _ShopLiteAppState extends State<ShopLiteApp> {
  // Created once, when the app starts. Creating it in build() would throw
  // away the navigation history on every rebuild.
  final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
  ...
```
| Where the router could live | Problem |
|---|---|
| Inside `build()` | A new router on every rebuild → navigation history lost |
| A global variable | One router for the whole program → **tests leak navigation into each other** |
| **A field of the app's `State`** ✅ | Survives rebuilds, one per app, disposed at the end (Phase 1 lifecycle rules) |

`createAppRouter({initialLocation})` returns a **fresh** router on every call, which is what lets each test start anywhere and clean up with `addTearDown(router.dispose)`.

### `push`, `go`, `goBranch` [Essential]

| Call | Meaning | Our use |
|---|---|---|
| `context.push('/product/7')` | Put a page **on top**; back returns to where you were | Opening a product |
| `context.go('/')` | Go **to** a location; the stack is rebuilt from the route table | "Back to home", "Start shopping" in empty states |
| `navigationShell.goBranch(i)` | Switch tabs | The bottom navigation bar |

**Rule of thumb:** `push` = "open this, and let me come back"; `go` = "take me there".

### The URL decides the tab [Essential]

`/product/78` belongs to the **Home** branch. Pushed from the Categories tab, it would open **in the Home tab**: the bar would jump to Home, and back would lead to the catalog. That's why the Categories tab has its own `/categories/:category/product/:id`. A test checks that the bar stays on **Categories** (`selectedIndex == 1`).

---

## C. The app shell

### `StatefulShellRoute.indexedStack` [Essential]

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      AppShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [/* '/' + product */]),          // Home
    StatefulShellBranch(routes: [/* '/categories' + … */]),      // Categories
    StatefulShellBranch(routes: [/* '/cart' */]),                // Cart
    StatefulShellBranch(routes: [/* '/profile' */]),             // Profile
  ],
),
```
- **One branch = one tab = its own `Navigator`** with its own stack.
- **`indexedStack`** uses Flutter's `IndexedStack`: **all** tabs stay in the tree, and only one is **shown**. Hidden tabs are not destroyed.

### `AppShell`

```dart
return Scaffold(
  body: navigationShell,
  bottomNavigationBar: NavigationBar(
    selectedIndex: navigationShell.currentIndex,
    onDestinationSelected: (index) {
      // Tapping the tab you're already on goes back to its first screen.
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    },
    destinations: const [ ... ],
  ),
);
```
- The bar **shows** what the router says (data down) and **reports** taps (events up).
- `initialLocation: true` only when you tap the **active** tab, which returns it to its first screen.
- **Nested `Scaffold`s are normal:** the shell's (for the bar) and each screen's (for its own `AppBar`).

### What survives what (Phase 1 table, extended) [Essential]

| Action | What happens to a screen | `dispose`? |
|---|---|---|
| Push another screen on top | Covered | No |
| **Switch tabs** | **Hidden** (still in the tree) | **No** |
| Pop (back) | Removed | **Yes** |
| Hot restart | All Dart state thrown away | No log at all |

**Verified:** a probe scrolled the Home grid to offset 500, visited Cart, came back: still **500**. The emulator log showed **no `dispose`** for the details screen while we were in Cart.

---

## D. Which navigator? [Essential]

```
Root Navigator             ← whole-app overlays belong here
 └─ AppShell (NavigationBar)
     ├─ Home tab Navigator
     ├─ Categories tab Navigator
     ├─ Cart tab Navigator
     └─ Profile tab Navigator
```

`Navigator.of(context)`, `showModalBottomSheet`, and `showDialog` use the navigator **nearest above `context`**. In a tab, that's the **tab's** navigator.

**The bug we found:** the sort sheet first opened on the Home tab's navigator, **below** the bar. The bar wasn't dimmed and **still worked** while the sheet was open (a test proved a tab switch: `Expected: <0>  Actual: <2>`). The fix:

```dart
final chosen = await showModalBottomSheet<ProductSort>(
  context: context,
  // Open on the app's top-level navigator, above the bottom navigation
  // bar, so the sheet covers the whole app instead of only this tab.
  useRootNavigator: true,
  ...
```

**Nested navigators mattered three times in this phase:** route nesting → back stacks (Task 1), per-tab navigators → kept state (Task 2), root navigator → overlays that cover everything (Task 5).

---

## E. Mini design system

### Spacing tokens [Essential]

```dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}
```
- **17 raw numbers → named tokens**, so the app has one spacing vocabulary and one place to change it.
- A class with only static members is acceptable **for grouped constants** (like Flutter's `Colors` and `Icons`).
- **`abstract`** means no instances; **`final`** means no subclasses outside this library (Dart 3 class modifiers).
- `const SizedBox(height: AppSpacing.lg)` stays `const`, because the tokens are `static const`.

### `EmptyView` [Essential]

```dart
const EmptyView({
  super.key,
  required this.icon,
  required this.title,
  this.message,
  this.action,       // any Widget, usually a FilledButton
});
```
- **Composition:** `action` is a `Widget?`, so the caller decides what it is. The cost: callers *could* pass inconsistent styles, so we keep a convention (a `FilledButton`).
- **`Center` + `SingleChildScrollView` + `Column(mainAxisSize: min)`**: centered when it fits, scrollable when it doesn't (landscape + 200% text, tested).
- Used in **5 places**: page not found, product not found, empty category, Cart, and Profile.
- **UX rule: an empty state is never a dead end.** It says what happened and why, and offers a way forward.

### What we deliberately did *not* build

| Item | Why not (yet) |
|---|---|
| `LoadingView`, `ErrorView` | Nothing loads or fails before the API (Phase 3) |
| `AppButton` | `FilledButton` + the theme already give consistency; a wrapper only earns its place with **behavior** |

**Principle:** build shared components at their **first real use**, so they're shaped by real needs and tested.

---

## F. Feedback patterns

### An overlay that returns a result [Essential]

```dart
Future<void> _chooseSort() async {
  final previous = _sort;

  final chosen = await showModalBottomSheet<ProductSort>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => SortOptionsSheet(selected: _sort),
  );

  if (chosen == null || chosen == previous || !mounted) {
    return;
  }
  setState(() { _sort = chosen; });
  ...
```
- A modal sheet is a **route**. `showModalBottomSheet<T>` returns a **`Future<T?>`**.
- **`await`** pauses this method (not the app) until the sheet closes.
- The result is whatever the sheet passed to `Navigator.of(context).pop(value)`, or **`null`** if dismissed (tap outside, swipe down, system back).
- **After every `await` in a `State`: check `mounted`** before `setState` or `context`. The screen may be gone. You'll use this in Phase 3 for every API call.

### The snackbar with Undo [Essential]

```dart
ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      content: Text('Showing: ${sortLabel(chosen)}'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (mounted) {
            setState(() { _sort = previous; });
          }
        },
      ),
    ),
  );
```
- `ScaffoldMessenger` is created by `MaterialApp` and shows snackbars on the **outermost** `Scaffold` (the shell), so they appear above the bar.
- **`..` (cascade):** call several methods on the same object.
- `hideCurrentSnackBar()` first, so messages don't **queue** up.
- The Undo closure **remembers `previous`**.

| Pattern | Blocks the user? | Use for |
|---|---|---|
| Snackbar | No | Confirmations, especially **with Undo** |
| Bottom sheet | Until dismissed | Choosing from options |
| Dialog | Demands a decision | Destructive confirmations (Phase 6) |

---

## G. Accessibility and dark theme

### The semantics tree [Essential]

Screen readers (TalkBack, VoiceOver) don't read pixels. They read the **semantics tree**: nodes with a **label**, a **value**, a **role** (button, heading, selected), and **actions** (tap). Material widgets fill it in. Plain `Text` is **merged** into the nearest **container**.

### Automated guidelines: a floor, not a finish line

```dart
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));   // ≥ 48×48 dp
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));   // has a label
await expectLater(tester, meetsGuideline(textContrastGuideline));       // ≥ 4.5 : 1
```
They run on **7 screens × light and dark + the sort sheet**. All passed on the first run, thanks to the Phase 1 habits (tooltips, `semanticLabel`, color roles). But they only check that a label **exists**, not that it **makes sense**.

### What we fixed

| Widget | Before | After |
|---|---|---|
| Product card | "…, $9.99, **2.6**" (no role) | "…, $9.99, **Rated 2.6 out of 5**", **button** |
| Details title | inside one long merged block | its own **heading** |
| Quantity | "…Quantity, 1, The Essence…" mixed into text | "**Quantity, 1**" group with two labeled buttons |

| Tool | Use |
|---|---|
| `Text(..., semanticsLabel: ...)` | Different words for ears than for eyes |
| `Semantics(button: true)` | Declares a role |
| `Semantics(container: true, header: true)` | A heading with **its own node**. Without `container`, the flag would mark the whole merged block. |
| `Semantics(container: true, label:, value:)` | Groups a control and announces its current value |
| `ExcludeSemantics` | Hides visible text that would otherwise be read twice |

### Dark theme [Essential]

```dart
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _brandSeedColor, brightness: brightness),
    ...
```
```dart
theme: buildAppTheme(),
darkTheme: buildAppTheme(brightness: Brightness.dark),
themeMode: ThemeMode.system,
```
**Zero widget changes were needed**, because widgets use color **roles**. In dark mode the roles resolve to different colors (for example, a lighter `primary`). A hard-coded `Colors.deepPurple` price on a dark card would have about **2.5 : 1** contrast, which the dark-mode contrast tests would fail.

---

## H. Dart concepts new in Phase 2

| Concept | Example | Remember |
|---|---|---|
| Extension methods | `context.push(...)` from go_router | Packages can add methods to existing types |
| `int.tryParse` | `int.tryParse('abc')` → `null` | Safe parsing of outside input |
| **Type promotion: locals only** | `final selectedCategory = _selectedCategory;` | Fields aren't promoted after a `null` check; local copies are. `!` would compile but can crash. |
| `enum` | `ProductSort { featured, ... }` | A fixed set of values; typos are compile errors; `.values` lists them |
| `switch` statement (Dart 3) | `sortProducts` | No fall-through after code; an **empty** case *does* fall through (hence `break;`) |
| Switch expression | `return switch (sort) { ... => 'Featured', ... };` | Produces a value; exhaustive |
| Copy with spread | `final sorted = [...products];` | Never sort the input in place (a `const` list would throw) |
| Comparator | `(a, b) => b.rating.compareTo(a.rating)` | Negative/zero/positive; swap `a` and `b` for descending |
| Collection `if` + spread | `if (message != null) ...[gap, Text(...)]` | Conditionally add several children |
| Cascade `..` | `ScaffoldMessenger.of(context)..hide…()..show…()` | Several calls on one object |
| `Future<T?>` + `async`/`await` | `await showModalBottomSheet<ProductSort>(...)` | A value later, possibly `null` |
| Destructuring pattern | `for (final MapEntry(key: name, value: location) in _screens.entries)` | Unpack an object into variables |
| Class modifiers | `abstract final class AppSpacing` | No instances, no outside subclasses |
| Default parameter for compatibility | `buildAppTheme({Brightness brightness = Brightness.light})` | Old calls keep working |
| `this.` to tell field from local | `final message = this.message;` | Same name, different variable |

---

## I. Important decisions

| Decision | Why | Revisit when |
|---|---|---|
| Router created in `_ShopLiteAppState`, via a function | Survives rebuilds; a fresh one per test | — |
| Product route nested in **each** tab that opens products | The URL decides the tab | Phase 6 (wishlist/cart may open products too) |
| `indexedStack` (all tabs kept alive) | Users never lose their place; 4 light tabs | If a tab becomes heavy |
| Refactor committed separately from the feature | Easier to review, revert, and debug | Always |
| `EmptyView` takes `Widget? action` | Flexibility; convention keeps it consistent | If styles drift |
| `LoadingView`/`ErrorView`/`AppButton`/dialog postponed | Built at their first real use | Phases 3, 6, 7 |
| Sort logic in `data/`, labels in `presentation/` | Pure, testable logic; text is a UI concern | Phase 5 (API sorting) |
| Modal sheet on the **root** navigator | Must cover the whole app | Every future overlay |
| Accessibility guidelines in **both** themes | Catches contrast regressions automatically | — |
| `ThemeMode.system` | Follows the user's choice | An in-app theme switch (optional, later) |

---

## J. Testing

### 89 tests (25 at the end of Phase 1)

| File | Tests | Protects |
|---|---|---|
| `app/router_test.dart` | 9 | Routes, deep links, not found, Categories tab routing, "Back to home" |
| `app/app_shell_test.dart` | 7 | Tabs, kept stacks, active-tab reset, kept selection, empty cart → shopping, **sheet covers the bar** |
| `app/accessibility_test.dart` | 15 *(generated by loops)* | 3 guidelines × 7 screens × light/dark + the sort sheet |
| `app/screen_reader_test.dart` | 3 | Card = button with rating; title = heading; quantity group + value |
| `app/theme_test.dart` | 4 | Light by default, dark from the same seed, follows the phone |
| `core/utils/text_format_test.dart` | 4 | `capitalize` (incl. empty string), `ratingSemanticsLabel` |
| `core/widgets/empty_view_test.dart` | 4 | Parts shown/hidden, action works, no overflow at 200% |
| `features/products/data/mock_products_test.dart` | 5 | Categories, filtering, lookup by id |
| `features/products/data/product_sort_test.dart` | 5 | Each sort order; the input list is untouched |
| `features/products/presentation/screens/home_sort_test.dart` | 6 | Sort sheet, snackbar + Undo, dismissal, with filter, marked option, 200% |
| `features/categories/presentation/screens/categories_screen_test.dart` | 1 | Category list with counts |
| *Phase 1 files (updated where behavior changed)* | 26 | Formatter, chips, details, quantity, responsive layout, app start. The 25 Phase 1 tests + 1 added in Task 1 (unknown product id → "Product not found") |

### Techniques new in Phase 2

| Technique | Use |
|---|---|
| **Test-first (red → green)** | Write the test, watch it fail **for the right reason**, then implement |
| **Stub to get a behavioral red** | An empty class or a "do nothing" function lets tests compile and fail on behavior |
| **Refactor checkpoint** | Run the unchanged suite after restructuring, before adding features |
| `createAppRouter(initialLocation: ...)` + `addTearDown(router.dispose)` | Start any test on any page |
| `find.descendant(of:, matching:)` | "This text **inside** the `NavigationBar`" (avoids ambiguous finders) |
| `tester.widget<T>(finder).property` | Read a widget's data, e.g. `selectedIndex`, or a card's `product.id` |
| `tester.tapAt(offset)` / `tester.getCenter(finder)` | Tap a screen position (a barrier, or whatever covers a widget) |
| `find.widgetWithText(ListTile, '...')` | The tile that contains this text |
| `tester.ensureSemantics()` + `isSemantics(...)` | What a screen reader announces |
| `meetsGuideline(...)` | Automated accessibility checks |
| `platformBrightnessTestValue` | Simulate dark mode |
| **Probes** (temporary tests, deleted after) | Investigate behavior with evidence: top-level routes, scroll offsets, system back, semantics |

---

## K. Debugging stories and lessons

| What happened | Cause | Lesson |
|---|---|---|
| Sheet left the navigation bar usable | Opened on the tab's (nearest) navigator | Overlays covering the app → `useRootNavigator: true` |
| `containsSemantics` reported as deprecated | Flutter API changed | Read the SDK docs for the replacement (`isSemantics`); fix deprecations early |
| Tests failed to **compile** instead of failing on behavior | Screens didn't exist yet | Add minimal stubs to get a meaningful red |
| `flutter run` timed out: "log reader stopped unexpectedly" | Emulator/tooling hiccup (the build was fine) | Read the log; retry once; don't change code for a tooling issue |
| Emulator went black: "Application Not Responding: system" | The emulator's system UI froze | Check `mCurrentFocus`, crashes, and exceptions before blaming the app |
| `Width is zero` in every launch log | Android's zero-width first frame | Already handled by the Phase 1 fix; still **0 exceptions** |
| The first automated tap after launch sometimes lost | Emulator input timing | Verify each step's effect (logs/screenshots); retry |
| A "four widgets" question was wrong (it was 3 + a helper) | My counting mistake in a question | Verify counts against the real diff |
| Commit file count first stated as 15 | My miscount; the real number was 14 | **Trust `git diff --staged --stat`**, not memory |

---

## L. Git in Phase 2

- The **Phase 1 review** was the first commit on the Phase 2 branch, because untracked files belong to no branch.
- **`refactor:` committed separately from `feat:`** (Task 3): each commit is green on its own, and either can be reverted alone.
- When one file contains two kinds of change (tokens + `EmptyView` in `product_details_screen.dart`), splitting needs partial staging. We used **one commit** and said so in the message.
- Every commit was checked with `git diff --staged --stat` **before** committing.

---

## M. Phase 2 completion checklist

| Criterion | Status | Evidence |
|---|---|---|
| Switching tabs keeps each tab's scroll position | ✅ | Probe: offset 500 → 500; tests for kept stack and kept selection |
| Android back button behaves correctly inside tabs and from details | ✅ | Probe with the system back; `pageBack` tests |
| Data screens use shared state views | ✅ for empty states | `EmptyView` × 5; `LoadingView`/`ErrorView` moved to Phase 3 by decision |
| Icon-only buttons have semantic labels | ✅ | `labeledTapTargetGuideline` on every screen, both themes |
| All six tasks implemented, tested, and committed | ✅ | Section A |
| Accessibility guidelines + screen-reader checks | ✅ | 15 + 3 tests |
| Dark theme following the system | ✅ | 4 tests + live switch on the emulator |
| Phase 2 knowledge check | ✅ | 5 fully correct, 1 refined (the URL decides the tab) |
| Merged into `main` and tagged `phase-2` | ⏳ | Next step after this file is committed |

---

## N. Carried forward

| Item | Where it goes |
|---|---|
| `LoadingView`, `ErrorView` | **Phase 3**, with the first API calls |
| Details screen reads `findMockProductById` | **Phase 3**: fetch `/products/{id}` |
| Home reads `mockProducts` directly | **Phases 3–4**: repository + Cubit |
| Sorting and categories done locally | **Phase 5**: API query parameters and `/products/categories` |
| Confirmation dialog | **Phase 6**: "Remove from cart?" |
| Cart tab badge | **Phase 6** |
| `/login`, protected routes (`redirect`) | **Phase 7** |
| `AppButton` with a loading state | **Phase 7**, if the login button needs it |
| Back at a non-Home tab's root leaves the app | **Phase 10**: decide whether back should jump to Home first |
| Quantity as an "adjustable" control for screen readers | Optional |
| `QuantitySelector` lifecycle logs | **Phase 10** |

---

## O. Knowledge check

Answer each one **before** opening the Answer Key.

1. Why is `ShopLiteApp` a `StatefulWidget` now? Name two places the router must **not** be created, and what would go wrong in each.
2. Opening `/product/78` directly shows a back arrow. Why? What would be different if the product route were top-level?
3. What do `int.tryParse` and `errorBuilder` each protect against? Give one URL for each.
4. What's the difference between `context.push('/product/7')` and `context.go('/')`? Which does "Start shopping" use, and why?
5. Why does a tab keep its scroll position when you visit another tab, but a details screen loses its quantity when you press back?
6. Why do the Categories products open at `/categories/laptops/product/78` and not at `/product/78`?
7. What does `useRootNavigator: true` change, and what was the visible bug without it?
8. `showModalBottomSheet<ProductSort>` returns a `Future<ProductSort?>`. When is the result `null`, and what must be checked after the `await`?
9. The automated accessibility guidelines passed, yet the card said "…, 2.6". What did the guidelines miss, and which three `Semantics`-related tools fixed the announcements?
10. Dark mode needed no widget changes. Why? And how would our tests notice if someone hard-coded `Colors.deepPurple` for a price?

---

## P. Readiness for Phase 3

### Phase 2 concepts you'll use right away

| Phase 2 concept | How it appears in Phase 3 |
|---|---|
| `async` / `await` / `Future<T?>` | Every API call |
| `mounted` after `await` | Every screen that loads data |
| `EmptyView` | Joined by `LoadingView` and `ErrorView`: **loading / empty / error / success** |
| Screens receive ids | `ProductDetailsScreen(productId:)` fetches `/products/{id}` |
| Data logic in `data/` with unit tests | The API client and repository live there |
| Test-first with stubs | Fake repositories for testing screens without the network |
| Probes and console checks | Debugging real network errors |

### Self-assessment checklist

- [ ] I can explain declarative routing and read our route table.
- [ ] I can predict the back stack from the route nesting.
- [ ] I know when to use `push`, `go`, and `goBranch`.
- [ ] I can explain why tabs keep their state, and what "hidden, not destroyed" means.
- [ ] I can explain "nearest navigator" vs. the root navigator.
- [ ] I can add a spacing token and use `EmptyView` on a new screen.
- [ ] I can open a bottom sheet, `await` its result, and handle `null` and `mounted`.
- [ ] I can show a snackbar with an action.
- [ ] I can read and improve what a screen reader announces.
- [ ] I can explain why the dark theme needed no widget changes.
- [ ] I write the test first and check it fails for the right reason.

---

## Answer Key

<details>
<summary><strong>Click to show answers</strong> (try the questions first!)</summary>

**1. Why `ShopLiteApp` is stateful**
The router remembers the navigation history, so it must live as long as the app: in a `State` field (created once, disposed in `dispose`). **Not in `build()`:** every rebuild would create a new router and send the user back to `/`. **Not as a global:** one router would be shared by all tests, so one test's navigation would leak into the next.

**2. The back arrow on `/product/78`**
The product route is **nested** under `/`, so go_router builds the stack [Home, Details] from the table, and `AppBar` shows a back arrow because it can pop. With a **top-level** route, the stack is only [Details]: no back arrow (`canPop` is false), and the system back leaves the app (verified with a probe).

**3. `int.tryParse` and `errorBuilder`**
`int.tryParse` protects against a **non-numeric id**, e.g. `/product/abc`: it returns `null` instead of throwing. `errorBuilder` protects against a **path that matches no route**, e.g. `/nope`. Both show the "Page not found" `EmptyView`.

**4. `push` vs. `go`**
`push` puts a page **on top**; back returns to where you were. `go` navigates **to** a location; the stack is rebuilt from the route table. "Start shopping" uses `go('/')`: it should take you to Home (switching to the Home tab), not stack a page on top of the empty cart with back leading to it again.

**5. Kept scroll vs. lost quantity**
Switching tabs only **hides** the tab (`IndexedStack` keeps every branch in the tree), so its `State` objects, including the grid's scroll position, survive. Pressing back **pops** the details route: `deactivate` → `dispose`, so the `QuantitySelector`'s state is destroyed. Reopening creates a new one starting at 1.

**6. Why `/categories/laptops/product/78`**
The **URL decides the tab**. `/product/78` belongs to the Home branch, so it would open in the Home tab, the bar would jump to Home, and back would go to the catalog. The nested Categories path keeps the product in the Categories tab, and back returns to Laptops → Categories.

**7. `useRootNavigator: true`**
Without it, the sheet used the **nearest** navigator, the Home tab's, so it was drawn below the shell's bar: the bar stayed bright and **tappable**, and a tap switched tabs while the sheet was open (`Actual: <2>`). With the root navigator, the sheet covers the whole app, and a tap there only closes the sheet.

**8. `null` and `mounted`**
`null` when the sheet is dismissed without a choice: tapping outside, swiping down, or the system back. After the `await`, check `mounted` before `setState` or `context`, because the screen may have been removed while waiting. (We also skip the update when the same sort was picked.)

**9. Guidelines vs. meaning**
The guidelines check that tap targets are big enough, that a label **exists**, and that the contrast is sufficient. They can't judge whether the label **makes sense**: "2.6" exists, but means nothing without the star. Fixed with `semanticsLabel` ("Rated 2.6 out of 5"), `Semantics(button: true)` / `Semantics(container: true, header: true)` for roles and headings, and `Semantics(label:, value:)` with `ExcludeSemantics` for the quantity group.

**10. Dark mode and hard-coded colors**
Widgets ask for color **roles** (`colorScheme.primary`), and `ThemeMode.system` picks the light or dark `ThemeData`, generated from the same seed. The roles resolve to dark-friendly colors, with no widget edits. A hard-coded `Colors.deepPurple` price would stay the same on a dark card (about 2.5 : 1 contrast), and `textContrastGuideline`, which runs on every screen **in dark mode**, would fail.

</details>
