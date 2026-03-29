# Account Screen — Leveling & Achievement Overhaul Plan

## Current State Audit

### What Works
- **Customize tab** — avatar picker, title picker, username editor — solid, keep as-is.

### What's Broken / Incomplete

| Problem | Location |
|---------|----------|
| "Level" = `user.unlockedTitles.length` — arbitrary, not meaningful | `achievements_screen.dart:297` |
| Progress bar = achievements completed / total — confusing and flat | `achievements_screen.dart:299` |
| Only 5 achievements, 3 of which have wrong/repeated stage values | `getAchievements()` |
| "Losses" and "Misses" achievements punish bad play — bad design | `getAchievements()` |
| Activity tab duplicates Friends → Social feed entirely | `account_screen.dart:70` |
| Emblems row shows hardcoded dummy icons | `achievements_screen.dart:396` |
| Titles list is a static fallback `['Beginner', 'Pro Player', 'Champion']` | `custom_user_screen.dart:64` |

### Stats Available in `User` Model (All Tracked Today)
```
wins, losses
totalScore          — cups hit (double, used as int-ish)
totalThrows
totalMisses, totalAirballs
onFire              — times 3-consecutive-hit streak triggered
totalHeatingUp      — times 2-consecutive reached
defended            — cups defended
hitLastCup          — times player sank the game-winning cup
cupsHitCount        — map<cupIndex, count> for heatmap
totalBounceAttempts, totalBounceMakes
totalIslandAttempts, totalIslandMakes
totalDeathCupHits
friends[]           — friend count
unlockedTitles[]
lastGameAt
```

### Stats Missing (Needed for Richer System)
| Field | Why It's Needed |
|-------|----------------|
| `xp: int` | The XP currency for leveling |
| `currentWinStreak: int` | Streak achievements, leaderboard metric |
| `bestWinStreak: int` | Historical best streak |
| `tournamentsPlayed: int` | Tournament achievements |
| `tournamentsWon: int` | Tournament champion achievement |
| `perfectGames: int` | 0-miss game achievement |
| `comebackWins: int` | Win when down 3+ cups at some point |
| `gamesWithFriends: int` | Social gaming metric |

---

## Part 1 — Leveling System

### Design Choice: XP-Based with Tier Labels

An XP system is recommended over "level = achievement count" because:
- Every game contributes progress (retention driver even after losses)
- Transparent to players — they see exactly what they earned and why
- Scales independently from achievements — achievements become bonus XP on top
- Easy to tune thresholds post-launch

### XP Sources

| Action | XP Awarded |
|--------|-----------|
| Game played (any outcome) | +30 |
| Win | +80 |
| Cup hit | +5 each |
| On Fire triggered | +25 each |
| Bounce make | +15 each |
| Island make | +20 each |
| Death cup triggered | +30 each |
| Cup defended | +10 each |
| Hit the winning cup (last cup) | +50 bonus |
| Win streak bonus (≥3) | +(streak − 2) × 20 |
| Achievement stage unlocked (Bronze) | +50 |
| Achievement stage unlocked (Silver) | +100 |
| Achievement stage unlocked (Gold) | +200 |
| Achievement stage unlocked (Diamond) | +400 |

**Typical per-game XP:**
- Average win (10 cups, 1 On Fire): 30 + 80 + 50 + 25 = 185 XP
- Average loss (6 cups): 30 + 30 = 60 XP
- 3-game streak win: +40 bonus XP on top

### Level Curve

Formula: `xpRequiredForLevel(n) = 150 * n^1.6` (rounded to nearest 50)

| Level | XP to reach | Cumulative XP | At ~150 XP/game |
|-------|-------------|---------------|-----------------|
| 2 | 300 | 300 | ~2 games |
| 5 | 1,250 | 3,800 | ~25 games |
| 10 | 3,800 | 18,000 | ~120 games |
| 20 | 11,000 | 90,000 | ~600 games |
| 35 | 27,000 | 350,000 | ~2,300 games |
| 50 | 55,000 | 900,000 | ~6,000 games |

Level 10 in ~30 dedicated nights of 4 games. Level 50 is a true "lifetime" milestone.

### Level Tiers (Beer-Pong Themed)

| Levels | Tier Name | Badge Color | Unlocks |
|--------|-----------|-------------|---------|
| 1–5 | Bench Warmer | Grey | Starting titles |
| 6–10 | Party Starter | Green | 2 extra avatar choices |
| 11–15 | Cup Hunter | Blue | Blue title glow |
| 16–20 | Table Regular | Purple | Purple badge |
| 21–25 | Foam Roller | Teal | Foam Roller title |
| 26–30 | Bounce Artist | Orange | Orange level frame |
| 31–35 | Death Cup Dealer | Deep Red | Animated badge |
| 36–40 | Pong Veteran | Gold | Gold badge + frame |
| 41–45 | Island Master | Diamond/Cyan | Diamond badge |
| 46–50 | Pong Legend | Gradient (gold→orange) | Legendary animated badge |

