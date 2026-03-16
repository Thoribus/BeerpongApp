import 'dart:async';

import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/route_args.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown after the recipient accepts an invitation.
/// Watches the game doc in real time; navigates to GameScreen the moment
/// the host starts the game (started == true).
class WaitingForGameScreen extends StatefulWidget {
  final Invitation invitation;
  const WaitingForGameScreen({super.key, required this.invitation});

  @override
  State<WaitingForGameScreen> createState() => _WaitingForGameScreenState();
}

class _WaitingForGameScreenState extends State<WaitingForGameScreen> {
  StreamSubscription<DocumentSnapshot>? _gameSub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    if (widget.invitation.gameId.isNotEmpty) {
      _gameSub = FirestoreService.instance
          .getGameDocStream(widget.invitation.gameId)
          .listen(_handleGameDoc);
    }
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    super.dispose();
  }

  void _handleGameDoc(DocumentSnapshot snapshot) {
    if (_navigated || !mounted) return;
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>;
    final started = data['started'] as bool? ?? false;
    if (!started) return;
    _navigated = true;

    final team1 = Team.fromJson(data['team1'] as Map<String, dynamic>);
    final team2 = Team.fromJson(data['team2'] as Map<String, dynamic>);
    final rawRules = (data['specialRules'] as List<dynamic>?) ?? [];
    final selectedRules = <String, bool>{
      for (final r in rawRules) (r as String): true,
    };
    final startingTeamStr = data['startingTeam'] as String? ?? 'Team Blue';
    final invites = (data['invitations'] as List<dynamic>?)
            ?.map((i) => i as String)
            .toList() ??
        [];
    final tournamentId = data['tournamentId'] as String? ?? '';

    context.go(
      '/game',
      extra: GameArgs(
        id: widget.invitation.gameId,
        team1: team1,
        team2: team2,
        selectedRules: selectedRules,
        startingTeam: startingTeamStr == 'Team Blue',
        invitations: invites,
        tournamentId: tournamentId,
      ),
    );
  }

  Future<void> _cancel() async {
    await FirestoreService.instance.updateInvitationStatus(
      widget.invitation.id,
      InvitationStatus.cancelled.name,
    );
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final inv = widget.invitation;
    final hostName =
        inv.fromUsername.isNotEmpty ? inv.fromUsername : 'the host';

    // Tournament invites have no gameId at invite time — just show a waiting
    // screen until the host triggers Phase 4 routing.
    final bodyText = inv.gameId.isEmpty
        ? 'Waiting for $hostName to start the tournament…'
        : 'Waiting for $hostName to start the game…';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Waiting…', style: TextStyle(color: c.onBackground)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                bodyText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: c.onBackground),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.subtle,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
