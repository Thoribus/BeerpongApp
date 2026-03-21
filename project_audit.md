# BeerpongApp — Audit & Implementation Plan

**Date**: 2026-03-21
**Status**: Decisions made, implementation plan ready

---

## Decisions (from audit review)

| Finding | Decision |
|---------|----------|
| `activity_screen.dart` orphaned | **Delete** |
| `spectate_lobby_screen.dart` orphaned | **Reintegrate** — was unlinked, not intentionally removed |
| Shop tab has no purchase action | **Keep as-is** — work in progress |
| Challenge system half-built | **Remove entirely** |
| `backgroundKey` unimplemented | **Implement** as a customization feature |
| `hitLastCup`, `totalHeatingUp`, `nightGames` invisible | **Surface** in statistics and achievements |
| AccountScreen overloaded (3 unrelated sub-tabs) | **Split** — Profile = Customize only; Stats gets Progress sub-tab |
| Route path strings are magic literals | **Centralize** in `AppRoutes` constants class |
| Repositories live under `lib/util/` | **Move** to `lib/repositories/` |
| `total*` prefix inconsistency between User and Player | **Strip `total` prefix** from User fields |

---

## Part 1 — Audit Findings (for reference)

### Dead Code

- `lib/screens/activity_screen.dart` — unreferenced, safe to delete
- `lib/screens/spectate_lobby_screen.dart` — unlinked from router and nav, needs reintegration
- `lib/util/repositories/challenge_repository.dart` methods `sendChallenge`, `hasPendingChallenge`, `acceptChallenge`, `declineChallenge` — never called (entire repository will be deleted)

### Duplicate / Overlapping

- **Challenge vs. Invitation**: Challenge = generic social "want to play?" request. Invitation = slot reservation in a specific game with team/position. Genuinely different semantics, but Challenge implementation is incomplete (accept/decline wired to nothing). Decision: remove Challenge, keep Invitation.

### Thematic Inconsistencies

- AccountScreen `/profile` hosts Customize, Achievements, Progress — three distinct concerns crammed into one route.
- StatisticsScreen `/games` has four dense sub-tabs but no progression/level content.
- `hitLastCup`, `totalHeatingUp`, `nightGames` are tracked per-game, written to Firestore, and have matching achievements — but are displayed nowhere.
- `backgroundKey` is modelled, serialized, and documented but has no UI surface.

### Architecture

- Route paths (`'/login'`, `'/home'`, `'/games'`, etc.) are string literals scattered across `router.dart`, `base_screen.dart`, and any `context.go()` call.
- `lib/util/repositories/` — repositories are not utilities; wrong directory.
- `spectate_lobby_screen.dart` calls `FirebaseFirestore.instance` directly, bypassing `FirestoreService`.

### Naming Convention

- User model uses `total` prefix for cumulative stats (`totalBounceMakes`, `totalBounceAttempts`, `totalIslandMakes`, `totalIslandAttempts`, `totalDeathCupHits`) while Player uses bare names (`bounceMakes`, `bounceAttempts`). The prefix is redundant — all User stats are lifetime totals by definition.
- `Player.islandShotUsed` (boolean) is redundant with `Player.islandAttempts > 0`.

---

## Part 2 — Implementation Plan

Tasks are ordered by dependency. Items within a phase can be done in parallel.

---

### Phase 1 — Deletions (no dependencies)

#### 1.1 Delete `activity_screen.dart`

- **Delete**: `lib/screens/activity_screen.dart`
- **Verify**: No imports reference it (confirmed by audit).

#### 1.2 Remove Challenge System

Remove all challenge-related code across the codebase.

**Delete entirely:**

- `lib/models/challenge.dart`
- `lib/util/repositories/challenge_repository.dart`

**Edit — `lib/util/firestoreservice.dart`:**

- Remove `streamIncomingChallenges()` method
- Remove any challenge-related CRUD methods
- Remove import of `challenge.dart` and `challenge_repository.dart`