### `LevelSystem` Utility Class (pure Dart, no Firebase)

```dart
class LevelSystem {
  /// XP required to *reach* [level] from level 1.
  static int cumulativeXpForLevel(int level) {
    if (level <= 1) return 0;
    int total = 0;
    for (int n = 2; n <= level; n++) {
      total += xpRequiredForLevel(n);
    }
    return total;
  }

  /// XP needed to advance from level [n-1] to level [n].
  static int xpRequiredForLevel(int n) {
    if (n <= 1) return 0;
    return ((150 * pow(n, 1.6)) / 50).round() * 50;
  }

  /// Current level given cumulative [xp].
  static int levelFromXp(int xp) {
    int level = 1;
    while (cumulativeXpForLevel(level + 1) <= xp) level++;
    return level;
  }

  /// Progress (0.0–1.0) within the current level.
  static double progressInLevel(int xp) {
    final level = levelFromXp(xp);
    final base = cumulativeXpForLevel(level);
    final next = cumulativeXpForLevel(level + 1);
    return ((xp - base) / (next - base)).clamp(0.0, 1.0);
  }

  /// XP remaining until next level-up.
  static int xpToNextLevel(int xp) {
    final level = levelFromXp(xp);
    return cumulativeXpForLevel(level + 1) - xp;
  }

  static String tierName(int level) { /* lookup table above */ }
  static Color tierColor(int level) { /* lookup table above */ }
}
```

### XP Calculation in `UserRepository.saveGame()`

```dart
int _calculateXpGained(Player player, bool won, int newStreak) {
  int xp = 30; // participation
  if (won) xp += 80;
  xp += player.score.toInt() * 5;
  xp += player.onFire * 25;
  xp += player.bounceMakes * 15;
  xp += player.islandMakes * 20;
  xp += player.deathCupHits * 30;
  xp += player.defended * 10;
  if (player.lastCupHit) xp += 50;
  if (won && newStreak >= 3) xp += (newStreak - 2) * 20;
  return xp;
}
```

---

## Part 2 — Achievement System

### Redesign Principles
1. **No negative achievements** — remove "Losses" and "Misses" as standalone categories (can keep as hidden/ironic badges if desired, but not primary)
2. **Category grouping** — achievements grouped by theme so the grid isn't a flat dump
3. **Typed model** — replace `Map<String, Object>` with a proper `Achievement` class
4. **Locked state visible** — show locked achievements as greyed silhouettes so players know what to aim for
5. **Achievement = XP bonus** — each stage unlock awards XP (see above)

### Achievement Model

```dart
class AchievementDef {
  final String id;           // stable key
  final String title;        // display name
  final String description;  // "Sink X cups in total"
  final String imagePath;    // asset path
  final AchievementCategory category;
  final List<int> thresholds;  // e.g. [25, 100, 250, 500]
  final List<String> stageNames; // e.g. ['Bronze', 'Silver', 'Gold', 'Diamond']
  final String? titleToGrant;  // title unlocked at first stage
  final int Function(User) valueGetter; // how to extract progress from User
}
```

### Full Achievement Catalogue (26 achievements)

#### Category: Performance
| ID | Title | Description | Thresholds | Grants Title |
|----|-------|-------------|------------|--------------|
| `cups_hit` | Sniper | Sink N cups total | 50 / 250 / 750 / 2000 | "Sharpshooter" |
| `on_fire` | Pyromaniac | Trigger On Fire N times | 5 / 25 / 100 / 300 | "On Fire" |
| `bounce_makes` | Bounce King | Sink N cups via bounce | 5 / 25 / 75 / 200 | "Bounce Artist" |
| `island_makes` | Island Ruler | Hit N island shots | 3 / 15 / 50 / 100 | "Island Master" |
| `death_cups` | Grim Reaper | Trigger N death cups | 1 / 5 / 20 / 50 | "Death Bringer" |
| `defended` | Guardian | Defend N cups | 5 / 25 / 100 / 250 | "The Wall" |
| `last_cup` | Closer | Sink the final cup N times | 1 / 10 / 30 / 75 | "Clutch" |
| `heating_up` | Heating Up | Reach 2-in-a-row N times | 10 / 50 / 200 / 500 | "Warming Up" |

