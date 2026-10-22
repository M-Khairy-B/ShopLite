# Phase 0 Review: Setup, Tooling & Git

> **How to use this file**
> Read one section at a time. For each concept, try to explain it **out loud in your own words** before reading the explanation. If you can explain it and predict what happens when something changes, you understand it. If you can only repeat the command, you've memorized it.
>
> Labels used below:
> - **[Essential]**: you need this in every future phase.
> - **[Useful]**: good to know; depth can come later.

**State of the project at the end of Phase 0** (verified from the Git history):

```
*   bf14672 (HEAD -> main, tag: phase-0, origin/main) Merge phase-0-setup: project setup and tooling
|\
| * 6ab3a4c (origin/phase-0-setup, phase-0-setup) refactor: remove redundant useMaterial3 flag
| * 0a4709f chore: replace counter template with ShopLite app shell
| * 8144058 chore: enable stricter lint rules
|/
* 2617f44 chore: initial Flutter project setup with learning roadmap
```

---

## A. Flutter and Dart basics

### What Flutter and Dart do [Essential]

- **Dart** is the programming language. You write all app logic and UI in Dart.
- **Flutter** is the framework (a big toolbox written in Dart) that draws the UI on the screen, handles touches, and runs the same code on Android, iOS, web, and desktop.

Plain version: *Dart is the language you write in; Flutter is the toolbox that turns your Dart code into an app on screen.*

### What a widget is [Essential]

A **widget** is a description of a piece of UI: "a text that says X", "a bar at the top", "center this".