**Edit — `lib/screens/base/base_screen.dart`:**

- Remove `_buildFriendsNavItem()` (the `StreamBuilder`-based method with challenge badge)
- Replace with the original static `_buildNavItem()` call for the Friends tab
- Remove import of `firestoreservice.dart` if it was only used for the challenge stream

**Edit — `lib/screens/friends/friends_screen.dart`:**

- Remove `_buildChallengeCard()` method
- Remove challenge card rendering from `_buildSocialPage()`
- Remove any `Challenge`-related imports and state

**Edit — `lib/constants.dart`:**

- Remove `colChallenges` if it exists

---

### Phase 2 — Naming Convention Cleanup

This is done early because many later phases touch `User` fields, so it is better to rename first and have one coherent change.

#### 2.1 Strip `total` Prefix From User Model

Rename fields in `lib/models/user.dart`:

| Old name | New name |
|----------|----------|
| `totalBounceAttempts` | `bounceAttempts` |
| `totalBounceMakes` | `bounceMakes` |
| `totalIslandAttempts` | `islandAttempts` |
| `totalIslandMakes` | `islandMakes` |
| `totalDeathCupHits` | `deathCupHits` |

Fields that keep their names (no Player equivalent or already consistent):

- `totalScore` — keep (Player uses `score: double`, semantically different)
- `totalMisses` — keep
- `totalAirballs` — keep
- `totalThrows` — keep
- `totalHeatingUp` — keep (Player uses `heatingUp: int`; different cardinality)

**Files to update after renaming:**

| File | What changes |
|------|-------------|
| `lib/models/user.dart` | Field declarations, constructor defaults, `toJson`, `fromJson`, `copyWith` |
| `lib/util/repositories/user_repository.dart` | All field references in `mapPlayerToUser`, `saveGame` merge logic |
| `lib/util/achievement_engine.dart` | `valueGetter` lambdas referencing `u.totalBounceMakes`, etc. |
| `lib/screens/games/personal_statistics_screen.dart` | Stats grid tile definitions |
| `lib/screens/profile/account_screen.dart` | Any direct field references |
| `lib/util/debug_seeder.dart` | Field names in the seed data map |

#### 2.2 Remove `Player.islandShotUsed`

- **Edit `lib/models/player.dart`**: Remove `bool islandShotUsed` field, constructor param, and any `fromJson`/`toJson` references.
- **Search & replace**: Any read of `islandShotUsed` → replace with `islandAttempts > 0`.
- **Files likely affected**: `lib/screens/game/game_screen.dart`, `lib/screens/game/game_controller.dart`.

---

### Phase 3 — Structural Refactors

#### 3.1 Move Repositories to `lib/repositories/`

Create `lib/repositories/` and move these files (challenge_repository.dart was already deleted in Phase 1):

| Source | Destination |
|--------|-------------|

| `lib/util/repositories/user_repository.dart` | `lib/repositories/user_repository.dart` |
| `lib/util/repositories/game_repository.dart` | `lib/repositories/game_repository.dart` |
| `lib/util/repositories/invitation_repository.dart` | `lib/repositories/invitation_repository.dart` |
| `lib/util/repositories/friend_repository.dart` | `lib/repositories/friend_repository.dart` |
| `lib/util/repositories/tournament_repository.dart` | `lib/repositories/tournament_repository.dart` |

**Update imports** in every file that imports from `lib/util/repositories/`:

- `lib/util/firestoreservice.dart` (primary consumer)
- Any screen that imports directly from a repository

#### 3.2 Centralize Route Paths in `AppRoutes`

Create `lib/constants/routes.dart`:

