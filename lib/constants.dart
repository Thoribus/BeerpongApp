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

  // ── Avatar asset keys ────────────────────────────────────────────────────────
  static const List<String> avatarKeys = [
    'avatar_aggroracoon',
    'avatar_catbeer',
    'avatar_catpants',
    'avatar_cheering',
    'avatar_cupbeer',
    'avatar_frogisland',
  ];
}
