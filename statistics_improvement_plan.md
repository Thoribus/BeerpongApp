# Statistics Improvement Plan — BeerpongApp

## 1. Research: What Stats Matter in Beer Pong?

Beer pong is a competitive precision sport with well-defined mechanics. At every level
of play, from casual to tournament, the following categories of stats are meaningful:

### 1.1 Core Shooting
| Metric | Description |
|--------|-------------|
| Hit Rate (Accuracy) | Cups sunk / total throws |
| Airball Rate | Airballs / total throws |
| Miss Rate (non-airball) | (misses − airballs) / total throws |
| Bounce Conversion Rate | Bounce makes / bounce attempts |
| Island Shot Conversion Rate | Island makes / island attempts |

### 1.2 Per-Rack / Positional Stats
| Metric | Description |
|--------|-------------|
| Cup position hit distribution | Which of the 10 cups is hit most/least (heatmap) |
| Front-row vs back-row accuracy | Rows 1–4 vs rows 5–7 vs 8–9 vs apex |
| First throw of round accuracy | Is the player better/worse on their first throw? |
| Clutch rate | How often the winning shot (last cup) is hit by this player |

### 1.3 Streak & Consistency Metrics
| Metric | Description |
|--------|-------------|
| On Fire (3 in a row) frequency | Per game, career |
| Heating Up (2 in a row) frequency | Per game, career |
| Current win/loss streak | Consecutive wins or losses |
| Longest win streak | Career |
| Max consecutive hits in a game | Single-game peak |

### 1.4 Game Outcome Metrics
| Metric | Description |
|--------|-------------|
| Win Rate | Wins / (wins + losses) |
| Dominant win rate | Wins with ≥ 5 cups remaining (shutout-style) |
| Average margin of victory | Avg cups remaining when winning |
| Average cups hit per game | Total cups / games played |
| Average throws per game | Total throws / games played |
| Average game duration | Minutes per game |
| Average rounds per game | Rounds played per game |

### 1.5 Special Plays
| Metric | Description |
|--------|-------------|
| Death cups triggered | How often the player sinks a re-rack cup |
| Defended cups | Cups blocked/defended |
| Island makes | Already tracked |
| Bomb triggers | Player who first hit a cup that became a bomb |

### 1.6 Social / Comparative
| Metric | Description |
|--------|-------------|
| Head-to-head vs. opponent | W/L when specific friend is on the opposing team |
| Best teammate win rate | Win rate when paired with specific friend |
| Games played together | Count per friend |

---

## 2. Gap Analysis: What the App Already Tracks

### 2.1 Stats the app tracks correctly ✅

**Player (per-game)**
- `score` — cups hit
- `throws` — total throws
- `misses` — total misses (includes airballs)
- `airballs` — airball subset of misses
- `cupsHit: List<int>` — per-position cup hit log
- `onFire` — times triggered "On Fire" (3 consecutive)
- `heatingUp` — times reached 2 consecutive hits
- `bounceAttempts` / `bounceMakes` — bounce shot tracking
- `islandMakes` — island shots sunk
- `defended` — defended cups
- `lastCupHit` — won with the final shot
- `isWinner`

**User (lifetime)**
- `totalScore`, `totalMisses`, `totalAirballs`, `totalThrows`
- `onFire`, `defended`, `hitLastCup`
- `cupsHitCount: Map<String,int>` — positional hit counts → powers heatmap
- `wins`, `losses`
- `totalHeatingUp`
- `totalBounceAttempts`, `totalBounceMakes`
- `totalIslandMakes`

**Game document (Firestore)**
- `timestamp`, `endedAt` (both stored — duration is computable)
- `roundCount` (stored in Firestore but **never read back** into `GameStatistics`)
- `cupsRemainingWinner` (stored but **never read back**)
- `gameMode`, `specialRules`
- Full `team1` / `team2` player snapshots (score, throws, misses, airballs, etc.)

### 2.2 Stats tracked but NOT displayed anywhere ⚠️

| Field | Stored In | Missing From UI |
|-------|-----------|-----------------|
| `defended` | User + Player | stats screen, history cards |
| `totalHeatingUp` | User | stats grid, performance table |
| `bounceAttempts` | User | mentioned in grid as bounce% but `totalBounceAttempts` = 0 might hide it |
| `hitLastCup` | User | never shown |
| `roundCount` | games doc | never parsed into `GameStatistics` |
| `cupsRemainingWinner` | games doc | never parsed |
| `endedAt` | games doc | never used for duration |
| `gameMode` | games doc | not shown in history cards |
| `specialRules` | games doc | not shown in history cards |