- Everything you see is built from widgets, and widgets are put **inside** other widgets. This nesting is called the **widget tree**.
- Widgets are **immutable** (they can't change after creation). When the UI needs to change, Flutter builds **new** widgets. That's cheap, because widgets are only lightweight descriptions, not the actual pixels.

### `StatelessWidget` and when to use it [Essential]

A `StatelessWidget` is a widget that **holds no changing data of its own**. Its output depends only on what it receives from outside.

Use it when the widget shows the same thing until its parent gives it something different. Our root widget is stateless:

```dart
class ShopLiteApp extends StatelessWidget {
  const ShopLiteApp({super.key});
  ...
}
```

`ShopLiteApp` never changes by itself, so stateless is the right choice. (In Phase 1 you'll meet `StatefulWidget`, for widgets that *do* hold changing data, like a quantity counter.)

### The `build()` method and `BuildContext` [Essential]

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(...);
}
```

- **`build()`** answers one question: *"What should this widget look like right now?"* It returns more widgets. Flutter calls it whenever it needs to (first display, after changes, after hot reload), so **`build()` must be fast and have no side effects** (no network calls, no file saving).
- **`BuildContext`** is the widget's **address in the widget tree**. Flutter uses it to look **upward** in the tree for things like the theme (`Theme.of(context)`, used a lot in Phase 1).

### `MaterialApp`, `ThemeData`, `ColorScheme.fromSeed`, `Scaffold` [Essential]

| Widget/class | Plain meaning | In our app |
|---|---|---|
| `MaterialApp` | The root of a Material Design app. It sets up the theme, navigation, text direction, and more. | Returned by `ShopLiteApp.build()` |
| `ThemeData` | The app's visual settings: colors, text styles, shapes | `theme: ThemeData(...)` |
| `ColorScheme.fromSeed` | Generates a **whole palette** (primary, secondary, surface, error...) from **one** color | `seedColor: Colors.deepPurple` |
| `Scaffold` | The basic layout of one screen: slots for an app bar, a body, and later a bottom bar and buttons | Our `home:` screen |

Material 3 is Flutter's default design system (since Flutter 3.16), which is why we removed `useMaterial3: true`: it did nothing.

### `AppBar`, `Center`, `Text` [Essential]

- `AppBar`: the bar at the top of the screen, usually with a title.
- `Center`: places its single child in the middle of the available space.
- `Text`: displays a string.

```dart
appBar: AppBar(title: const Text('ShopLite')),
body: const Center(child: Text('Welcome to ShopLite')),
```

### What `const` means and why it's useful [Essential]

`const` means *"this value is fully known when the code is compiled and will never change."*

- Flutter creates a `const` widget **once** and reuses it. On rebuilds it can **skip** it, because it knows it can't have changed. That means less work and a smoother app.
- A widget can be `const` only if **everything inside it is also const**.

Real example from our code: `Text` and `Center` are `const`, but the `Scaffold` is not. `Scaffold` *has* a const constructor, but its `AppBar` doesn't (`AppBar`'s constructor isn't `const` in Flutter). Because one child can't be const, the whole `Scaffold` can't be either. The analyzer knew this, which is why it didn't ask us to add `const` there.

`const ShopLiteApp({super.key});` is a **const constructor**. It's what allows `runApp(const ShopLiteApp())` in `main.dart`.

### `main()` and `runApp()` [Essential]

- **`main()`** is where **every** Dart program starts. When the app launches, Dart calls `main()` first.
- **`runApp(widget)`** tells Flutter: *"this widget is the root of the app; build it and show it on screen."*

### Hot reload vs. hot restart [Essential]

| | What it does | Keeps current `State`? | Key |
|---|---|---|---|
| **Hot reload** | Loads your changed code into the running app and calls `build()` again | ✅ Yes | `r` |
| **Hot restart** | Runs `main()` again and rebuilds the whole app from nothing | ❌ No, everything resets | `R` |
| **Full restart** | Stops the app and builds it again (`q`, then `flutter run`) | ❌ No | — |

**Our experiment (confirmed):** we tapped `+` until the counter showed 5, changed `int _counter = 0;` to `int _counter = 100;`, and hot reloaded. The counter **stayed at 5**. After hot restart, it showed **100**.

**Why:** `int _counter = 0;` is a **field initializer**. It runs **only once**, when the `State` object is created. Hot reload reuses the existing `State` object, so that line never runs again. Hot restart creates new `State` objects, so the line runs.

**When hot reload is not enough:**
- You changed code that runs only once: field initializers, `initState`, `main()`, global or static variables → **hot restart**.
- You added a package in `pubspec.yaml` or changed native Android or iOS files → **full restart**.

---

## B. Understanding our ShopLite app

### `lib/main.dart`: the starting point [Essential]

```dart
import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/app.dart';

void main() {
  runApp(const ShopLiteApp());
}
```

Its only job is to **start the app**. Later phases will add startup work here before `runApp`: loading the environment config (Phase 3), registering services (Phase 4), and restoring the saved cart and login (Phases 6–7).

### `lib/app/app.dart`: what the app *is* [Essential]

```dart
class ShopLiteApp extends StatelessWidget {
  const ShopLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopLite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('ShopLite')),
        body: const Center(child: Text('Welcome to ShopLite')),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

It describes the app: its title, theme, and first screen. The `home:` screen is **temporary**; in Phase 1 it becomes the real `HomeScreen`.

**Why two files?** This is **separation of concerns**: each file has one job. `main.dart` = *start up*; `app.dart` = *describe the app*.

### How `main()` starts `ShopLiteApp`

```
Dart launches the app
   → calls main()
      → runApp(const ShopLiteApp())
         → Flutter calls ShopLiteApp.build(context)
            → returns MaterialApp → which shows home: Scaffold
```

### Widget hierarchy of the current app

```
ShopLiteApp
└── MaterialApp
    └── Scaffold                         (home)
        ├── AppBar                       (appBar)
        │   └── Text('ShopLite')
        └── Center                       (body)
            └── Text('Welcome to ShopLite')
```

[Useful] `MaterialApp` also adds many hidden widgets between itself and the `Scaffold` (theme, navigator, and others). You'll see them later in the DevTools Widget Inspector.

### Why `debugShowCheckedModeBanner: false`

In debug mode Flutter shows a red **DEBUG** ribbon in the top-right corner. This setting hides it so the app looks clean while we develop. It only affects debug builds; release builds never show the ribbon.

### `analysis_options.yaml`, lint rules, `flutter analyze` [Essential]

- The **analyzer** reads your code **without running it** and reports errors, warnings, and style problems. These are the squiggly underlines in VS Code.
- A **lint** is one rule it checks.
- `analysis_options.yaml` decides **which rules are active**. We use the standard `flutter_lints` set plus six extra rules we added:

| Rule | What it enforces |
|---|---|
| `prefer_single_quotes` | `'text'`, not `"text"` |
| `prefer_const_constructors` | Use `const` when a widget can be const |
| `prefer_const_declarations` | Use `const` for values known at compile time |
| `prefer_final_locals` | Local variables that never change should be `final` |
| `always_declare_return_types` | Functions must state what they return |
| `unawaited_futures` | Warns when you forget `await` (important in Phase 3) |

- `flutter analyze` runs the analyzer on the whole project from the terminal. **Our rule: never commit when it reports issues.**

### `flutter test` and our widget test [Essential]

```dart
void main() {
  testWidgets('App shell shows welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopLiteApp());

    expect(find.text('Welcome to ShopLite'), findsOneWidget);
  });
}
```

Line by line:
- `testWidgets(...)`: defines one widget test with a readable name.
- `tester.pumpWidget(const ShopLiteApp())`: builds our app **in a test environment** (no emulator or real screen needed) and renders one frame.
- `find.text('Welcome to ShopLite')`: a **finder** that searches the built widget tree for `Text` widgets showing that exact string.
- `findsOneWidget`: a **matcher** meaning *exactly one* match. **Zero** matches fail the test (the text is missing), and so do **two or more** (it's duplicated).

`flutter test` runs every test in the `test/` folder.

---

## C. Git and GitHub

### Core vocabulary [Essential]

| Term | Plain meaning | In our project |
|---|---|---|
| **Repository (repo)** | A project folder whose history Git records (stored in the hidden `.git` folder) | `e_commerce_learn` |
| **Working tree** | The actual files you see and edit on disk | Your `lib/`, `test/`, ... |
| **Commit** | A permanent snapshot of staged changes, with an ID, author, date, and message | `0a4709f chore: replace counter template...` |
| **Branch** | A named, movable line of work. New commits move it forward | `main`, `phase-0-setup` |
| **Remote** | A saved link to a copy of the repo hosted elsewhere | `origin` → `github.com/M-Khairy-B/ShopLite` |
| **Tag** | A permanent label on one commit; it never moves | `phase-0` → `bf14672` |

### The three places your changes live [Essential]

```
Working tree  ──git add──▶  Staging area  ──git commit──▶  History (commits)
(files on disk)             (the next commit)               (permanent)
                                                                │
                                                       git push ▼
                                                         GitHub (origin)
```

### File states [Essential]

| State | Meaning | How it shows in `git status` |
|---|---|---|
| **Untracked** | New file Git has never recorded | `??`, under "Untracked files" |
| **Tracked** | Git has it in history | (not listed if unchanged) |
| **Modified** | Tracked, but changed since the last commit, and not staged yet | "Changes not staged for commit" |
| **Staged** | Marked to go into the next commit | "Changes to be committed" |
| **Ignored** | Matches a `.gitignore` rule, so Git pretends it doesn't exist | Not listed at all |

### Inspection commands (safe; they change nothing)

- `git status`: *"Where am I and what has changed?"* Shows the branch, staged, modified, and untracked files. **Run it before every commit.**
- `git diff`: shows **unstaged** changes in **tracked** files (`-` red = removed, `+` green = added).
- `git diff --staged`: shows **exactly what the next commit will contain**.
- `git log --oneline` (optionally with `--graph`, `--all`): shows the commit history.
- `git show HEAD`: shows what one commit changed. **`HEAD` = the commit you're currently on.**

### Change commands

- `git init -b main`: turns a folder into a repository; the first branch is named `main`.
- `git add <path>`: copies changes into the staging area. We prefer **specific paths** (`git add lib test`) over `git add .`.
- `git commit -m "message"`: saves the staged changes as a commit.
- `git push`: uploads your commits to GitHub. `-u` the first time links the local branch to its GitHub copy.
- `git restore <file>`: throws away uncommitted changes to a file. ⚠️ **They can't be recovered.**

### Branching, merging, and tags

- `git switch -c phase-0-setup`: **creates** a branch and **moves onto** it.
- `git switch main`: moves to an existing branch. Your files change to match that branch.
- `git merge --no-ff phase-0-setup -m "..."`: run **while on `main`**. Brings the phase's commits into `main`.
  - Without `--no-ff`, Git would have done a **fast-forward** (just moved the `main` label, giving a straight line with no sign of the phase).
  - With `--no-ff`, Git created a **merge commit** (`bf14672`), so Phase 0 shows as a clearly labeled group in the history.
- `git tag -a phase-0 -m "..."`: an **annotated** tag stores who created it, when, and a message. A plain tag would only be a name.
- `git push origin phase-0`: **tags are not sent by a normal `git push`**; you push them by name.

### Why `.gitignore` doesn't untrack an already-committed file [Essential]

`.gitignore` only affects **untracked** files. It tells Git *"don't start tracking these"*. If a file is **already tracked**, Git keeps tracking it no matter what `.gitignore` says.

To stop tracking it: `git rm --cached <file>` (keeps the file on disk), then commit.
⚠️ The file still exists **in old commits**. If it contained a **secret** (password, API key), the secret has leaked and must be **changed (rotated)**, not just deleted.

That's why we added rules for `.env`, `.env.*`, and `env/*.local.json` **before** any such file exists.

### Why we review changes before committing

A commit is permanent history. Reviewing with `git status` → `git diff` → `git diff --staged` catches:
- leftover experiments and debug code
- unsaved edits that didn't make it in (our `useMaterial3` line)
- files that should never be committed (our accidental `hell"` file)

### Why code and its test were committed together

**Every commit should leave the project working.** When we replaced the counter app, the old test (which tapped the counter) would fail. So the new code and the updated test went into **the same commit** (`0a4709f`). If you check out *any* commit later, the app builds and its tests pass.

### Why we don't rewrite pushed history or force-push

`git commit --amend` *rewrites* the last commit. Once a commit is **pushed**, rewriting it means `git push --force`, which **replaces GitHub's history with yours**. If anything existed on GitHub that you don't have locally, it's gone. That's how people lose work.

What we did instead: when `useMaterial3` was still in the pushed commit, we added a **new fix-up commit** (`6ab3a4c refactor: remove redundant useMaterial3 flag`). That's safe and normal.

### Our commit message convention [Essential]

`type: short description in imperative mood`

| Prefix | Use for |
|---|---|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `refactor:` | Code change without behavior change |
| `test:` | Tests |
| `docs:` | Documentation only |
| `chore:` | Setup, config, dependencies |

---

## D. Project setup and tooling

### `pubspec.yaml` [Essential]

The project's **settings file**: app name, version, Dart SDK version, **dependencies** (packages the app uses), dev dependencies (packages only for development, like `flutter_lints`), and assets and fonts. `pubspec.lock` records the **exact** package versions in use. For apps it's committed, so every machine uses the same versions.

### `uses-material-design: true`

It bundles the **Material Icons font** with the app. Without it, every `Icon(Icons.something)` shows as an empty box. (The old counter app's `+` button used `Icons.add`.) It matters from Phase 1, where we use icons such as favorite, cart, and star.

### `flutter doctor`

Checks your development setup. Our result:

| Check | Result |
|---|---|
| Flutter (stable 3.47.5) | ✓ |
| Android toolchain (SDK 36.1.0) | ✓ |
| Chrome | ✓ |
| **Visual Studio** | **✗** |
| Connected device | ✓ |
| Network resources | ✓ |

**The Visual Studio warning:** Visual Studio (with C++ tools) is needed **only to build Windows desktop apps**. Android apps are built with the Android SDK and Gradle, so this ✗ doesn't block us. Ignore it unless we ever target Windows desktop.

### `flutter analyze` and `flutter test`

- `flutter analyze`: checks the code **without running it** (errors, warnings, lint rules).
- `flutter test`: **runs** the tests in `test/` in a test environment, with no emulator needed.

They check different things: analyze = *"is the code well written?"*, test = *"does it behave correctly?"*. Run both before finishing a task.

### The emulator and `flutter run -d emulator-5554`

- The **Android emulator** is a virtual Android phone running on your PC. Ours is `sdk gphone16k x86 64`, Android 17 (API 37).
- `flutter devices` lists available devices with their IDs.
- `flutter run -d emulator-5554` builds the app and runs it on the device with ID `emulator-5554`. While it runs, the terminal accepts `r` (hot reload), `R` (hot restart), and `q` (quit).

---

## E. Important commands

### Flutter

| Command | What it does | When I'd use it |
|---|---|---|
| `flutter doctor` | Checks the development setup | New machine, or when builds fail mysteriously |
| `flutter devices` | Lists devices and their IDs | To find the ID for `-d` |
| `flutter run -d emulator-5554` | Builds and runs the app on a device | Every development session |
| `r` / `R` / `q` (while running) | Hot reload / hot restart / quit | After code changes |
| `flutter analyze` | Static code check | Before every commit |
| `flutter test` | Runs all tests | Before every commit and before merging |

### Git: inspection (safe)

| Command | What it does | When I'd use it |
|---|---|---|
| `git status` | Branch + state of all changes | Constantly, especially before `add` and `commit` |
| `git diff` | Unstaged changes in tracked files | Reviewing your edits |
| `git diff --staged` | What the next commit contains | Right before `git commit` |
| `git log --oneline --graph --all` | History as a graph | Checking branches, merges, tags |
| `git show HEAD` | What the current commit changed | Checking a commit after making it |
| `git log --oneline main..phase-0-setup` | Commits on the branch but not on `main` | Reviewing a phase before merging |
| `git diff --stat main..phase-0-setup` | Files changed across the whole phase | Overview before merging |
| `git remote -v` | Lists remotes and their URLs | Checking the GitHub connection |
| `git branch` | Lists branches; `*` = current | Before switching or merging |

### Git: making changes

| Command | What it does | When I'd use it |
|---|---|---|
| `git init -b main` | Creates a repository with branch `main` | Once per project |
| `git add <path>` | Stages changes | Choosing what goes into the next commit |
| `git commit -m "type: message"` | Saves staged changes as a commit | After each small, finished task |
| `git restore <file>` | ⚠️ Discards uncommitted changes to a file | Undoing an experiment |
| `git remote add origin <url>` | Links to a GitHub repo | Once per project |
| `git push -u origin <branch>` | First push of a branch, linking it | First push of each new branch |
| `git push` | Uploads new commits | After committing on a linked branch |
| `git pull` | Downloads and merges new commits from GitHub | Before merging into `main` |

### Git: branching and tagging

| Command | What it does | When I'd use it |
|---|---|---|
| `git switch -c <name>` | Creates a branch and switches to it | Start of each phase |
| `git switch <name>` | Switches to an existing branch | Moving between `main` and phase branches |
| `git merge --no-ff <branch> -m "..."` | Merges a branch with a merge commit | End of each phase (while on `main`) |
| `git tag -a phase-N -m "..."` | Creates an annotated milestone tag | After merging a phase |
| `git push origin phase-N` | Pushes a tag | Right after creating it |

---

## F. Common mistakes and lessons learned

### 1. Typing commands while Git's pager is open (this happened to us)

Long output from `git diff` or `git log` opens a **pager** (a program called `less`). You're inside it when the bottom of the terminal shows `:` or `(END)`.

While the pager was open, the commit command was typed. The pager read the letters as **its own keyboard commands**: `h` opened its help screen, and in the word `shell"`, the `s` meant *"save to a file"*, followed by the filename `hell"`. Result: a junk file named `hell"` containing the pager's help text.

**Fix:** press **`q`** to exit the pager **before** typing the next command.

### 2. Review and remove accidental files before committing

The junk file appeared as **untracked** (`??`) in `git status`. Because we staged **specific paths** (`git add lib test`) instead of `git add .`, it **was not committed**. We looked inside it to confirm it was harmless, then deleted it.
**Lessons:** read `git status` before every commit, and stage specific paths.

### 3. `git diff` doesn't show untracked files

`git diff` compares your files with what Git already has. A brand-new file has no earlier version to compare against, so `git diff` shows nothing for it. That's why the new `lib/app/app.dart` didn't appear in `git diff`. It appears in `git status` (as `??`) and, **after `git add`**, in `git diff --staged`.

### 4. Why `git diff --staged` matters

It's the **only** view of exactly what the commit will contain, including new files. We committed `0a4709f` with `useMaterial3: true` still in it, because the planned edit wasn't in the staged version. Checking `git diff --staged` right before committing would have caught it. We fixed it with a new commit (`6ab3a4c`).

### 5. Check `git status` before committing

It answers: *Am I on the right branch? What's staged? Is anything unexpected here?* Ten seconds of checking prevents a messy history.

### 6. Unsaved files

VS Code shows a **●** dot on the tab of a file with unsaved changes. Git only sees **saved** files, so always save (Ctrl+S) before `git add`.

---

## G. Phase 0 completion checklist

Status is based on the verified Git history and our conversation.

| Goal | Status | Evidence |
|---|---|---|
| Flutter environment works (`flutter doctor`) | ✅ Done | All required checks ✓; only Visual Studio ✗ (not needed) |
| App runs on the Android emulator | ✅ Done | You ran it and confirmed it works |
| Hot reload vs. hot restart understood | ✅ Done | Experiment done and explained correctly |
| Counter template replaced with the ShopLite shell | ✅ Done | Commit `0a4709f` |
| Basic understanding of the app structure (`main.dart` vs. `app.dart`) | ✅ Done | Built by you in Step 11 |
| Stricter lints enabled; `flutter analyze` clean | ✅ Done | Commit `8144058`; "No issues found!" |
| Widget test updated and passing | ✅ Done | "All tests passed!" |
| Git repository created; `.gitignore` reviewed and extended | ✅ Done | Rules for `.env`, `.env.*`, `env/*.local.json` verified with `git check-ignore` |
| GitHub remote connected and `main` pushed | ✅ Done | `origin` → `M-Khairy-B/ShopLite` |
| Working branch with small commits | ✅ Done | `phase-0-setup`: 3 commits, pushed |
| Merged into `main` with `--no-ff` and pushed | ✅ Done | Merge commit `bf14672` on `origin/main` |
| `phase-0` annotated tag pushed | ✅ Done | `refs/tags/phase-0` on GitHub |
| Phase 0 knowledge check answered | ✅ Done | Hot reload, `.gitignore`, and `uses-material-design` answered correctly |
| **Opened DevTools Widget Inspector** (roadmap task 7) | ⏳ **Not done yet** | Never done during Phase 0. Can be done at the start of Phase 1, where it's most useful. |
| Folder skeleton `core/` and `features/` | ↪️ **Deliberately postponed** | Git doesn't track empty folders; they'll be created in Phase 1 with their first files. Only `lib/app/` exists now. |

**Verdict:** Phase 0 is **complete** (merged and tagged). The only open item is the DevTools Widget Inspector, a small optional exploration that we'll do in Phase 1.

---

## H. Knowledge check

Answer each one **before** opening the Answer Key. Write your answers down or say them out loud.

1. What's the difference between `main()` and `runApp()`?
2. Why are we allowed to write `runApp(const ShopLiteApp())`? What in `app.dart` makes `const` possible here?
3. What's the difference between `git add` and `git commit`?
4. You create a new file `lib/core/money.dart` and run `git diff`. Nothing appears. Is the file lost? Explain.
5. Our test uses `findsOneWidget`. What would happen if the welcome text accidentally appeared **twice** on screen? And what if it were missing?
6. Why can't we write `home: const Scaffold(...)` in our current `app.dart`, even though `Scaffold` has a const constructor?
7. You change `initState` in a `StatefulWidget` and press `r`. Nothing seems to change. Why, and what should you press instead?
8. After running `git diff`, the terminal shows `:` at the bottom and doesn't respond normally to commands. What's happening, what should you press, and what can go wrong if you keep typing?
9. Last week you pushed a commit that contained `.env` with a real API key. Today you add `.env` to `.gitignore`. Is the key safe now? List the steps you should take.
10. Look at the graph in section C. Why does the history show a side line joining `main`, instead of a straight line? What command made that happen, and why do we prefer it for phases?

---

## I. Readiness for Phase 1

### Phase 0 concepts you'll use constantly in Phase 1

| Concept | How it appears in Phase 1 |
|---|---|
| Widgets, the widget tree, `build()` | Building `ProductCard`, `HomeScreen`, the details screen |
| `StatelessWidget` | Most Phase 1 widgets |
| `BuildContext` | `Theme.of(context)`, `Navigator.push(context, ...)` |
| `const` + lints | Every widget you write; the analyzer will remind you |
| Hot reload vs. restart | The `QuantitySelector` lifecycle experiment builds directly on your `_counter` experiment |
| `ThemeData` / `ColorScheme` | Phase 1 task: a real app theme instead of hard-coded colors |
| `uses-material-design` | Icons on cards (favorite, rating stars) |
| `flutter analyze` + `flutter test` | Before every commit |
| Git branch → small commits → review → merge `--no-ff` → tag | Repeated for `phase-1-product-ui` |

### Self-assessment checklist

Be honest. Every "no" is a topic to review in this file before starting.

- [ ] I can explain what `build()` returns and why it must be fast.
- [ ] I can explain why `int _counter = 0;` doesn't reset on hot reload.
- [ ] I can draw the widget tree of our current app from memory.
- [ ] I know when a widget can be `const` and when it can't.
- [ ] I can explain what `findsOneWidget` checks.
- [ ] I can explain the difference between working tree, staging area, and commit.
- [ ] I can tell untracked, modified, staged, and ignored files apart in `git status`.
- [ ] I know why to check `git diff --staged` before committing.
- [ ] I know how to exit Git's pager.
- [ ] I can explain why we don't force-push and what to do instead.
- [ ] I can create a branch, commit, push, merge with `--no-ff`, and tag **without looking at notes**.

---

## Answer Key

<details>
<summary><strong>Click to show answers</strong> (try the questions first!)</summary>

**1. `main()` vs. `runApp()`**
`main()` is where every Dart program starts; Dart calls it automatically. `runApp()` is a Flutter function called *from* `main()` that takes a widget, makes it the root of the app, and shows it on screen.

**2. `runApp(const ShopLiteApp())`**
`ShopLiteApp` has a **const constructor**: `const ShopLiteApp({super.key});`. It also has no fields that change. That lets Dart create it at compile time and lets Flutter reuse it.

**3. `git add` vs. `git commit`**
`git add` puts changes into the **staging area** (choosing what goes into the next commit). It's easy to undo and isn't saved to history. `git commit` takes **everything staged** and saves it as a permanent snapshot in history.

**4. New file not in `git diff`**
The file isn't lost; it's **untracked**. `git diff` only compares files Git already tracks, and a new file has no previous version. You'll see it in `git status` as `??`, and after `git add` in `git diff --staged`.

**5. `findsOneWidget` with two texts or none**
It requires **exactly one** match, so the test **fails** in both cases: with two texts (duplicated UI) and with zero (missing UI). This is useful because it catches both kinds of bug.

**6. Why not `const Scaffold(...)`**
A widget can be `const` only if **everything inside it** is const too. Our `Scaffold` contains an `AppBar`, and `AppBar`'s constructor isn't `const`. One non-const child makes the whole `Scaffold` non-const. The analyzer knows this, so it doesn't suggest `const` there.

**7. Changing `initState` + hot reload**
`initState` runs **only once**, when the `State` object is created. Hot reload keeps the existing `State` object, so `initState` doesn't run again. Press **`R` (hot restart)** to create new `State` objects. (Or leave and reopen that screen, which creates a new `State`.)

**8. The `:` prompt**
You're inside Git's **pager** (`less`), which is showing long output. Press **`q`** to exit. If you keep typing, the pager treats your letters as its own commands. We saw this create a junk file named `hell"`, because `s` means "save to file" in the pager.

**9. Pushed API key, then added to `.gitignore`**
**Not safe.** `.gitignore` doesn't affect already-tracked files, and the key is in the pushed history, which anyone with access can read. Steps:
1. **Rotate the key**: revoke it and create a new one with the provider. This is the most important step.
2. `git rm --cached .env`, keeping the file locally.
3. Make sure `.env` is in `.gitignore`.
4. Commit and push.
The old key stays in the history, which is why rotating it is required.

**10. Side line in the graph**
We merged with **`git merge --no-ff phase-0-setup`**. `--no-ff` forces a **merge commit** even when a fast-forward was possible. A fast-forward would have moved `main` forward in a straight line, with no sign that a phase branch existed. The merge commit (`bf14672`) groups Phase 0's three commits and marks where the phase ended, which makes the project's progress easy to read. The `phase-0` tag marks that point permanently.

</details>
