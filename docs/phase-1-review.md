# Phase 1 Review: UI Foundations with a Static Catalog

> **How to use this file**
> Read one section at a time. Before reading an explanation, try to explain the concept **out loud** using our ShopLite code. If you can predict what happens when the code changes, you understand it. If you can only repeat it, you've memorized it.
>
> Labels used below:
> - **[Essential]**: you will use this in every remaining phase.
> - **[Useful]**: good to know now; depth can come later.

**State of the project at the end of Phase 1** (verified from the Git history):

```
*   0937650 (main, tag: phase-1) Merge phase-1-product-ui: static catalog UI
|\
| * cde7b9b fix: avoid grid layout error on zero-width first frame
| * ba15b85 feat: make catalog and details layouts responsive
| * d5d4c80 feat: add Poppins font and app logo
| * d3448c5 feat: add central app theme and design tokens
| * c854fcf feat: add quantity selector with lifecycle logging
| * de105e0 feat: add product details screen with navigation
| * 665b793 feat: add category filter chips to home screen
| * 5573280 feat: add home screen with product grid
| * 835eeb4 feat: add product card widget with temporary preview
| * f5e8ae6 feat: add integer-only price formatter with tests
| * a54b4fa feat: add product model and mock catalog data
| * 65f7181 docs: add phase 0 review
|/
*   bf14672 (tag: phase-0) Merge phase-0-setup: project setup and tooling
```

On `main` after the merge: `flutter analyze` reports **No issues found**; `flutter test` reports **25/25 passed**.

**How we worked:** from Task 1 onward, Claude implemented each task, explained it, and asked learning-check questions. You studied the code, answered the questions, and approved every Git action.

---

## A. What we built

### The nine tasks

| # | Task | Main concept | Commit |
|---|---|---|---|
| 1 | `Product` model + 8 real products from DummyJSON | Immutable classes, money as cents | `a54b4fa` |
| 2 | Price formatter + `ProductCard` | Integer math, first unit tests, composition | `f5e8ae6`, `835eeb4` |
| 3 | `HomeScreen` with a product grid | Lazy `GridView.builder`, cell sizes | `5573280` |
| 4 | Category filter chips | First `StatefulWidget`, `setState`, data down / events up | `665b793` |
| 5 | Product details screen | `Navigator.push`, the navigation stack, `InkWell` | `de105e0` |
| 6 | `QuantitySelector` | The full `State` lifecycle, seen in a real log | `c854fcf` |
| 7 | Central app theme | `ThemeData`, color roles, component themes | `d3448c5` |
| 8 | Logo + Poppins font | Assets and fonts in `pubspec.yaml` | `d5d4c80` |
| 9 | Responsive layouts | Breakpoints, `LayoutBuilder`, large text, landscape | `ba15b85`, `cde7b9b` |

### Where the code lives

```
lib/
  main.dart                          starts the app
  app/
    app.dart                         MaterialApp: title, theme, first screen
    theme/app_theme.dart             buildAppTheme(), ratingStarColor
  core/
    utils/price_formatter.dart       formatPrice(1999) -> '$19.99'
  features/products/
    data/
      models/product.dart            the Product model
      mock_products.dart             8 hard-coded products (until Phase 3)
    presentation/
      screens/home_screen.dart       chips + responsive grid
      screens/product_details_screen.dart
      widgets/product_card.dart
      widgets/product_image.dart     network image with loading/error states
      widgets/category_chips.dart
      widgets/quantity_selector.dart
assets/
  images/logo.png
  fonts/Poppins-*.ttf + OFL.txt      font files and their license
```

---

## B. Widgets and layout

### Constraints go down, sizes go up [Essential]

Every layout question in Phase 1 came back to this rule:
1. A parent tells its child **how big it may be** (constraints).
2. The child picks its size **within** those limits.
3. The parent decides **where** the child goes.

Most layout errors come from a child receiving **unbounded** (infinite) constraints and not knowing how big to be.

| Situation in our app | Problem | Solution we used |
|---|---|---|
| `Expanded` image inside a card inside a `Column` | A `Column` gives unbounded height → *"RenderFlex children have non-zero flex but incoming height constraints are unbounded"* | Give the card a bounded size (the grid cell) |
| `GridView` inside the home `Column` | A scrollable is as tall as you allow → *"Vertical viewport was given unbounded height"* | `Expanded(child: GridView...)` |
| Horizontal chip row inside a `Column` | Needs a height | Task 4: fixed `SizedBox(height: 56)`. Task 9: `SingleChildScrollView` + `Row`, which takes its content's height. |
| Square image in the scrolling details `ListView` | `Expanded` can't work in a scrollable (no "remaining space") | `AspectRatio(aspectRatio: 1)`, which computes height from the bounded width |