### 2.3 Stats NOT tracked yet — need model changes ❌

| Stat | Where to Add | Priority |
|------|-------------|----------|
| `islandAttempts` | Player + User | Medium — currently only `islandShotUsed` (bool) |
| `deathCupHits` | Player + User | Medium — exists in events but not persisted to user profile |
| `longestWinStreak` | User | Low — computable from game history but expensive |
| `currentStreak` / `currentStreakType` | User | Low — fully derivable |
| First-throw accuracy | n/a | Low — would require per-throw event data |
| Head-to-head stats | n/a | Medium — derivable from game history given opponent IDs |

### 2.4 Known model inconsistencies 🐛

1. **`islandShotUsed: bool` vs `islandMakes: int`** — The per-game `Player` has a boolean
   `islandShotUsed` (was the rule invoked?) and an integer `islandMakes` (cups sunk via
   island). But there is no `islandAttempts` integer, so island conversion rate cannot be
   computed. Fix: replace `islandShotUsed: bool` with `islandAttempts: int`.

2. **`misses` double-counts airballs** — `incrementAirballs()` also calls `misses++`. This
   means "misses" shown in the UI includes airballs. For a clean "bad-miss" (non-airball)
   rate the code must use `misses - airballs`. This is not reflected anywhere in the stats
   UI. Add a `pureHits` getter or surface `normalMisses` where appropriate.

3. **`hitLastCup` in User is an `int`** (lifetime count) but in Player it is a `bool`.
   Fine, but `hitLastCup` should be renamed `lastCupHits` on User for clarity.

---

## 3. Statistics Screen — Screen-by-Screen Improvement Plan

The current screen has **3 tabs: Stats → Performance → History**.

The plan proposes **4 tabs: Overview → Trends → Breakdown → History**.

---

### Tab 1: Overview (replaces "Stats" / `PersonalStatisticsScreen`)

**Current state:** Hero card → recent form strip → 8-tile grid (Wins, Losses, Win Rate,
Hit Rate, Cups Hit, On Fire, Bounce%, Islands).

**Improvements:**

#### 1a. Hero card — no change
Already well designed. Keep win-rate arc ring, W/L chips, hit rate.

#### 1b. Recent form strip — extend to 10 games, add tooltip
Show last 10 results (W/L circles). On tap, show the game date and hit rate
as a tooltip. Currently takes 8, increase to 10.

#### 1c. Derived stat chips row (NEW)
Below the form strip, a horizontal scroll row of amber stat pills:
```
🔥 Avg X cups/game   💡 Avg X throws/game   ⏱ Avg X:XX/game   📍 X-game streak
```
All computable from `games` list already passed to the screen.

#### 1d. Stat grid — expand to 12 tiles in a 3×4 grid
Replace the 4-column 8-tile grid (items too small) with a 3-column 12-tile layout:

| Icon | Label | Value | Colour |
|------|-------|-------|--------|
| 🏆 | Wins | N | amber |
| ✗ | Losses | N | red |
| % | Win Rate | N% | green |
| 🎯 | Hit Rate | N% | blue |
| 🍺 | Cups Hit | N | orange |
| 🔥 | On Fire | N | deepOrange |
| ↩️ | Bounce% | N% | purple |
| 🏝 | Islands | N | teal |
| 🛡 | Defended | N | indigo |
| 🌡 | Heating Up | N | orange.shade300 |
| 🎯 | Last Cup | N | amber |
| 📊 | Avg/Game | N cups | grey |

Use `user.totalBounceAttempts`, `user.defended`, `user.totalHeatingUp`, `user.hitLastCup`
(all currently stored but not displayed).

#### 1e. Career highlights row (NEW)
Three cards in a horizontal row — big, eye-catching numbers:
```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  BEST STREAK │  │ BEST HIT RATE│  │  MOST CUPS   │
│     N games  │  │  N% (1 game) │  │  N in 1 game │
└──────────────┘  └──────────────┘  └──────────────┘
```
These require iterating `games` (already in scope) and computing per-game stats.

**Visual style:** Card background `c.surface2`, amber top-border accent, value in
`fontSize: 22 bold`, label in `fontSize: 10 subtle`.

---

### Tab 2: Trends (replaces "Performance" / `PerformanceScreen`)

**Current state:** Filter chips (All / Last 10 / Last 5) → StatisticsTable with sparklines
and slope % → Cup position heatmap.

**Improvements:**

#### 2a. Keep filter chips
Already good. Add a 4th chip: "Last 3" for high-frequency players.

#### 2b. StatisticsTable — add missing rows
Currently shows: Total Score, Total Misses, Total Airballs, Cups Hit, Hit Rate, Win Rate.