```dart
abstract final class AppRoutes {
  static const login         = '/login';
  static const home          = '/home';
  static const shop          = '/shop';
  static const friends       = '/friends';
  static const games         = '/games';
  static const profile       = '/profile';
  static const game          = '/game';
  static const gameMode      = '/game-mode';
  static const tournament    = '/tournament/:id';
  static const spectateLobby = '/spectate-lobby/:gameId';
  static const spectateLive  = '/spectate-live/:gameId';
  static const compare       = '/compare';
  static const invitations   = '/invitations';
  static const waiting       = '/waiting';

  // Parameterized helpers
  static String tournamentPath(String id) => '/tournament/$id';
  static String spectateLobbyPath(String gameId) => '/spectate-lobby/$gameId';
  static String spectateLivePath(String gameId) => '/spectate-live/$gameId';
}
```

**Files to update:**

- `lib/util/router.dart` — replace all string literals with `AppRoutes.*`
- `lib/screens/base/base_screen.dart` — any `context.go()` calls
- `lib/screens/spectate_lobby_screen.dart` — `context.pushReplacement('/spectate-live/${...}')` → `AppRoutes.spectateLivePath(...)`
- Every `context.go(...)` / `context.push(...)` in the codebase

---

### Phase 4 — Reintegrate Spectate Lobby

`ReadOnlyLobbyScreen` is a waiting room that streams a game document and auto-navigates to `LiveGameStatsScreen` once `started == true`. It is a valid, complete screen that simply lost its route registration.

#### 4.1 Fix Direct Firestore Access

**Edit `lib/screens/spectate_lobby_screen.dart`:**

- Replace `FirebaseFirestore.instance.collection('games').doc(widget.gameId).snapshots()` with `FirestoreService.instance.getGameDocStream(widget.gameId)` (this method already exists — it is used by `GameScreen`).
- Add import for `FirestoreService`.

#### 4.2 Register the Route

**Edit `lib/util/router.dart`:**

- Import `spectate_lobby_screen.dart`
- Add route:

  ```dart
  GoRoute(
    path: AppRoutes.spectateLobby, // '/spectate-lobby/:gameId'
    builder: (context, state) {
      final gameId = state.pathParameters['gameId']!;
      return ReadOnlyLobbyScreen(gameId: gameId);
    },
  ),
  ```

#### 4.3 Add Entry Points

A spectator needs a way to reach `/spectate-lobby/:gameId`. Candidate entry points:

1. **Invitation acceptance** — when accepting an invitation with `type: 'spectate'` (if Invitation model supports it) or when a game invite includes a spectate option.
2. **Friends list** — show a "Watching" or "In Game" status on a friend's card with a "Watch" button that navigates to the spectate lobby.
3. **Home screen** — "Join as spectator" option when entering a game ID.

**Minimum viable**: Add a "Watch" button to the friend card in `friends_screen.dart` that appears when the friend has an active `lastGameAt` within the last 3 hours. Button navigates to `AppRoutes.spectateLobbyPath(gameId)`. Requires storing or retrieving the active `gameId` on the friend's user document.

---

### Phase 5 — AccountScreen Overload Reduction

**Goal**: Profile tab = customization only. Progression and achievements move to the Stats tab.

#### 5.1 Simplify AccountScreen

**Edit `lib/screens/profile/account_screen.dart`:**

- Remove the `PageController` and `PageView`
- Remove `AppTabBar` (tab bar widget)
- Remove `AchievementsScreen` and `_ProgressTab` imports/references
- `AccountScreen.build()` renders:
  - The logout `IconButton` (keep in an `AppBar` or a trailing icon in the body)
  - `CustomUserScreen(user: user)` directly, no wrapping tabs

The result is a clean single-purpose profile screen.

#### 5.2 Add "Progress" Sub-tab to StatisticsScreen

**Edit `lib/screens/games/statistics_screen.dart`:**

- Add `'Progress'` as a 5th tab (or replace `'Breakdown'` if 5 feels too dense — evaluate in practice)
- Recommended tab order: **Stats | Performance | Progress | Breakdown | History**
- Wire the new tab to the existing `_ProgressTab` widget (move it from `account_screen.dart` to `statistics_screen.dart` or extract it to its own file `lib/screens/games/progress_screen.dart`)