### The layout widgets we used

| Widget | What it does | Where |
|---|---|---|
| `Column` / `Row` | Stack children vertically / horizontally | Everywhere |
| `crossAxisAlignment: stretch` | Children fill the full width (of a `Column`) | Card, home body |
| `Expanded` | "Take all the remaining space" | Card image, home grid, Quantity label |
| `Spacer` | An empty `Expanded` that pushes things apart | (replaced in Task 9; see below) |
| `SizedBox` | A fixed size, or fixed spacing | Gaps between texts |
| `Padding` | Space around a child | Everywhere |
| `AspectRatio` | Height derived from width (or the largest fitting box) | Details image |
| `Card` + `clipBehavior: Clip.antiAlias` | Rounded surface; children clipped to its corners | `ProductCard` |
| `InkWell` | Tap detection + ripple (built from `GestureDetector`) | `ProductCard` |

### `Spacer` vs. `Expanded(child: Text)` [Essential]

A `Row` lays out **non-flexible** children first, at their natural size. Only the **leftover** space goes to flexible children.

```dart
// Overflowed by 22 pixels at 200% text: Text claims its full width first.
Row(children: [Text('Quantity'), const Spacer(), const QuantitySelector()])

// Works: the selector is measured first; the Text gets what's left and wraps.
Row(children: [Expanded(child: Text('Quantity')), const QuantitySelector()])
```

**Rule:** in a `Row`, wrap the child that's allowed to shrink (usually text) in `Expanded` or `Flexible`.

### Lists and grids: lazy or not? [Essential]

| Tool | Builds | Use for |
|---|---|---|
| `GridView.builder` / `ListView.builder` | Only what's visible + a small buffer | Long or unknown-length lists (products) |
| `GridView.count(children: [...])` | Everything at once | Short, fixed lists |
| `SingleChildScrollView` + `Row` | Everything at once; height = its content | A handful of items (our 5 category chips) |

**Lazy building also explained two test failures:** on the 800 × 600 test screen, widgets far below the visible area were simply **never built**, so `find.text` couldn't find them.

### Responsive layout [Essential]

**The grid**: we compute the column count ourselves:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    // One column per 200 dp of width, but never fewer than 2.
    final columns = max(_minColumns, constraints.maxWidth ~/ _widthPerColumn);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns, ...
```

| Width (dp) | 0 (first frame) | 411 (phone) | 600 | 800 (tablet) | 914 (landscape) |
|---|---|---|---|---|---|
| Columns | 2 | 2 | 3 | 4 | 4 |

**The details screen** switches layout at a **breakpoint**:
```dart
const double _wideLayoutBreakpoint = 600;   // Material: below 600 dp = "compact"
...
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= _wideLayoutBreakpoint) {
      return Row(...);      // image left, details right
    }
    return ListView(...);   // image above, details below
  },
)
```

**`LayoutBuilder` vs. `MediaQuery.sizeOf(context)`:**
- `MediaQuery` answers *"how big is the screen?"*
- `LayoutBuilder` answers *"how much room do **I** get?"*

They differ when a widget gets only part of the screen (for example, tablet split view). For deciding a widget's own layout, `LayoutBuilder` is usually the right question.

### Cell size, checked in DevTools [Useful]

`childAspectRatio: 0.65` means width ÷ height = 0.65. On the emulator (1080 px ÷ 2.625 = 411.43 dp wide):
```
card width  = (411.43 − 24 padding − 12 gap) ÷ 2 = 187.7
card height = 187.7 ÷ 0.65                       = 288.8
```
The **Widget Inspector** showed exactly **187.7 × 288.8**. Your calculation matched reality.

---

## C. State

### Stateless vs. Stateful [Essential]

| | `StatelessWidget` | `StatefulWidget` |
|---|---|---|
| Holds changing data? | No | Yes, in a separate `State` object |
| Our examples | `ProductCard`, `CategoryChips`, `ProductDetailsScreen` | `HomeScreen` (selected category), `QuantitySelector` (quantity) |

**Why two classes?** Widgets are immutable and get recreated on every rebuild. The `State` object is created **once** and **survives** rebuilds, so data stored there isn't lost.

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();   // only create; no logic
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;   // the state: null means "All"
  ...
}
```

