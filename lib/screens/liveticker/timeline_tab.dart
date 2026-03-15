import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';

class TimelineTab extends StatelessWidget {
  final LiveGameData gameData;

  const TimelineTab({required this.gameData, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('games')
          .doc(gameData.gameId)
          .collection('events')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<GameEvent> events = snapshot.data!.docs
            .map((doc) =>
                GameEvent.fromJson(doc.data(), doc.id, gameData.gameId))
            .toList();

        return _buildGroupedEventList(events);
      },
    );
  }

  Widget _buildGroupedEventList(List<GameEvent> events) {
    Map<int, List<GameEvent>> grouped = {};

    for (var event in events) {
      int minute = event.timestamp.difference(gameData.gameStart).inMinutes;
      grouped.putIfAbsent(minute, () => []).add(event);
    }

    return ListView(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Text(
                "Minute ${entry.key.toString().padLeft(2, '0')}:00",
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ),
            ...entry.value.map((e) => _buildAnimatedEventRow(e)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedEventRow(GameEvent event) {
    final isTeam1 = event.team == '4294198070';
    Color eventColor = _getEventColor(event.eventType);
    IconData eventIcon = _getEventIcon(event.eventType);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: isTeam1
                  ? _buildHoverTile(event, eventColor, isTeam1: true)
                  : const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: Icon(eventIcon, color: eventColor),
              ),
            ),
            Expanded(
              child: !isTeam1
                  ? _buildHoverTile(event, eventColor, isTeam1: false)
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoverTile(GameEvent event, Color color,
      {required bool isTeam1}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: _buildEventTile(event, color, isTeam1: isTeam1),
    );
  }

  Widget _buildEventTile(GameEvent event, Color color,
      {required bool isTeam1}) {
    Duration eventDuration = event.timestamp.difference(gameData.gameStart);
    String eventTime =
        '${(eventDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(eventDuration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.only(
        left: isTeam1 ? 0 : 8,
        right: isTeam1 ? 8 : 0,
      ),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isTeam1 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Timestamp + EventType logic
          Row(
            mainAxisAlignment:
                isTeam1 ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: isTeam1
                ? [
                    Text(
                      event.eventType,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      eventTime,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ]
                : [
                    Text(
                      eventTime,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.eventType,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 4),
          Text(
            event.player ?? 'End Turn',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'Airball':
        return Colors.blue;
      case 'Bitchcup':
        return Colors.red;
      case 'Normal Hit':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'Airball':
        return BeerpongIcons.airball;
      case 'Bitchcup':
        return Icons.warning;
      case 'Normal Hit':
        return Icons.sports_bar;
      default:
        return Icons.sports;
    }
  }
}
