import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:flutter/material.dart';

/// Route arguments for GameModeDetailsScreen.
class GameModeArgs {
  final String title;
  final String subtitle;
  final String details;
  final String iconPath;
  final Color color;
  final bool isTournament;

  const GameModeArgs({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.iconPath,
    required this.color,
    this.isTournament = false,
  });
}

/// Route arguments for GameScreen.
class GameArgs {
  final String id;
  final Team team1;
  final Team team2;
  final Map<String, bool> selectedRules;
  final bool startingTeam;
  final List<String> invitations;
  final String tournamentId;

  const GameArgs({
    required this.id,
    required this.team1,
    required this.team2,
    required this.selectedRules,
    required this.startingTeam,
    required this.invitations,
    required this.tournamentId,
  });
}

/// Route arguments for TournamentPageView.
class TournamentPageViewArgs {
  final String tournamentId;
  final Tournament initialTournament;

  const TournamentPageViewArgs({
    required this.tournamentId,
    required this.initialTournament,
  });
}

/// Route arguments for ComparisonScreen.
class ComparisonArgs {
  final User currentUser;
  final User friend;

  const ComparisonArgs({required this.currentUser, required this.friend});
}

/// Route arguments for WaitingForGameScreen.
///
/// Can be built from a full [Invitation] (normal accept flow) or from just a
/// [gameId] + [hostName] when arriving via a [game_started] notification tap
/// (the app was in the background when the host started).
class WaitingArgs {
  final String gameId;
  final String hostName;

  /// Invitation document ID — null when opened from a game_started notification.
  final String? invitationId;

  const WaitingArgs({
    required this.gameId,
    required this.hostName,
    this.invitationId,
  });
}
