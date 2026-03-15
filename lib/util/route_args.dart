import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:flutter/material.dart';

/// Route arguments for GameModeDetailsScreen and TournamentLobbyScreen.
/// Both screens share identical constructor params.
class GameModeArgs {
  final String title;
  final String subtitle;
  final String details;
  final String iconPath;
  final Color color;

  const GameModeArgs({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.iconPath,
    required this.color,
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