### `setState` [Essential]

```dart
onSelected: (category) {
  setState(() {
    _selectedCategory = category;
  });
},
```
`setState` changes the value **and** tells Flutter "this State changed, rebuild it". It doesn't redraw anything itself: it schedules a rebuild, and `build()` reads the new value.

**Without `setState`**, the value changes in memory but the screen doesn't follow, until some other rebuild happens (hot reload, rotation). The UI is then **one step behind**. That's the typical symptom of a forgotten `setState`.

### Store the minimum, derive the rest [Essential]

`_HomeScreenState` stores **only** `_selectedCategory`. The filtered product list is **recomputed in `build()`**:
```dart
final products = _selectedCategory == null
    ? mockProducts
    : mockProducts.where((product) => product.category == _selectedCategory).toList();
```
One stored value = **one source of truth**. Two stored values (category + filtered list) could get out of sync: a "Beauty" chip showing laptops.

### Data down, events up [Essential]

```
             HomeScreen   (owns: _selectedCategory)
    data ↓                               ↑ events
selectedCategory: 'laptops'      onSelected('laptops')
             CategoryChips (displays it, reports taps)
```
- The **parent** owns the state and passes it **down** as constructor arguments.
- The **child** reports user actions **up** by calling a function the parent gave it.
- State lives in the **closest common parent** of everything that needs it ("lifting state up"). The chips *and* the grid need the selection, so `HomeScreen` owns it.

`ProductCard.onTap` follows the same pattern: the card reports a tap, and the **screen** decides to navigate.

### The State lifecycle, from the real emulator log [Essential]

```
── open details ─────────────────────────────────────
[QuantitySelector] State object created
[QuantitySelector] initState (quantity = 1)
[QuantitySelector] didChangeDependencies
[QuantitySelector] build (quantity = 1)
── tap + twice ──────────────────────────────────────
[QuantitySelector] setState (quantity = 2)
[QuantitySelector] build (quantity = 2)
[QuantitySelector] setState (quantity = 3)
[QuantitySelector] build (quantity = 3)
── press back ───────────────────────────────────────
[QuantitySelector] deactivate
[QuantitySelector] dispose
── open the same product again ──────────────────────
[QuantitySelector] State object created
[QuantitySelector] initState (quantity = 1)        ← a new State: back to 1
```

| Method | When | Use it for |
|---|---|---|
| Constructor | `createState()` makes the object | Nothing yet: `widget` and `context` aren't usable |
| `initState` | Once, when attached | One-time setup; reading `widget.…`; creating controllers |
| `didChangeDependencies` | After `initState`, and when an inherited value (e.g. the theme) changes | Setup that needs `context` |
| `build` | After setup and after every `setState` | Describing the UI (must be fast) |
| `didUpdateWidget` | The parent rebuilt with a **new** widget object | Comparing old and new settings |
| `deactivate` | Removed from the tree | Rarely used |
| `dispose` | Gone for good | Cleanup: timers, controllers, subscriptions |

**Rules:** call `super.initState()` **first**; call `super.dispose()` **last**. Never call `setState` after `dispose`. If an async operation can finish after the user has left, check `mounted` first (Phase 3).

### What survives what? [Essential]

| Event | `HomeScreen` state (selected chip) | Details `QuantitySelector` state |
|---|---|---|
| **Push** details over home | ✅ Survives (covered, not destroyed) | — |
| **Pop** (back) | ✅ Visible again, unchanged | ❌ `dispose`: quantity lost |
| **Hot reload** (`r`) | ✅ Kept | ✅ Kept: log shows `reassemble` → `build (quantity = 4)` |
| **Hot restart** (`R`) | ❌ Reset | ❌ Gone, and **navigation resets to the home screen** |

Verified live for `r` and `R`:
```
Performing hot reload...
[QuantitySelector] reassemble (hot reload)
[QuantitySelector] build (quantity = 4)
Performing hot restart...
Restarted application in 698ms.        ← no QuantitySelector lines at all
```
**Why no `didUpdateWidget` after `r`?** The selector is created as `const QuantitySelector()`, so the parent hands over the **identical** widget object, and Flutter skips the update. `reassemble` had already marked it for rebuilding, so only `build` ran.