#### Category: Consistency / Volume
| ID | Title | Description | Thresholds | Grants Title |
|----|-------|-------------|------------|--------------|
| `games_played` | Veteran | Play N games | 10 / 50 / 150 / 500 | "Regular" |
| `wins` | Winner | Win N games | 10 / 50 / 150 / 400 | "Victor" |
| `win_streak` | On a Roll | Reach a N-game win streak | 3 / 5 / 10 / 15 | "Unstoppable" |
| `tournaments_played` | Competitor | Enter N tournaments | 1 / 5 / 15 / 30 | "Contender" |
| `tournaments_won` | Champion | Win N tournaments | 1 / 3 / 10 / 25 | "Tournament King" |
| `perfect_games` | Perfection | Finish a game with 0 misses | 1 / 5 / 20 / 50 | "Flawless" |
| `comeback_wins` | Comeback Kid | Win from ≥3 cups down | 1 / 5 / 20 / 50 | "Never Give Up" |

#### Category: Accuracy (rate-based, min. 20 games required)
| ID | Title | Description | Thresholds | Grants Title |
|----|-------|-------------|------------|--------------|
| `hit_rate_60` | Sharp Eye | Maintain 60% hit rate (20+ games) | Milestone badge, single stage | "Sharpshooter" |
| `hit_rate_70` | Laser Focus | Maintain 70% hit rate (20+ games) | Milestone badge, single stage | "Laser" |
| `bounce_accuracy` | Trick Shot | 70%+ bounce accuracy (10+ attempts) | Single stage | "Trick Artist" |
| `island_accuracy` | Island Precision | 60%+ island accuracy (5+ attempts) | Single stage | "Island Ace" |

*Note: Rate-based achievements are single-stage badges awarded once the threshold is first crossed, not multi-tier progressions.*

#### Category: Social
| ID | Title | Description | Thresholds | Grants Title |
|----|-------|-------------|------------|--------------|
| `friends_count` | Social Butterfly | Add N friends | 3 / 10 / 25 / 50 | "Social Butterfly" |
| `challenges_sent` | Challenger | Send N challenges | 5 / 25 / 75 / 150 | "Instigator" |
| `games_with_friends` | Team Player | Play N games with app friends | 5 / 25 / 75 / 200 | "Good Sport" |

#### Category: Quirky / Fun
| ID | Title | Description | Thresholds | Grants Title |
|----|-------|-------------|------------|--------------|
| `airballs` | Airball Artist | Throw N airballs (ironic) | 10 / 50 / 150 / 300 | "Air Guitarist" |
| `night_games` | Night Owl | Play N games after 11 PM | 5 / 20 / 50 / 100 | "Vampire" |
| `total_losses` | Warrior | Lose N games with dignity | 10 / 50 / 150 / 300 | "Resilient" |

*Note: "Warrior" reframes losses as persistence rather than failure.*

### Stage Colors (renamed for clarity)

| Stage | Current Name | Proposed | Color |
|-------|-------------|----------|-------|
| 1 | Bronze | Bronze | `Colors.brown` |
| 2 | Silver | Silver | `Colors.blueGrey.shade400` |
| 3 | Amber | Gold | `Colors.amber` |
| 4 | Violet | Diamond | `Colors.cyan.shade300` |

### Achievement Grid Layout

Replace the flat 3-column grid with **category sections**, each collapsible:
```
▼ Performance        (8 achievements, 3/8 unlocked)
  [Sniper] [Pyromaniac] [Bounce King] ...

▼ Consistency        (7 achievements, 1/7 unlocked)
  [Veteran] [Winner] ...

▶ Accuracy           (4 achievements, locked)
  [???] [???] [???] [???]   ← greyed silhouettes

▶ Social             (3 achievements, 0/3 unlocked)
▶ Fun                (3 achievements, 1/3 unlocked)
```

---

## Part 3 — Account Screen Structure

### Tab Proposal: Drop "Activity", Keep 2 Tabs

The Activity tab duplicates Friends → Social exactly. Remove it. Replace with a **"Progress"** tab that shows things the Social tab can't:

| Tab | Content |
|-----|---------|
| **Customize** | Current implementation (avatar, username, title) |
| **Achievements** | Overhauled achievement grid with categories + locked states |
| **Progress** | XP/level progress, recent unlocks, streak, stat highlights |

Alternatively: keep 2 tabs only (Customize + Achievements) and embed the level card inside Achievements as the header (as it is now, but with real data).

**Recommendation: 3 tabs, replace Activity → Progress.**

### Progress Tab Content