Add:
- **Bounce Rate** (bounceMakes / bounceAttempts) — line chart of per-game conversion
- **Defended** (per game) — line chart
- **On Fire** (per game) — line chart
- **Heating Up** (per game) — line chart

Each row already shows a sparkline + slope % — apply the same pattern.

#### 2c. Sparkline improvement — add game-date tooltip on tap
The detail dialog currently shows the regression line but has no x-axis labels.
Replace `bottomTitles: SideTitles(showTitles: false)` with date labels from
`userStatsList` sorted by date. Pass dates alongside `rawData` to the dialog.

#### 2d. Cup heatmap — keep as-is but add per-position count labels
Currently shows colours but no numbers on the cups. The `hitCount` is already
passed to `cup.widget(hitCount: ...)`. Verify the `Cup` widget renders it.
If not, add a small `Text` overlay inside each cup widget.

#### 2e. Add a "Row accuracy" bar chart below the heatmap (NEW)
Group the 10 positions by row:
- Row 1 (front, 4 cups): positions 0–3
- Row 2 (3 cups): positions 4–6
- Row 3 (2 cups): positions 7–8
- Row 4 (apex, 1 cup): position 9

Show a 4-bar horizontal bar chart where bar length = (hits in row) / (total hits).
This reveals whether the player is a front-rack sniper or an apex specialist.

**Visual:** `fl_chart` `BarChart`, horizontal orientation, amber fill, subtle row labels
on the left ("Front", "Mid", "Back", "Apex").

---

### Tab 3: Breakdown (NEW tab)

This tab visualises stats that can't fit naturally in Trends — per-shot type breakdowns
and head-to-head comparisons.

#### 3a. Shot type comparison — Donut chart
A single donut chart divided into: **Hits** (green) | **Misses** (red) | **Airballs** (blue).

Centred value: total throws. Legend below.

Use `fl_chart`'s `PieChart` with `sectionsSpace: 3`, `centerSpaceRadius: 40`.

#### 3b. Special shots breakdown — Horizontal stat bar cards
Three cards stacked vertically, each showing a mini dual-bar (attempts vs makes):
```
Bounce Shot    ████████░░░░  3/7  (43%)
Island Shot    ██████░░░░░░  2/5  (40%)     ← requires islandAttempts
Defended       ████░░░░░░░░  5 total
```

Each card: `c.surface2` background, coloured left border accent, attempt/make counts
in bold, conversion % in amber.

#### 3c. Win/Loss context analysis (NEW)
Two small donut charts side by side:
- Left: "When winning, how early did you clinch?" — distribution of `cupsRemainingWinner`
  bucketed as: Dominant (≥5), Comfortable (3–4), Close (1–2)
- Right: "When was the game-winning cup hit?" — `hitLastCup` / wins as a %

Requires reading `cupsRemainingWinner` from the games list (needs `GameStatistics` model fix).

#### 3d. Head-to-head friend comparison link
A card at the bottom linking to the existing `/compare` route, showing a friend avatar
grid. Already implemented in `compare_stats_screen.dart` — just surface it here.

---

### Tab 4: History (from `statistics_screen.dart _buildHistoryTab`)

**Current state:** Expandable game cards with date, cup score (T1 – T2), your hit rate %,
and an inline player table (Player / Score / Throws / Miss / Hit%).

**Improvements:**

#### 4a. Game card header — add metadata badges
After the hit rate badge, add:
- **Game mode** badge if not "Single Game" (e.g. "Tournament")
- **Duration** badge: "12 min" (requires `endedAt` in `GameStatistics`)
- **Dominant win** badge: "🏆 +5" if `cupsRemainingWinner ≥ 5`
- **Special rules** pill: e.g. "Bomb · Island" if rules are active

#### 4b. Expanded player table — add more columns
Current columns: Player / Score / Throws / Miss / Hit%
Add: **Bounce** (b/B makes/attempts) | **🔥** (onFire) | **Def** (defended)

The table is already `Table` with `FlexColumnWidth`. Add 2–3 columns and
make the whole table horizontally scrollable.

#### 4c. Game-level "MVP" badge inside expanded section
Highlight the player with the highest hit rate per game with a ⭐ badge on their row.

#### 4d. Streak banner at top of list (NEW)
Before the `ListView`, show a small card:
```
┌────────────────────────────────────┐
│  🔥  Current streak: 3W            │
│  📈  Last 10 games: 7W  3L  (70%)  │
└────────────────────────────────────┘
```
Computed from `games` list. Green if winning streak, red if losing.

---

## 4. Data Model Changes Required

