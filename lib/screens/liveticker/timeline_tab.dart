import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';

class TimelineTab extends StatelessWidget {
  final LiveGameData gameData;

  const TimelineTab({required this.gameData, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("games")
          .doc(gameData.gameId)
          .collection("events")
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

        return _buildEventList(events);
      },
    );
  }

  Widget _buildEventList(List<GameEvent> events) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isTeam1 = event.team == "4294198070";

        return _buildEventRow(event, isTeam1);
      },
    );
  }

  Widget _buildEventRow(GameEvent event, bool isTeam1) {
    Color eventColor = _getEventColor(event.eventType);
    IconData eventIcon = _getEventIcon(event.eventType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: isTeam1
                ? _buildPlayerInfo(event, eventColor)
                : const SizedBox(),
          ),
          Expanded(
            child: isTeam1 ? _buildTimestamp(event) : const SizedBox(),
          ),
          Icon(eventIcon, color: eventColor),
          Expanded(
            child: !isTeam1 ? _buildTimestamp(event) : const SizedBox(),
          ),
          Expanded(
            child: !isTeam1
                ? _buildPlayerInfo(event, eventColor)
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(GameEvent event, Color color) {
    return Text(
      event.player ?? 'End Turn',
      style: TextStyle(fontWeight: FontWeight.bold, color: color),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTimestamp(GameEvent event) {
    Duration eventDuration = event.timestamp.difference(gameData.gameStart);
    String eventTime =
        "${(eventDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(eventDuration.inSeconds % 60).toString().padLeft(2, '0')}";

    return Text(
      eventTime,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case "Airball":
        return Colors.blue;
      case "Bitchcup":
        return Colors.red;
      case "Normal Hit":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case "Airball":
        return BeerpongIcons.airball;
      case "Bitchcup":
        return Icons.warning;
      case "Normal Hit":
        return Icons.sports_bar;
      default:
        return Icons.sports;
    }
  }
}
