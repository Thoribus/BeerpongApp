class GameEvent {
  final String eventType;       // e.g. "Airball", "Bitchcup", etc.
  final String? player;        // The ID of the Player
  final String? team;         // If it was a Team event instead of a single player

  // You can add more fields, like "scoreChange", etc.

  GameEvent({
    required this.eventType,
    this.player,
    this.team,
  });

  // Convert to JSON-friendly map (for Firestore or other storage):
  Map<String, dynamic> toJson() {
    return {
      "eventType": eventType,
      "player": player,
      "team": team,
    };
  }

  // Construct from JSON map:
  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      eventType: json["eventType"] as String,
      player: json["player"] as String?,
      team: json["team"] as String?,
    );
  }
}