### 4.1 `Player` model

```dart
// ADD
int islandAttempts;   // replaces the boolean `islandShotUsed`
int deathCupHits;     // cups sunk via death cup rule

// KEEP (rename conceptually only, no code change needed)
// islandShotUsed → bool can be kept alongside islandAttempts for
// backward-compat deserialization, but should be deprecated in toJson
```

Backwards compatibility: `fromJson` reads `islandAttempts ?? 0` with a fallback
so old game documents don't break.

### 4.2 `User` model

```dart
// ADD
int totalIslandAttempts;   // lifetime island attempts
int totalDeathCupHits;     // lifetime death cups triggered
```

### 4.3 `GameStatistics` model

```dart
// ADD — parse from existing Firestore fields
final int roundCount;            // from 'roundCount' field
final int? cupsRemainingWinner;  // from 'cupsRemainingWinner' field
final int? durationSeconds;      // endedAt.seconds - timestamp.seconds
final String gameMode;           // from 'gameMode'
final List<String> specialRules; // from 'specialRules'
```

`fromFirestore` already receives the full doc map — just parse these extra fields.
No Firestore schema migration needed; they are already being written.

### 4.4 `UserRepository.saveGame`

Add to the Firestore transaction update map:
```dart
'totalIslandAttempts': FieldValue.increment(player.islandAttempts),
'totalDeathCupHits':   FieldValue.increment(player.deathCupHits),
```

### 4.5 `game_controller.dart` — increment new fields

In the game controller, where island shots are handled:
```dart
// When the player announces an island shot
player.islandAttempts++;

// When the island shot sinks a cup
player.islandMakes++;
```

Where death cup is handled:
```dart
player.deathCupHits++;
```

---

## 5. New Computed Properties (no model changes needed)

Add these as getters or helper functions in a new `lib/util/stats_helpers.dart`:

```dart
/// Average cups hit per game
double avgCupsPerGame(User u) =>
    (u.wins + u.losses) > 0 ? u.totalScore / (u.wins + u.losses) : 0;

/// Average throws per game
double avgThrowsPerGame(User u) =>
    (u.wins + u.losses) > 0 ? u.totalThrows / (u.wins + u.losses) : 0;

/// Bounce conversion rate
double bounceConversion(User u) =>
    u.totalBounceAttempts > 0
        ? u.totalBounceMakes / u.totalBounceAttempts
        : 0;

/// Island conversion rate (needs totalIslandAttempts added to User)
double islandConversion(User u) =>
    u.totalIslandAttempts > 0
        ? u.totalIslandMakes / u.totalIslandAttempts
        : 0;

/// Clutch rate — how often you hit the last cup per game played
double clutchRate(User u) =>
    (u.wins + u.losses) > 0 ? u.hitLastCup / (u.wins + u.losses) : 0;

/// Current win/loss streak from sorted game list
({int length, bool isWin}) currentStreak(
    List<GameStatistics> games, String username) { ... }

/// Best single-game hit rate
double bestSingleGameHitRate(List<UserStatsInGame> stats) { ... }

/// Most cups hit in a single game
int mostCupsInGame(List<UserStatsInGame> stats) { ... }
```

---

## 6. Firestore Query Notes

All new metrics derive from data **already being written** to Firestore. There are no
new collection writes required. The changes are:

1. Parse `roundCount`, `cupsRemainingWinner`, `endedAt`, `gameMode`, `specialRules`
   in `GameStatistics.fromFirestore` — they are already in the doc.

2. Add `totalIslandAttempts` and `totalDeathCupHits` increments to the
   `saveGame` transaction in `UserRepository`.

3. Add `islandAttempts` and `deathCupHits` to `Player.toJson` / `fromJson`.
   Old game documents that lack these fields will deserialize to `0` via
   the existing `?? 0` fallback pattern.

No Firestore index changes required. No new collection writes required.

---

## 7. Implementation Phases

### Phase 1 — Zero-migration quick wins (no model changes)
Surface data that is already stored but ignored:

1. **`GameStatistics`**: Parse `roundCount`, `cupsRemainingWinner`, `endedAt`,
   `gameMode`, `specialRules` from the existing Firestore doc.

2. **History tab**: Show game mode badge, duration, dominant-win badge,
   special rules pills in the game card header.

3. **Stats tab**: Add `Defended`, `Heating Up`, `Last Cup Hits` tiles to the
   stat grid using existing `user.defended`, `user.totalHeatingUp`, `user.hitLastCup`.

4. **Stats tab**: Add derived stats chips row (avg cups/game, avg throws/game,
   current streak) computed from the `games` list already in scope.