**Big lesson:** a value lives as long as the thing that owns it. A quantity that must survive leaving the screen has to live **higher up**, in the cart (Phase 6).

---

## D. Navigation

### The navigation stack [Essential]

```
  tap card → push                       back → pop
┌──────────────────────┐
│ ProductDetailsScreen │ ← visible
├──────────────────────┤      ┌──────────────────────┐
│ HomeScreen           │      │ HomeScreen           │ ← visible again
└──────────────────────┘      └──────────────────────┘
```

```dart
itemBuilder: (context, index) {
  final product = products[index];
  return ProductCard(
    product: product,
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ProductDetailsScreen(product: product),
        ),
      );
    },
  );
},
```

| Piece | Meaning |
|---|---|
| `Navigator.of(context)` | Look **up** the tree for the `Navigator` that `MaterialApp` created |
| `MaterialPageRoute<void>` | A route with the platform's page transition; `<void>` = no result returned |
| `ProductDetailsScreen(product: product)` | Passing data to a screen = constructor arguments |
| `final product = …` inside `itemBuilder` | Each `onTap` **closure** remembers its own product |
| `AppBar()` | Adds a back button automatically when the navigator can pop |

**Coming in Phase 2:** go_router with URL-style routes (`/product/78`). Screens will receive an **id** and look the product up themselves. That's why ids must be stable and never confused with list positions.

---

## E. Theme, assets, and fonts

### The theme in one place [Essential]

```dart
const Color _brandSeedColor = Colors.deepPurple;   // change this to re-color the app
const Color ratingStarColor = Colors.amber;        // not a scheme role, so defined here

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _brandSeedColor),
    fontFamily: 'Poppins',
    chipTheme: const ChipThemeData(showCheckmark: false),
  );
}
```

- **Widgets ask for roles, not colors:** `colorScheme.primary` (prices), `secondaryContainer` (selected chip), `onSurfaceVariant` (broken-image icon). Change the seed, and every role regenerates with good contrast.
- **"On" colors** (`onPrimary`, `onSurface`...) are for text and icons drawn **on** that color.
- **Component themes** (`chipTheme`...) set defaults for every widget of that type. Lookup order: **widget parameter → component theme → Material default**, so one chip can still override the theme.
- **Checked by search:** no `Colors.`, `Color(0x`, `TextStyle(`, or `fontSize:` outside `lib/app/theme/`.

### Assets [Essential]

```yaml
flutter:
  assets:
    - assets/images/          # files directly in this folder only, not subfolders
```
```dart
Image.asset('assets/images/logo.png', width: 32, height: 32, semanticLabel: 'ShopLite logo')
```
- Only **declared** files are bundled. An undeclared file fails with *"Unable to load asset"* (we proved it with a probe test).
- The logo is **192 px** for a **32 dp** display, enough for sharp results on 3× screens.

### Fonts [Essential]

```yaml
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf    # weight 400 (default)
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500                                # Material titles and labels
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700                                # our bold prices
```
- `fontFamily: 'Poppins'` in the theme restyles **every** text at once.
- The name is **case-sensitive**. A mismatch silently falls back to the default font: no error, no failing test, only visible on screen.
- Third-party files need a license check. Poppins uses the **SIL Open Font License**, so `OFL.txt` travels with the fonts.
- Changes to `pubspec.yaml` need a **full restart** (`q` then `flutter run`), not hot reload.

---

## F. Dart concepts used in Phase 1

