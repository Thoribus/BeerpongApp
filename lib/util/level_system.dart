import 'package:flutter/material.dart';

/// Pure utility — no Firestore, no widgets.
/// All methods are static and compute-only.
///
/// XP formula: `xpRequiredForLevel(n) = 100 + (n − 2) × 50` for n ≥ 2.
/// This gives a gentle linear ramp:
///   Level  2 →   100 XP per step  (cumulative    100)
///   Level 10 →   500 XP per step  (cumulative  2,700)
///   Level 25 → 1,250 XP per step  (cumulative 18,600)
///   Level 50 → 2,500 XP per step  (cumulative 63,700)
///
/// At ~130 XP per average game this places Level 10 at ~21 games,
/// Level 30 at ~200 games, and Level 50 at ~490 games.
class LevelSystem {
  LevelSystem._();

  static const int maxLevel = 50;

  // ---------------------------------------------------------------------------
  // Core formulas
  // ---------------------------------------------------------------------------

  /// XP needed to advance from level [n-1] to level [n].
  static int xpRequiredForLevel(int n) {
    if (n <= 1) return 0;
    return 100 + (n - 2) * 50;
  }

  /// Total XP to reach [level] from the very start.
  ///
  /// Closed form: `(level − 1) × (100 + 25 × (level − 2))`
  static int cumulativeXpForLevel(int level) {
    if (level <= 1) return 0;
    return (level - 1) * (100 + 25 * (level - 2));
  }

  /// Current level derived from cumulative [xp].
  static int levelFromXp(int xp) {
    if (xp <= 0) return 1;
    int level = 1;
    while (level < maxLevel && cumulativeXpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  /// Progress within the current level as 0.0–1.0.
  static double progressInLevel(int xp) {
    final level = levelFromXp(xp);
    if (level >= maxLevel) return 1.0;
    final base = cumulativeXpForLevel(level);
    final next = cumulativeXpForLevel(level + 1);
    if (next <= base) return 1.0;
    return ((xp - base) / (next - base)).clamp(0.0, 1.0);
  }

  /// XP remaining until the next level-up.
  static int xpToNextLevel(int xp) {
    final level = levelFromXp(xp);
    if (level >= maxLevel) return 0;
    return cumulativeXpForLevel(level + 1) - xp;
  }

  // ---------------------------------------------------------------------------
  // Tier
  // ---------------------------------------------------------------------------

  static LevelTier tierForLevel(int level) {
    if (level >= 46) return LevelTier.pongLegend;
    if (level >= 41) return LevelTier.islandMaster;
    if (level >= 36) return LevelTier.pongVeteran;
    if (level >= 31) return LevelTier.deathCupDealer;
    if (level >= 26) return LevelTier.bounceArtist;
    if (level >= 21) return LevelTier.foamRoller;
    if (level >= 16) return LevelTier.tableRegular;
    if (level >= 11) return LevelTier.cupHunter;
    if (level >= 6) return LevelTier.partyStarter;
    return LevelTier.benchWarmer;
  }

  // ---------------------------------------------------------------------------
  // XP award
  // ---------------------------------------------------------------------------

  /// Stars earned for one game result. Mirrors [calculateXpGained] in structure.
  ///
  /// Typical range: 25–80 ⭐, so a 100-star shop item takes ~2–5 games.
  static int calculateStarsGained({
    required bool isWinner,
    required int cupsHit,
    required int onFire,
    required int bounceMakes,
    required int islandMakes,
    required int deathCupHits,
    required bool hitLastCup,
  }) {
    int stars = 10; // participation
    if (isWinner) stars += 20;
    stars += cupsHit * 2;
    stars += onFire * 5;
    stars += bounceMakes * 8;
    stars += islandMakes * 10;
    stars += deathCupHits * 15;
    if (hitLastCup) stars += 30;
    return stars;
  }

  /// XP earned for one game result.
  static int calculateXpGained({
    required bool isWinner,
    required int cupsHit,
    required int onFire,
    required int bounceMakes,
    required int islandMakes,
    required int deathCupHits,
    required int defended,
    required bool hitLastCup,
    required int newStreak,
  }) {
    int xp = 30; // participation
    if (isWinner) xp += 80;
    xp += cupsHit * 5;
    xp += onFire * 25;
    xp += bounceMakes * 15;
    xp += islandMakes * 20;
    xp += deathCupHits * 30;
    xp += defended * 10;
    if (hitLastCup) xp += 50;
    if (isWinner && newStreak >= 3) xp += (newStreak - 2) * 20;
    return xp;
  }
}

// ---------------------------------------------------------------------------
// Tier definitions
// ---------------------------------------------------------------------------

enum LevelTier {
  benchWarmer('Bench Warmer', Color(0xFF9E9E9E)),
  partyStarter('Party Starter', Color(0xFF4CAF50)),
  cupHunter('Cup Hunter', Color(0xFF2196F3)),
  tableRegular('Table Regular', Color(0xFF9C27B0)),
  foamRoller('Foam Roller', Color(0xFF009688)),
  bounceArtist('Bounce Artist', Color(0xFFFF9800)),
  deathCupDealer('Death Cup Dealer', Color(0xFFF44336)),
  pongVeteran('Pong Veteran', Color(0xFFFFD700)),
  islandMaster('Island Master', Color(0xFF00BCD4)),
  pongLegend('Pong Legend', Color(0xFFFF8C00));

  const LevelTier(this.displayName, this.color);

  final String displayName;
  final Color color;
}
