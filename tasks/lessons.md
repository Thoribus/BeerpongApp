# Lessons Learned

Patterns extracted from corrections and bugs encountered during development.
Review at the start of each session to avoid repeating mistakes.

---

## Flutter Testing

### 1. Lazy `GridView.builder` / `ListView.builder` in widget tests
**Rule:** `find.text()` cannot find items that were never built. Items outside the test viewport are skipped by lazy builders — `skipOffstage: false` does NOT help (it only finds built-but-hidden widgets).

**Fix:**
```dart
await tester.binding.setSurfaceSize(const Size(800, 12000));
addTearDown(() async => tester.binding.setSurfaceSize(null));
```
Set the surface tall enough that all items fit and are eagerly rendered before calling `find.text()`.

**Apply when:** Any test that needs to find specific text inside a `ListView.builder`, `GridView.builder`, or `SliverList` widget where items may not all be on screen.

---

### 2. Stale test expectations after source changes
**Rule:** When a UI element is removed from source, update all tests that assert on it immediately. Don't leave `expect(find.text('Play Again'), findsWidgets)` in tests when the button no longer exists.

**Fix:** Search all test files for the removed text/widget type before committing. `grep -r "Play Again" test/` confirms no stale expectations remain.

**Apply when:** Removing or renaming any user-visible string, button, or widget.

---

### 3. Use `(color.r * 255.0).round()` — not `color.red`
**Rule:** `Color.red`, `Color.green`, `Color.blue` are deprecated in Flutter. Use the float accessors instead.

**Fix:**
```dart
final r = (color.r * 255.0).round();
final g = (color.g * 255.0).round();
final b = (color.b * 255.0).round();
```

**Apply when:** Writing any test or production code that inspects RGB channel values of a `Color`.

---

## Dart / Flutter Architecture

### 4. Never duplicate a class declaration when inserting above it
**Rule:** When adding a new class before an existing one in a file, check the full file structure first. Inserting `class AppConstants {` accidentally created a duplicate declaration, causing a compile error.

**Fix:** Read the full file with the Read tool before any structural edit. If inserting a sibling class, place it cleanly outside the existing class braces — confirm by reading the surrounding context.

**Apply when:** Editing files with large classes or multiple top-level declarations.

---

### 5. `const` keyword on widgets inside methods
**Rule:** Flutter lint warns (and in strict mode, errors) when a widget constructor is `const`-eligible but the `const` keyword is omitted. This surfaces in new `_build*` methods where sub-widgets are all constant.

**Fix:** Add `const` to `Icon(Icons.lock, ...)` → `const Icon(Icons.lock, ...)` and similar inside grid/list builder callbacks.

**Apply when:** Writing new `_build*Grid()` or `_build*List()` methods that construct widgets from constant data.

---

### 6. `updateUser()` must not be called while a dialog is open
**Rule:** `UserProvider.updateUser()` calls `notifyListeners()`, which causes GoRouter to rebuild the widget tree. If a dialog is open, its `BuildContext` is disposed mid-flight, crashing `AwesomeDialog.dismiss()`.

**Fix:** Always call `updateUser()` after navigation has completed or after the dialog has been closed.

**Apply when:** Any flow that saves user data (profile updates, game end) while a dialog may be visible.

---

## Workflow

### 7. Verify test titles match actual source before committing tests
**Rule:** Hardcoded achievement titles like `['Wins', 'Losses', 'Friendships']` in tests rotted silently. The real catalogue had `['Sniper', 'Pyromaniac', 'Winner', ...]`.

**Fix:** Always derive expected values from the same source of truth used by the production code (e.g., iterate `AchievementEngine.allAchievements` instead of hardcoding strings).

**Apply when:** Writing tests for any catalogue, list, or enum-driven UI. Prefer `for (final item in Source.allItems)` over hand-typed expected values.

---

### 8. Run `flutter test` before every commit
**Rule:** Never commit without a green test suite. Two failures were caught only at commit time that could have been caught earlier.

**Fix:** Make `flutter test` the last step before `git add`. If CI also runs it, a local pass gives confidence before the push.

**Apply when:** Always — this is a hard rule, not situational.

---

### 9. `_makeUser()` helper parameters must be passed through to the constructor
**Rule:** Adding a parameter to a test helper (`int nightGames = 2`) but forgetting to forward it to `User(nightGames: nightGames)` produced an "unused parameter" lint warning and meant the test was not actually testing what it claimed.

**Fix:** After adding any named parameter to a test helper, immediately verify the parameter is forwarded in the constructor call.

**Apply when:** Extending any `_makeUser()`, `_makeGame()`, or similar factory helper in tests.