```
┌──────────────────────────────────────┐
│  Level 14 · Bounce Artist            │
│  ████████████░░░░  3,240 / 4,500 XP  │
│  "1,260 XP to Level 15"              │
└──────────────────────────────────────┘

Recently Unlocked
  🏅 Bounce King · Silver  (+100 XP)  2 days ago
  🏅 Closer · Bronze       (+50 XP)   5 days ago

Highlights
  🔥 Current win streak: 4
  🏆 Best win streak: 8
  🎯 Hit rate: 63.2%  (top 20% of friends)
  ⚡ On Fire count: 47

Next to Unlock (closest to threshold)
  [Veteran] Silver — 89 / 100 games · 11 to go
  [Bounce King] Gold — 63 / 75 makes · 12 to go
```

---

## Part 4 — Data Model Changes

### `User` additions needed

```dart
// Add to User:
int xp = 0;
int currentWinStreak = 0;
int bestWinStreak = 0;
int tournamentsPlayed = 0;
int tournamentsWon = 0;
int perfectGames = 0;
int comebackWins = 0;
int challengesSent = 0;
int gamesWithFriends = 0;
int nightGames = 0;         // games after 23:00 local time
```

All of these are write-once-per-game increments. No structural Firestore change needed — new fields default to 0 via `json['field'] ?? 0` in `fromJson`.

### `UserRepository.saveGame()` additions

```dart
// After existing stat accumulation:
final xpGained = _calculateXpGained(player, isWinner, newStreak);
batch.update(userRef, {
  'xp': FieldValue.increment(xpGained),
  'currentWinStreak': isWinner ? FieldValue.increment(1) : 0,
  'bestWinStreak': FieldValue.increment(0), // handled separately with conditional
  // ... other new fields
});
```

**Important:** `bestWinStreak` requires a read-before-write (compare current value). Use a Firestore transaction, not a batch. Since `saveGame` already uses a transaction for the score updates, this fits naturally.

### New `Firestore` index needed

None — all achievement computation is client-side from the `User` document.

---

## Part 5 — Implementation Phases

### Phase A — Data Foundation (pre-requisite, ~1 session)
1. Add new fields to `User` model (`xp`, `currentWinStreak`, `bestWinStreak`, `tournamentsPlayed`, `tournamentsWon`, `perfectGames`, `comebackWins`, `challengesSent`, `nightGames`)
2. Update `toJson()`, `fromJson()`, `copyWith()` for all new fields
3. Update `UserRepository.saveGame()` to calculate and write `xp` and `currentWinStreak`/`bestWinStreak`
4. Create `lib/util/level_system.dart` — pure `LevelSystem` utility (no Firebase)

### Phase B — Achievement Engine (1 session)
1. Create `lib/models/achievement_def.dart` — typed `AchievementDef` + `AchievementCategory` enum
2. Create `lib/util/achievement_engine.dart` — `AchievementEngine.evaluate(User)` returns progress list
3. Replace `AchievementsScreen.getAchievements()` with `AchievementEngine.evaluate()`
4. Replace `AchievementsScreen.getUpgradedAchivements()` with diff-based engine call
5. Wire XP bonus on stage unlock into `UserRepository.saveGame()`

### Phase C — Account Screen UI (1 session)
1. Remove Activity tab from `account_screen.dart`
2. Add Progress tab with XP card, recent unlocks, stat highlights, next-to-unlock list
3. Overhaul `AchievementsScreen`: category sections, locked silhouettes, fix level badge to use `LevelSystem.levelFromXp(user.xp)`
4. Fix progress bar to show XP progress within level (not achievements/total)
5. Replace dummy emblems row with real unlocked-title count + tier badge

### Phase D — Cosmetic Rewards (optional, later)
1. Lock certain avatar options behind level thresholds
2. Add colored level frame to `UserCard` based on tier
3. Show tier name next to level badge ("Lv 14 · Bounce Artist")

---

## Key Design Constraints

- **No server-side computation** — all XP and achievement evaluation happens client-side at game-end, stored as plain integers in the User document. Avoids Cloud Functions complexity.
- **Backwards compatible** — all new fields default to `0` / `null`. Existing users start at XP 0, Level 1. Their historical stats still feed into achievements from day one (cups, wins etc. are already accumulated).
- **XP is append-only** — never subtract XP. If a threshold changes in a future update, old XP totals are preserved.
- **Achievements are idempotent** — `AchievementEngine.evaluate()` is a pure function over User state. No separate "unlocked" flags needed in Firestore for multi-tier achievements — stage is always derived from current stat value vs. threshold.
- **Rate-based achievements** require minimum game count to prevent day-1 perfect-rate abuse. Enforce: `(wins + losses) >= 20` before evaluating hit-rate badges.
