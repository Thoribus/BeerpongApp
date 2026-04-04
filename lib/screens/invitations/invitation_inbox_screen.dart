import 'dart:async';

import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/constants/routes.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Shows all pending invitations for the signed-in user.
/// Tapping Accept navigates to WaitingForGameScreen; Decline sets the status
/// and returns the user to this screen (the StreamBuilder auto-removes the card).
class InvitationInboxScreen extends StatelessWidget {
  const InvitationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(context.loc.invitationsTitle, style: TextStyle(color: c.onBackground)),
        iconTheme: IconThemeData(color: c.onBackground),
      ),
      body: user == null
          ? Center(child: Text(context.loc.invitationsNotSignedIn, style: TextStyle(color: c.subtle)))
          : StreamBuilder<List<Invitation>>(
              stream: FirestoreService.instance.pendingInvitationsStream(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final invitations = snapshot.data ?? [];
                if (invitations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mail_outline, size: 64, color: c.subtle),
                        const SizedBox(height: 16),
                        Text(
                          context.loc.invitationsNoPending,
                          style: TextStyle(color: c.subtle, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: invitations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _InvitationCard(invitation: invitations[index]),
                );
              },
            ),
    );
  }
}

class _InvitationCard extends StatefulWidget {
  final Invitation invitation;
  const _InvitationCard({required this.invitation});

  @override
  State<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends State<_InvitationCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    // Fire status update without awaiting — awaiting it causes the stream to
    // update, which removes this card from the list and unmounts the widget
    // before navigation can happen.
    unawaited(FirestoreService.instance.updateInvitationStatus(
      widget.invitation.id,
      InvitationStatus.accepted.name,
    ));
    if (!mounted) return;
    context.go(
      AppRoutes.spectateLobbyPath(widget.invitation.gameId),
      extra: widget.invitation.id,
    );
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    await FirestoreService.instance.updateInvitationStatus(
      widget.invitation.id,
      InvitationStatus.declined.name,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.loc.invitationsDeclined)));
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
    final c = AppColors.of(context);
    final isTournament = inv.gameType == GameType.tournament;
    final badgeLabel = isTournament ? context.loc.labelTournament : context.loc.gameLoadingTitle;
    final senderName =
        inv.fromUsername.isNotEmpty ? inv.fromUsername : context.loc.invitationsFromPlayer;

    return Card(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.person, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: c.onBackground,
                        ),
                      ),
                      Text(
                        isTournament ? context.loc.invitationsInvitedToTournament : context.loc.invitationsInvitedToGame,
                        style: TextStyle(color: c.subtle, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _decline,
                      child: Text(context.loc.invitationsDeclineBtn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _accept,
                      child: Text(context.loc.invitationsAcceptBtn),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
