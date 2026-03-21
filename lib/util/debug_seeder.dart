import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/constants.dart';

/// Seeds the current user's Firestore document with realistic test data so
/// that the leveling, achievement, and cosmetic systems can be evaluated
/// without playing dozens of real games.
///
/// Call [DebugSeeder.seedUser] from a dev-only button or console.
/// Safe to call repeatedly — it always overwrites with the preset values.
class DebugSeeder {
  DebugSeeder._();

  /// Writes preset stats to [userId] in Firestore.
  ///
  /// The preset puts the user at **Level 14 (Cup Hunter tier)** with a spread
  /// of achievement stages across all categories, several unlocked titles, and
  /// the third avatar locked (requires level 6, satisfied).
  static Future<void> seedUser(String userId) async {
    final data = <String, dynamic>{
      // ── Identity ─────────────────────────────────────────────────────────
      'avatarKey': 'avatar_catpants', // unlocked at Lv 6 ✓
      'backgroundKey': '',
      'title': 'Sharpshooter',

      // ── XP / Level ───────────────────────────────────────────────────────
      // cumulativeXpForLevel(14) = 13*(100+25*12) = 13*400 = 5200
      // cumulativeXpForLevel(15) = 14*(100+25*13) = 14*425 = 5950
      // 5450 XP → Level 14, ~48% into the level
      'xp': 5450,

      // ── Win/loss record ───────────────────────────────────────────────────
      'wins': 38,
      'losses': 22,
      'currentWinStreak': 4,
      'bestWinStreak': 8,
      'perfectGames': 3,
      'nightGames': 18,

      // ── Throwing stats ────────────────────────────────────────────────────
      'totalScore': 420.0,
      'totalMisses': 180,
      'totalThrows': 600,
      'totalAirballs': 27,

      // ── Special moves ─────────────────────────────────────────────────────
      'onFire': 22,
      'totalHeatingUp': 58,
      'defended': 41,
      'hitLastCup': 9,
      'totalBounceMakes': 32,
      'totalBounceAttempts': 60,
      'totalIslandMakes': 11,
      'totalIslandAttempts': 18,
      'totalDeathCupHits': 3,

      // ── Cups hit count map ────────────────────────────────────────────────
      'cupsHitCount': {
        '0': 52, '1': 48, '2': 55, '3': 44, '4': 38,
        '5': 61, '6': 47, '7': 42, '8': 33, '9': 0,
      },

      // ── Social ───────────────────────────────────────────────────────────
      'friends': <String>[],

      // ── Unlocked titles ───────────────────────────────────────────────────
      'unlockedTitles': [
        'Sharpshooter', // cups_hit Bronze (50 cups ✓: 420)
        'On Fire',      // on_fire Bronze (5 times ✓: 22)
        'Bounce Artist',// bounce_makes Bronze (5 ✓: 32)
        'Victor',       // wins Bronze (10 ✓: 38)
        'Regular',      // games_played Bronze (10 ✓: 60)
        'Unstoppable',  // win_streak Bronze (3 ✓: 8)
        'Resilient',    // warrior Bronze (10 losses ✓: 22)
        'Warming Up',   // heating_up Bronze (10 ✓: 58)
        'The Wall',     // defended Bronze (5 ✓: 41)
        'Clutch',       // last_cup Bronze (1 ✓: 9)
      ],

      // ── Achievement stages ────────────────────────────────────────────────
      // Stage index: 0=locked, 1=Bronze, 2=Silver, 3=Gold, 4=Diamond
      'unlockedAchievementStages': {
        // Performance
        'cups_hit': 2,        // Silver (250 cups? no, 420 → Silver threshold 250 ✓)
        'on_fire': 1,         // Bronze (22 → Bronze 5 ✓, Silver needs 25 → close)
        'bounce_makes': 2,    // Silver (32 → Silver 25 ✓)
        'island_makes': 1,    // Bronze (11 → Bronze 3 ✓)
        'death_cups': 1,      // Bronze (3 → threshold 1 ✓)
        'defended': 2,        // Silver (41 → Silver 25 ✓)
        'last_cup': 1,        // Bronze (9 → Bronze 1 ✓)
        'heating_up': 2,      // Silver (58 → Silver 50 ✓)
        // Consistency
        'games_played': 2,    // Silver (60 games → Silver 50 ✓)
        'wins': 1,            // Bronze (38 → Bronze 10 ✓)
        'win_streak': 2,      // Silver (8 → Silver 5 ✓)
        'perfect_games': 1,   // Bronze (3 → Bronze 1 ✓)
        'night_games': 1,     // Bronze (18 → Bronze 5 ✓)
        // Accuracy — hit_rate: 420/600 = 70% → Gold threshold 70 ✓
        'hit_rate': 3,
        // bounce accuracy: 32/60 = 53% → Silver 55? No, 53 < 55 → Bronze 40 ✓
        'bounce_accuracy': 1,
        // island accuracy: 11/18 = 61% → Silver 55 ✓
        'island_accuracy': 2,
        // Social — no friends yet
        'friends_count': 0,
        // Fun
        'airballs': 1,        // Bronze (27 → Bronze 10 ✓)
        'warrior': 1,         // Bronze (22 losses → Bronze 10 ✓)
      },

      // ── Metadata ─────────────────────────────────────────────────────────
      'usernameLower': '', // will be overwritten on next real save
      'lastGameAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(userId)
        .update(data);
  }
}