| Concept | Example from our code | Remember |
|---|---|---|
| `final` fields + `const` constructor | `Product` | Immutable data; `const` instances possible |
| `const` vs. `final` list | `const List<Product> mockProducts` | `final` locks the variable; `const` locks the **contents** too. `add` on a const list → runtime `UnsupportedError` (the analyzer doesn't catch it). |
| Const context | No `const` needed before each `Product(` in the list | Everything inside a `const` expression is const |
| Named `required` parameters | `Product(id: 1, title: ...)` | Readable, order-free, checked by the compiler |
| Default parameter values | `this.fit = BoxFit.cover`, `this.initialQuantity = 1` | Optional with a sensible default |
| Nullable types | `String? _selectedCategory`, `void Function()? onTap` | `null` can carry meaning ("All", "not tappable") |
| `late` | `late int _quantity;` set in `initState` | A promise to assign before reading; broken promise = runtime error |
| Top-level functions / variables | `formatPrice`, `mockProducts`, `buildAppTheme` | Simpler than classes with only static members |
| `_` private names | `_HomeScreenState`, `_ProductInfo`, `_log` | Visible only in this file |
| Integer math | `cents ~/ 100`, `cents % 100` | `~/` = divide and drop the remainder; `/` gives a `double` |
| Money conversion | `(19.99 * 100).round()` → 1999 | `.toInt()` gives **1998**: always `.round()` |
| String interpolation | `'\$$dollars.${remainingCents.toString().padLeft(2, '0')}'` | `\$` = literal dollar; `$name`; `${expression}` |
| Adjacent strings | `'first part ' 'second part'` | Joined at compile time; watch the spaces |
| `assert` | `assert(cents >= 0, ...)` | Debug and test only; stripped from release |
| Collection methods | `.map(...).toSet().toList()`, `.where(...)` | Derive data instead of hard-coding it |
| Collection `for` | `for (final category in categories) _buildChip(category)` | A loop inside a list literal |
| Ternary | `index == 0 ? null : categories[index - 1]` | `condition ? a : b` |
| Closures | Each `onTap` remembers its `product` | A function that captures variables from where it was created |
| Tear-offs | `onPressed: _decrement` | Pass the function; `_decrement()` would call it (`use_of_void_result` error) |
| `dart:math` | `max(_minColumns, ...)` | SDK library; `dart:` imports come first |

---

## G. Important decisions

| Decision | Why | Revisit when |
|---|---|---|
| Prices as `int priceCents` | Exact arithmetic and comparisons; the API format stays at the boundary | Phase 3 (`fromJson` with `.round()`) |
| Real DummyJSON data and ids in the mock list | Ids stay consistent with the API we'll use | Phase 3 (list replaced by API data) |
| Mock data in `data/`, not in a screen | Data source vs. presentation separation | Phases 3–4 |
| `formatPrice` in `core/utils` | Every feature (cart, checkout, orders) displays money | Phase 6 (`intl` for thousands separators) |
| Extract only at the second real use | `ProductImage`, `_ProductInfo`; no premature abstractions | Ongoing |
| Star + rating row kept in two places | Styled differently; not yet the same component | If a third use appears |
| Theme in `lib/app/theme/` with design tokens | One place to change the look | Phase 2 (spacing tokens, shared buttons, optional dark mode) |
| Chips without checkmark (theme-wide) | Selecting a chip no longer shifts its neighbors | — |
| Bundled font files instead of `google_fonts` | Offline, no extra dependency, identical from the first frame | — |
| Grid: `LayoutBuilder` + fixed count, min 2 columns | Valid at **any** width, including Android's zero-width first frame | — |
| Lifecycle logs kept (`kDebugMode`-guarded) | Learning tool; silent in release builds | Phase 10 (logging) |

---

## H. Testing

### The 25 tests

| File | Tests | What they protect |
|---|---|---|
| `core/utils/price_formatter_test.dart` | 7 | Price formatting: typical, padding (`$0.05`), `$10.00`, zero, large, negative rejected |
| `features/products/presentation/screens/home_screen_test.dart` | 4 | Chips shown, filtering, "All" resets, tap → details → back |
| `features/products/presentation/screens/product_details_screen_test.dart` | 1 | Title, price, rating, description shown |
| `features/products/presentation/widgets/quantity_selector_test.dart` | 3 | + / −, minimum 1, maximum |
| `features/products/presentation/responsive_layout_test.dart` | 9 | 2 vs. 4 columns, 200% text, chips fit and align, landscape, **zero-size first frame**, wide details layout |
| `widget_test.dart` | 1 | App starts on the home screen with logo and grid |

### Kinds of tests [Essential]

| Kind | Tests what | Our example |
|---|---|---|
| **Unit test** | A function or class, no UI | `formatPrice` |
| **Widget test** | A widget or screen, without a device | Chips filtering, navigation, layouts |
| **Regression test** | A bug that happened once, so it can't come back unnoticed | Chip clipping, chip alignment, zero-size frame |

### Tools you learned

| Tool | Use |
|---|---|
| `group`, `test`, `testWidgets`, `expect` | Structure and checks |
| `find.text`, `find.byType`, `find.byTooltip`, `find.image(AssetImage(...))` | Finding widgets |
| `findsOneWidget`, `findsWidgets`, `findsNothing` | Exactly one / one or more / none |
| `throwsA(isA<AssertionError>())` with `() =>` | Expecting an error (the closure delays the call) |
| `tester.tap(...)` | Simulate a tap (must hit an **on-screen** point) |
| `pump()` vs. `pumpAndSettle()` | One frame (after plain `setState`) vs. until all animations finish (navigation) |
| `tester.pageBack()` | Tap the app bar's back button |
| `tester.view.physicalSize` + `addTearDown(tester.view.reset)` | Phone, landscape, tablet, or zero-size screens |
| `textScaleFactorTestValue = 2.0` | The user's largest text size |
| `tester.takeException()` | Catches errors such as overflow during layout |
| `getTopLeft`, `getBottomLeft`, `greaterThan`, `lessThanOrEqualTo` | Measuring layout directly |

### Testing lessons [Essential]

1. **In widget tests, time doesn't pass on its own.** A frame only happens when you call `pump`.
2. **Test behavior, not screen-size details:** `findsWidgets` instead of `findsNWidgets(8)` on a lazy grid.
3. **The default test screen is 800 × 600.** Off-screen widgets may not be built, and off-screen taps hit nothing (Flutter warns: *"would not hit test"*).
4. **Tests use a block-shaped test font.** They check layout logic, not how real Poppins looks.
5. **Some bugs don't throw** (a clipped chip label, a centered row). Tests that only listen for exceptions miss them, so **measure** the layout.
6. **Test-first for bugs:** write a test that **fails** (red), fix the code, see it **pass** (green). The red run proves the test can detect the bug.
7. **One test, one behavior:** navigation tests check navigation; content tests check content.

---

## I. Debugging stories and lessons

| What happened | Cause | Lesson |
|---|---|---|
| `info: avoid_print` in `main.dart` | A `print(0.1 + 0.2)` experiment left in the code | Use `debugPrint`; clean up experiments (`git restore`) |
| `0.1 + 0.2` printed `0.30000000000000004` | Binary floating point | Money in integer cents |
| `19.99 * 100` → `.toInt()` gave `1998` | Floating-point error + truncation | Always `.round()` |
| `no_logic_in_create_state` | A log line inside `createState()` | Lints often encode **design rules**: read *why* |
| *"The name 'AssetImage' isn't a class"* | Missing `package:flutter/material.dart` import in a test | "Undefined" or "isn't a class" for a known Flutter name → check imports |
| Test: `Found 0 widgets` on the details screen | 800-wide test screen → 800-tall image → text never built | Test on realistic sizes |
| Tap warning *"would not hit test"* at `y = 631` | The target was below the 600-tall test screen | Tap something on screen (the card) |
| `RenderFlex overflowed by 22 pixels` at 200% text | `Text` + `Spacer` in a `Row` | `Expanded(child: Text)` |
| Chip labels clipped at 200% text, **tests green** | Fixed-height row; chips clip silently | Device check → regression test that measures |
| Chip row centered in landscape | Scroll view narrower than the `Column`, which centers by default | `crossAxisAlignment: stretch` |
| `'crossAxisExtent > 0.0': is not true` at startup | Android's first frame has **width 0**; the old delegate asserts width > 0 | Code must handle any width; **read the console, not just the screen** |
| Commands "stuck" for minutes | Another `flutter run` held Flutter's startup lock | One Flutter command at a time; press `q` when done |

**Biggest lesson:** the zero-width bug looked perfect on every screenshot. It was only visible in the **console**. Watch the Debug Console, especially right after startup.

---

## J. Git in Phase 1

- **One branch for the phase** (`phase-1-product-ui`), **one or two small commits per task**, pushed after each task.
- **Stage specific files** (`git add <paths>`) and check `git diff --staged --stat` before every commit.
- **Untracked files don't belong to any branch.** That's why this review file could be written before the Phase 2 branch existed.
- **`fix:` vs. `feat:`**: the zero-width bug fix is its own `fix:` commit, so the history shows what was a feature and what was a correction.
- **Code + its tests in the same commit**, so every commit builds and passes.
- **Merge with `--no-ff`**, verify on `main` (`analyze` + `test`), push, then an **annotated tag** `phase-1`.

---

## K. Phase 1 completion checklist

| Criterion | Status | Evidence |
|---|---|---|
| No overflow at common sizes or with the largest system font | ✅ | Responsive tests (phone, landscape, tablet, 200%) + emulator checks at 200% and in landscape |
| `ProductCard` is one reusable widget, no duplicated layout code | ✅ | One card; image logic shared via `ProductImage`. The rating row duplication is a documented decision. |
| You can explain the lifecycle log line by line | ✅ | Task 6 learning check + the live `r`/`R` run during the review |
| No hard-coded colors or text styles outside the theme | ✅ | Search found none outside `lib/app/theme/` |
| All nine tasks implemented and committed | ✅ | Section A |
| DevTools Widget Inspector (open item from Phase 0) | ✅ | Card size 187.7 × 288.8; widget path traced |
| Phase 1 knowledge check | ✅ | 5 correct, 1 corrected (hot restart resets navigation) |
| Merged into `main` and tagged | ✅ | `0937650`, tag `phase-1`, on GitHub |
| `RatingStars` built from scratch (roadmap exercise) | ⏳ **Optional, not done** | A 🧑‍💻 exercise from before the workflow change |

---

## L. Carried forward

| Item | Where it goes |
|---|---|
| `Navigator.push` with a whole `Product` | **Phase 2:** go_router with `/product/:id` |
| `HomeScreen` reads `mockProducts` directly | **Phases 3–4:** repository + Cubit |
| `CategoryChips` builds all chips at once | Fine for ~24 API categories (Phase 5); revisit only if the list grows a lot |
| Prices shown as `$1999.99` (no thousands separator) | **Phase 6:** `intl` currency formatting |
| The quantity is lost when leaving the details screen | **Phase 6:** the cart keeps it, above all screens |
| `QuantitySelector` lifecycle logs | **Phase 10:** remove or replace with real logging |
| The placeholder logo generated by a script | Replace with a real design anytime (keep the same path) |
| Tablet-width product images are low resolution (`thumbnail`) | **Phase 5:** product image gallery |

---

## M. Knowledge check

Answer each one **before** opening the Answer Key. Write your answers down or say them out loud.

1. Why do we store prices as `int priceCents`? When converting `19.99` from the API, why must we use `.round()` and not `.toInt()`?
2. What is the difference between `final List<Product> products = [...]` and `const List<Product> products = [...]`? What happens if you call `.add(...)` on each?
3. Why does `ProductCard` receive an `onTap` callback instead of calling `Navigator.push` itself?
4. `_HomeScreenState` stores `_selectedCategory` but not the filtered product list. Why?
5. On the details screen, the quantity is 4. What does the screen show after `r` (hot reload)? And after `R` (hot restart)?
6. Why is `widget.initialQuantity` read in `initState` and not in a field declaration like `int _quantity = widget.initialQuantity;`?
7. Why did `Text('Quantity')` + `Spacer()` + `QuantitySelector()` overflow at 200% text, while `Expanded(child: Text('Quantity'))` + `QuantitySelector()` didn't?
8. In a widget test, when should you use `pump()` and when `pumpAndSettle()`?
9. All tests passed, but on the emulator the chip labels were clipped at 200% text. How can both be true, and what did we do about it?
10. Why did the grid throw `'crossAxisExtent > 0.0': is not true` on Android at startup, why did no screenshot show a problem, and why does `max(2, width ~/ 200)` with a fixed-count delegate fix it?

---

## N. Readiness for Phase 2

### Phase 1 concepts you'll use right away

| Phase 1 concept | How it appears in Phase 2 |
|---|---|
| The navigation stack, push/pop | go_router manages the same stack with URL-style routes |
| Passing a `Product` to a screen | Replaced by passing an **id** in the route (`/product/78`) |
| `BuildContext` lookups (`Navigator.of`, `Theme.of`) | `context.go(...)` / `context.push(...)` find the router the same way |
| "Push keeps the screen below alive" | Each bottom-navigation tab keeps its own stack and scroll position |
| `ProductImage` loading/error states | Grow into shared `LoadingView`, `EmptyView`, `ErrorView` |
| Theme and design tokens | Grow into a mini design system (spacing, `AppButton`) |
| `tooltip` / `semanticLabel` | Accessibility basics for every icon button |
| Widget tests with `pumpAndSettle` | Navigation tests between tabs and routes |

### Self-assessment checklist

Be honest. Every "no" is a section to re-read before Phase 2.

- [ ] I can explain "constraints go down, sizes go up" with one example from our app.
- [ ] I know when to use `Expanded`, `AspectRatio`, or a fixed `SizedBox`.
- [ ] I can explain why `GridView.builder` is lazy and when that matters.
- [ ] I can explain the two classes of a `StatefulWidget` and what `setState` does.
- [ ] I can list the lifecycle methods in order and say what `initState` and `dispose` are for.
- [ ] I can explain "data down, events up" using `CategoryChips`.
- [ ] I can explain what survives push, pop, hot reload, and hot restart.
- [ ] I know why widgets use `colorScheme.primary` instead of a color constant.
- [ ] I can add an image asset and a font weight to `pubspec.yaml`, and I know a full restart is needed.
- [ ] I know `pump()` vs. `pumpAndSettle()`, and why the test screen size matters.
- [ ] I check the **console**, not only the screen, after starting the app.

---

## Answer Key

<details>
<summary><strong>Click to show answers</strong> (try the questions first!)</summary>

**1. Prices as cents, and `.round()`**
A `double` can't represent most decimal amounts exactly (`0.1 + 0.2` = `0.30000000000000004`), so totals and comparisons go wrong. Integer cents are exact. `19.99 * 100` is `1998.9999999999998` in floating point: `.toInt()` truncates it to `1998` (a lost cent), while `.round()` gives `1999`. The conversion belongs in `fromJson`, at the boundary, so the rest of the app never sees the API's format.

**2. `final` vs. `const` list**
`final` only locks the **variable**: you can't assign a new list, but `.add(...)` works. `const` locks the variable **and** the contents, and the list is created at compile time: `.add(...)` throws `UnsupportedError: Cannot add to an unmodifiable list` **at runtime** (the analyzer doesn't catch it).

