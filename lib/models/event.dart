import 'package:cloud_firestore/cloud_firestore.dart';

class GameEvent {
  final String eventId;      // The ID of the event in Firestore
  final String eventType;    // e.g. "Airball", "Bitchcup", etc.
  final String gameId;       // The ID of the game this event is part of
  final String? player;      // The ID of the player (if relevant)
  final String team;        // The ID of the team (if relevant)
  final DateTime timestamp; // When the event occurred, as a DateTime in Dart

  // Constructor: we won't assign a DateTime here because we'll rely on
  // FieldValue.serverTimestamp() when writing to Firestore. However, we
  // still accept a timestamp if you want to pass one manually (or null).
  GameEvent({
    required this.eventId,
    required this.eventType,
    required this.gameId,
    this.player,
    required this.team,
    required this.timestamp,
  });

  /// Construct from Firestore data. 
  /// Firestore returns a `Timestamp` object, so we convert it to DateTime in Dart.
  factory GameEvent.fromJson(Map<String, dynamic> json, String id, String gameId) {
    return GameEvent(
      eventId: id,
      eventType: json["eventType"] as String,
      gameId: gameId,
      player: json["player"] as String?,
      team: json["team"] as String,
      timestamp: (json["timestamp"] as Timestamp).toDate(),
    );
  }

  @override
  String toString() {
    return "GameEvent($eventType, player: $player, team: $team, timestamp: $timestamp)";
  }
}
