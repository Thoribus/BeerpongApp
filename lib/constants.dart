import 'package:beerpongapp/theme.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // ── UI colours ──────────────────────────────────────────────────────────────
  static const Color primaryColor = Colors.amber;
  static const Color secondaryColor = Colors.black;
  static const Color unselectedColor = Colors.grey;
  static const Color teamOneColor = Colors.blue;
  static const Color teamTwoColor = Colors.red;

  // ── App background / surface colours ────────────────────────────────────────
  static const Color bgDark = AppTheme.backgroundDark;
  static const Color surfaceDark = AppTheme.surfaceDark;
  static const Color borderDark = AppTheme.surfaceDark2;

  // ── Game rules ───────────────────────────────────────────────────────────────
  /// Number of cups per team at the start of a standard game.
  static const int cupsPerTeam = 10;

  /// Consecutive hits required to trigger the "On Fire" bonus.
  static const int onFireThreshold = 3;

  /// Cups remaining on the table at or below which a team may rearrange.
  static const int rearrangeMaxCups = 6;

  /// The cup index that is treated as the "Bitch Cup" centre cup.
  static const int bitchCupIndex = 4;

  /// Proximity threshold (logical pixels) for adjacency detection.
  static const double proximityThreshold = 100.0;

  /// Airball milestone — every Nth airball triggers a group drink.
  static const int airballMilestone = 3;

  // ── Achievements ─────────────────────────────────────────────────────────────
  static const int maxAchievements = 50;

  // ── Firestore collection names ───────────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colGames = 'games';
  static const String colEvents = 'events';
  static const String colInvitations = 'invitations';
  static const String colTournaments = 'tournaments';
  static const String colMatches = 'matches';

  // ── SharedPreferences keys ───────────────────────────────────────────────────
  static const String prefGameState = 'currentGameState';

  // ── Background keys ──────────────────────────────────────────────────────────
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
    'bg_blue':    6,   // Party Starter
    'bg_green':   11,  // Cup Hunter
    'bg_purple':  16,  // Table Regular
    'bg_dark':    21,  // Foam Roller
  };

  // ── Avatar asset keys ────────────────────────────────────────────────────────
  static const List<String> avatarKeys = [
    'avatar_aggroracoon',
    'avatar_catbeer',
    'avatar_catpants',
    'avatar_cheering',
    'avatar_cupbeer',
    'avatar_frogisland',
  ];

  /// Minimum level required to equip each avatar.
  /// Avatars not listed here are free (level 1).
  static const Map<String, int> avatarLevelRequirements = {
    'avatar_aggroracoon': 1,
    'avatar_catbeer': 1,
    'avatar_catpants': 6,   // Party Starter
    'avatar_cheering': 11,  // Cup Hunter
    'avatar_cupbeer': 16,   // Table Regular
    'avatar_frogisland': 26, // Bounce Artist
  };
}

/// Programmatic gradient backgrounds for the user card.
///
/// `bg_default` is handled specially in [UserCard] — it renders the SVG asset
/// instead of this gradient, so the value here is never actually used for it.
abstract final class AppBackgrounds {
  static LinearGradient gradientFor(String key) => switch (key) {
        'bg_amber' => const LinearGradient(
            colors: [Color(0xFFB45309), Color(0xFF78350F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        'bg_blue' => const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF1E3A5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        'bg_green' => const LinearGradient(
            colors: [Color(0xFF15803D), Color(0xFF14532D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        'bg_purple' => const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        'bg_dark' => const LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        _ /* bg_default */ => const LinearGradient(
            colors: [Color(0xFF374151), Color(0xFF1F2937)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
      };

  static String labelFor(String key) => switch (key) {
        'bg_amber'  => 'Amber',
        'bg_blue'   => 'Blue',
        'bg_green'  => 'Green',
        'bg_purple' => 'Purple',
        'bg_dark'   => 'Dark',
        _           => 'Default',
      };
}