**3. `onTap` callback**
Data down, events up: the card only **reports** the tap, and the screen **decides** what happens. The card stays reusable (a wishlist could react differently), and switching to go_router in Phase 2 changes `HomeScreen`, not `ProductCard`.

**4. Only `_selectedCategory` is stored**
One source of truth. The filtered list is **derived** in `build()`. Storing both means two values must always be updated together; forgetting one would show the wrong products under a chip.

**5. `r` vs. `R` with quantity 4**
After `r`: still **4**. The `State` survives; the log shows `reassemble` → `build (quantity = 4)`; `initState` doesn't run (and no `didUpdateWidget`, because the selector is `const`). After `R`: all Dart state is thrown away and `main()` runs again, so the app is back on the **home screen**. The details screen and its quantity are gone, without any `dispose` log.

**6. Why `initState`**
Field initializers run in the constructor, **before** the `State` is attached to its widget, so `widget` isn't accessible there (Dart reports an error). `initState` is the first moment `widget` is available. `late` promises the field will be set before it's read.

**7. `Spacer` vs. `Expanded(child: Text)`**
A `Row` lays out non-flexible children first at their natural width: the 200% `Text` plus the selector were wider than the row, so it overflowed by 22 px, and the `Spacer` got no space. With `Expanded`, the `Text` is the flexible child: the selector is measured first, and the text gets exactly what's left and wraps.

**8. `pump()` vs. `pumpAndSettle()`**
`pump()` runs **one** frame: enough after a plain `setState` (chip tap, + button). `pumpAndSettle()` keeps running frames until nothing is animating: needed for navigation, because page transitions take many frames. After a push with only one `pump()`, the new screen is still offstage and finders ignore it.

**9. Green tests, clipped chips**
Chips **clip** their label instead of throwing, and our tests only checked for exceptions. We confirmed it on the emulator, then wrote a regression test that **measures** the label's bottom edge against the chip's bottom edge (red: `111 > 104`), fixed the row (`SingleChildScrollView` + `Row`, which takes its content's height), and saw it pass.

**10. The zero-width first frame**
Android lays out the very first frame while the window still reports width 0 (`FlutterRenderer: Width is zero`). `SliverGridDelegateWithMaxCrossAxisExtent` asserts that the width is above 0, so it threw once. A moment later the real size arrived, so every **screenshot** looked fine; the error was only in the **console**. With `max(2, width ~/ 200)`, the column count is always at least 2, and the fixed-count delegate has no width assertion. The invalid state can't be reached at any width. The regression test `survives a zero-size first frame` failed on the old code and passes on the new.

</details>
