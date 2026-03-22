import 'dart:async';

import 'package:beerpongapp/constants/routes.dart';
import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:go_router/go_router.dart';

/// Shown after the recipient accepts an invitation.
///
/// Displays the host's current lobby setup (teams, rules, starting team) in
/// read-only mode and auto-navigates to [LiveGameStatsScreen] the moment the
/// host starts the game.
class ReadOnlyLobbyScreen extends StatefulWidget {
  final String gameId;

  /// Provided when arriving via the accept flow so the spectator can cancel.
  final String? invitationId;

  const ReadOnlyLobbyScreen({
    super.key,
    required this.gameId,
    this.invitationId,
  });

  @override
  State<ReadOnlyLobbyScreen> createState() => _ReadOnlyLobbyScreenState();
}

class _ReadOnlyLobbyScreenState extends State<ReadOnlyLobbyScreen> {
  bool _navigated = false;
  bool _cancelling = false;

  Future<void> _cancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    if (widget.invitationId != null) {
      await FirestoreService.instance.updateInvitationStatus(
        widget.invitationId!,
        InvitationStatus.cancelled.name,
      );
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return StreamBuilder(
      stream: FirestoreService.instance.getGameDocStream(widget.gameId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: c.background,
            appBar: AppBar(
              backgroundColor: c.surface,
              title: Text('Lobby', style: TextStyle(color: c.onBackground)),
            ),
            body: Center(
              child:
                  Text('Error loading game.', style: TextStyle(color: c.subtle)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: c.background,
            appBar: AppBar(
              backgroundColor: c.surface,
              title: Text('Lobby', style: TextStyle(color: c.onBackground)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final started = data['started'] == true;

        if (started && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.pushReplacement(AppRoutes.spectateLivePath(widget.gameId));
            }
          });
        }

        final team1 = Team.fromJson(data['team1'] ?? {});
        final team2 = Team.fromJson(data['team2'] ?? {});
        final gameMode = data['gameMode'] as String? ?? 'Unknown Mode';
        final rulesList = (data['specialRules'] as List?) ?? [];
        final startingTeam = data['startingTeam'] as String? ?? 'Team Blue';

        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            backgroundColor: c.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text('Game Lobby', style: TextStyle(color: c.onBackground)),
            actions: [
              TextButton(
                onPressed: _cancelling ? null : _cancel,
                child: Text(
                  'Leave',
                  style: TextStyle(
                    color: _cancelling ? c.subtle : Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTeamPanel(c, 'Team Blue', team1, Colors.blue.shade400),
                const SizedBox(height: 12),
                _buildTeamPanel(c, 'Team Red', team2, Colors.red.shade400),
                const SizedBox(height: 12),
                _buildGameSettings(c, gameMode, rulesList, startingTeam),
                const SizedBox(height: 24),
                _buildWaitingIndicator(c),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamPanel(AppColors c, String title, Team team, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          if (team.players.isEmpty)
            Text('No players yet',
                style: TextStyle(color: c.subtle, fontSize: 13))
          else
            ...team.players.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: c.subtle, size: 18),
                    const SizedBox(width: 8),
                    Text(p.name,
                        style: TextStyle(color: c.onBackground, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameSettings(
      AppColors c, String mode, List rules, String starting) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: c.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          _settingsRow(c, Icons.sports_bar_outlined, 'Mode', mode),
          if (rules.isNotEmpty) ...[
            const SizedBox(height: 8),
            _settingsRow(
              c,
              Icons.rule_outlined,
              'Rules',
              rules.join(', '),
            ),
          ],
          const SizedBox(height: 8),
          _settingsRow(c, Icons.flag_outlined, 'Starting Team', starting),
        ],
      ),
    );
  }

  Widget _settingsRow(AppColors c, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: c.subtle, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: c.subtle, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: c.onBackground, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingIndicator(AppColors c) {
    return Column(
      children: [
        const CircularProgressIndicator(color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          'Waiting for the host to start the game…',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.subtle, fontSize: 14),
        ),
      ],
    );
  }
}