`_ProgressTab` already has: XP/level card, next-tier callout, tier roadmap, achievement category progress bars, unlocked titles, and "Almost There" upcoming unlocks. It fits naturally alongside the other Stats sub-tabs.

#### 5.3 Full AchievementsScreen Access

The detailed `AchievementsScreen` grid (all achievements by category) should be reachable from the Progress tab via a button or a tap on a category row, not as a standalone tab. Options:

- **Push route**: Add `GoRoute(path: '/achievements', ...)` and navigate from Progress tab.
- **Bottom sheet / modal**: Show the full grid in a `DraggableScrollableSheet`.

Recommended: push route `/achievements` from a "View all achievements" button at the top of the Progress tab. This avoids an extra always-visible tab slot.

---

### Phase 6 — Surface Hidden Stats

#### 6.1 Add Missing Tiles to Statistics Grid

**Edit `lib/screens/games/personal_statistics_screen.dart` — `_buildStatsGrid()`:**

Add these three tiles to the existing 12-tile grid (making 15 tiles, or replace 3 less-useful ones):

| Stat | Icon | Color | Label |
|------|------|-------|-------|

| `hitLastCup` | `Icons.sports_score` | `Colors.amber` | `'Last Cup'` |
| `totalHeatingUp` | `Icons.whatshot` | `Colors.orange.shade300` | `'Heating Up'` |
| `nightGames` | `Icons.nightlight_round` | `Colors.indigo` | `'Night Games'` |

These three already have achievement definitions (`last_cup`, `heating_up`, `night_games`) so surfacing the raw stat value gives the user context for why those achievements exist.

---

### Phase 7 — Implement `backgroundKey`

`backgroundKey` is already on the `User` model and serialized to Firestore. It needs a set of options and a UI surface.

#### 7.1 Define Background Options

**Edit `lib/constants.dart`:**

```dart
static const List<String> backgroundKeys = [
  'bg_default',
  'bg_amber',
  'bg_blue',
  'bg_green',
  'bg_purple',
  'bg_dark',
];

/// Minimum level required to equip each background.
static const Map<String, int> backgroundLevelRequirements = {
  'bg_default': 1,
  'bg_amber':   1,
  'bg_blue':    6,
  'bg_green':   11,
  'bg_purple':  16,
  'bg_dark':    21,
};
```

Backgrounds can be implemented as solid colors, gradients, or SVG assets depending on the art direction. Start with programmatic gradients (no extra assets needed).

#### 7.2 Add Background Selection to CustomUserScreen

**Edit `lib/screens/profile/custom_user_screen.dart`:**

- Add `String _selectedBackgroundKey` state field (initialized from `widget.user.backgroundKey`)
- Add `_buildBackgroundGrid()` method below the avatar grid — similar layout to avatar grid but shows color swatches with lock overlays for level-gated options
- Include `_selectedBackgroundKey` in `_previewUser.copyWith(backgroundKey: ...)` so the live preview card updates

#### 7.3 Apply Background in `UserCard`

**Edit `lib/widgets/user_card.dart`:**

- Map `user.backgroundKey` to a `Color` or `LinearGradient`
- Replace (or layer over) the static `slanted-gradient.svg` with the user's chosen background
- Keep SVG as the default (`bg_default`) to avoid breaking existing cards

---

## Implementation Order Summary

```
Phase 1 — Delete & Remove Challenge     (no deps)
Phase 2 — Rename User fields            (no deps, do before anything touching User)
Phase 3 — Move repositories, AppRoutes  (no deps)
Phase 4 — Reintegrate spectate lobby    (depends on Phase 3 for AppRoutes)
Phase 5 — AccountScreen split           (depends on Phase 2 for clean User refs)
Phase 6 — Surface hidden stats          (depends on Phase 2 for renamed fields)
Phase 7 — backgroundKey feature         (depends on Phase 2, Phase 5)
```

Phases 1, 2, and 3 can be started in parallel if worked on separate branches. Phases 4–7 each have only their listed dependencies.