5. **Stats tab**: Add the Career Highlights row (best streak, best hit rate in
   one game, most cups in one game) computed from `games` + `userStatsList`.

6. **Trends tab**: Add Defended, On Fire, Heating Up rows to the `StatisticsTable`.

7. **Trends tab**: Add x-axis date labels to the detail chart dialog.

8. **Trends tab**: Add the Row Accuracy bar chart below the cup heatmap.

**Estimated files touched:** `personal_statistics_screen.dart`,
`performance_screen.dart`, `statistics_screen.dart`, `game_statistics.dart`.
No game logic changes. No Firestore schema changes.

---

### Phase 2 — Model additions (small, backward-compatible)

1. **`Player`**: Add `islandAttempts: int`, `deathCupHits: int`.
   Update `toJson`, `fromJson`, `clone`, `mergedWith`, `copyWithResetStats`.

2. **`User`**: Add `totalIslandAttempts: int`, `totalDeathCupHits: int`.
   Update `toJson`, `fromJson`, `copyWith`.

3. **`UserRepository.saveGame`**: Increment the two new user fields.

4. **`game_controller.dart`**: Increment `player.islandAttempts++` and
   `player.deathCupHits++` at the right places.

5. **Trends tab**: Add Island Conversion row to `StatisticsTable` (was previously
   impossible without `islandAttempts`).

6. **Breakdown tab (NEW)**: Implement the new third tab with:
   - Shot type donut chart
   - Bounce / Island / Defended horizontal comparison cards
   - Win/loss context section

---

### Phase 3 — Streak tracking & social stats

1. Compute `currentStreak` and `longestWinStreak` from game history on the client
   (no Firestore write needed for current streak; add `longestWinStreak` to `User`
   if you want it persisted).

2. Streak banner at the top of the History tab.

3. Head-to-head section in the Breakdown tab using game history.

4. `compare_stats_screen.dart` UI overhaul (already flagged in UI audit).

---

## 8. Visual Design Reference

### Colour conventions (consistent with existing AppColors)
| Stat type | Colour |
|-----------|--------|
| Wins / positive outcomes | `Colors.green` |
| Losses / negative outcomes | `Colors.redAccent` |
| Hit rate / accuracy | `Colors.blue` |
| Special shots (bounce, island) | `Colors.purple` / `Colors.teal` |
| On fire / streaks | `Colors.deepOrange` |
| Neutral counts | `Colors.amber` |
| Defended | `Colors.indigo` |

### Chart types per metric
| Metric | Chart type | Notes |
|--------|-----------|-------|
| Hit rate over time | LineChart (sparkline + detail) | existing |
| Cup position heatmap | Custom pyramid widget | existing |
| Row accuracy | BarChart (horizontal) | new |
| Shot type split | PieChart (donut) | new |
| Bounce/Island conversion | LinearProgressIndicator pair | new |
| Win/loss streak | Form strip (W/L circles) | existing, extend |
| Career highlights | Stat cards (3 horizontal) | new |
| Win context | PieChart (donut, small) | new |

### Spacing & typography
- Section titles: `fontSize: 13, fontWeight: w600, color: c.subtle, letterSpacing: 0.5`
- Card values: `fontSize: 22, fontWeight: bold, color: c.onBackground`
- Card labels: `fontSize: 10, color: c.subtle`
- All chart colours: use the table above for consistency
- Card background: `c.surface2`, border-radius `12`, boxShadow `Colors.black26 blurRadius 6`

---

## 9. Files to Create / Modify

| File | Change |
|------|--------|
| `lib/models/player.dart` | Add `islandAttempts`, `deathCupHits` |
| `lib/models/user.dart` | Add `totalIslandAttempts`, `totalDeathCupHits` |
| `lib/models/game_statistics.dart` | Add `roundCount`, `cupsRemainingWinner`, `durationSeconds`, `gameMode`, `specialRules` |
| `lib/util/repositories/user_repository.dart` | Increment new User fields in `saveGame` |
| `lib/util/stats_helpers.dart` | **CREATE** — computed stat helper functions |
| `lib/screens/games/personal_statistics_screen.dart` | Expand grid, add chips row, career highlights |
| `lib/screens/games/performance_screen.dart` | Add rows to table, row accuracy chart, date labels |
| `lib/screens/games/breakdown_screen.dart` | **CREATE** — new Breakdown tab |
| `lib/screens/games/statistics_screen.dart` | Add 4th tab, history card improvements |
| `lib/screens/game/game_controller.dart` | Increment `islandAttempts`, `deathCupHits` |

---

*Plan authored: 2026-03-17*
