import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/localization_extensions.dart';

class TimelineTab extends StatefulWidget {
  final LiveGameData gameData;

  const TimelineTab({required this.gameData, super.key});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameData.gameId)
          .collection('events')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs
            .map((doc) =>
                GameEvent.fromJson(doc.data(), doc.id, widget.gameData.gameId))
            .toList();

        if (events.isEmpty) {
          return _buildEmptyState(context);
        }

        _scrollToBottom();
        return _buildEventList(context, events);
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_bar_outlined, size: 48, color: c.muted),
          const SizedBox(height: 12),
          Text(
            context.loc.liveTimelineNoEvents,
            style: TextStyle(color: c.subtle, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── List builder ───────────────────────────────────────────────────────────

  Widget _buildEventList(BuildContext context, List<GameEvent> events) {
    final items = <_TimelineItem>[];
    int? lastRound;

    for (final event in events) {
      if (event.eventType == 'End Turn') {
        items.add(_TimelineItem.divider(event));
        lastRound = null;
        continue;
      }

      // Insert a round header whenever the round number advances.
      final round = event.roundNumber;
      if (round != null && round != lastRound) {
        items.add(_TimelineItem.roundHeader(round));
        lastRound = round;
      }

      items.add(_TimelineItem.event(event));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return switch (item.type) {
          _ItemType.roundHeader => _buildRoundHeader(context, item.roundNumber!),
          _ItemType.divider => _buildTurnDivider(context, item.event!),
          _ItemType.event => _buildEventRow(context, item.event!),
        };
      },
    );
  }

  // ── Structural rows ────────────────────────────────────────────────────────

  Widget _buildRoundHeader(BuildContext context, int round) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: c.divider, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              context.loc.liveTimelineRound(round),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.subtle,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: c.divider, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildTurnDivider(BuildContext context, GameEvent event) {
    final c = AppColors.of(context);
    final duration = event.timestamp.difference(widget.gameData.gameStart);
    final mm = duration.inMinutes.toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: c.border,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              context.loc.liveTimelineEndOfTurn('$mm:$ss'),
              style: TextStyle(
                fontSize: 10,
                color: c.subtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: c.border,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Event row (left = team1, right = team2) ────────────────────────────────

  Widget _buildEventRow(BuildContext context, GameEvent event) {
    final c = AppColors.of(context);
    final isTeam1 =
        event.team == widget.gameData.team1.color.toARGB32().toString();
    final color = _eventColor(event.eventType);
    final icon = _eventIcon(event.eventType);

    final duration = event.timestamp.difference(widget.gameData.gameStart);
    final timeLabel =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    final tile = _buildEventTile(context, c, event, color, timeLabel, isTeam1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: isTeam1 ? tile : const SizedBox()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: c.surface2,
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          Expanded(child: !isTeam1 ? tile : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildEventTile(
    BuildContext context,
    AppColors c,
    GameEvent event,
    Color color,
    String timeLabel,
    bool isTeam1,
  ) {
    return Container(
      margin: EdgeInsets.only(
        left: isTeam1 ? 0 : 4,
        right: isTeam1 ? 4 : 0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment:
            isTeam1 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: isTeam1
                ? [
                    Text(
                      _eventLabel(context, event.eventType),
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeLabel,
                      style: TextStyle(fontSize: 10, color: c.subtle),
                    ),
                  ]
                : [
                    Text(
                      timeLabel,
                      style: TextStyle(fontSize: 10, color: c.subtle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _eventLabel(context, event.eventType),
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 2),
          Text(
            event.player ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c.onBackground,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Event metadata ─────────────────────────────────────────────────────────

  Color _eventColor(String type) => switch (type) {
        'Normal Hit' => Colors.green,
        'Bounce Shot' => Colors.teal,
        'Island Shot' => Colors.purple,
        'Death Cup' => Colors.deepOrange,
        'Airball' => Colors.blue,
        'Bitchcup' || 'Bitch Cup' => Colors.red,
        'On Fire' => Colors.orange,
        _ => Colors.grey,
      };

  IconData _eventIcon(String type) => switch (type) {
        'Normal Hit' => Icons.sports_bar,
        'Bounce Shot' => Icons.sports_volleyball,
        'Island Shot' => Icons.place,
        'Death Cup' => Icons.warning_amber_rounded,
        'Airball' => BeerpongIcons.airball,
        'Bitchcup' || 'Bitch Cup' => Icons.report,
        'On Fire' => Icons.local_fire_department,
        _ => Icons.sports,
      };

  String _eventLabel(BuildContext context, String type) => switch (type) {
        'Normal Hit' => context.loc.liveEventHit,
        'Bounce Shot' => context.loc.liveEventBounce,
        'Island Shot' => context.loc.liveEventIsland,
        'Death Cup' => context.loc.liveEventDeathCup,
        'Airball' => context.loc.liveEventAirball,
        'Bitchcup' || 'Bitch Cup' => context.loc.liveEventBitchCup,
        'On Fire' => context.loc.liveEventOnFire,
        _ => type,
      };
}

// ── Data helpers ───────────────────────────────────────────────────────────

enum _ItemType { roundHeader, divider, event }

class _TimelineItem {
  final _ItemType type;
  final GameEvent? event;
  final int? roundNumber;

  const _TimelineItem._({
    required this.type,
    this.event,
    this.roundNumber,
  });

  factory _TimelineItem.event(GameEvent e) =>
      _TimelineItem._(type: _ItemType.event, event: e);
  factory _TimelineItem.divider(GameEvent e) =>
      _TimelineItem._(type: _ItemType.divider, event: e);
  factory _TimelineItem.roundHeader(int n) =>
      _TimelineItem._(type: _ItemType.roundHeader, roundNumber: n);
}
