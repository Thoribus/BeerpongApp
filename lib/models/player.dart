import 'user.dart';

/// A class representing a player in the game.
class Player {
  final String name;        // The player's name
  num score;                // The player's score
  int throws;               // Number of throws the player made
  int misses;               // Number of misses by the player
  int airballs;             // Number of airballs by the player
  int hitThisRound;         // Hits in the current round
  List<int> cupsHit;        // List of cup indices that the player has hit
  bool lastCupHit;          // Whether the player hit the last cup
  bool islandShotUsed;      // Whether the player used an island shot
  int defended;             // Number of successful defenses
  int consecutiveHits;      // Tracks consecutive hits
  int onFire;               // Times the player triggered "On Fire"
  User? user;               // Optional reference to a User object (DB, stats, etc.)
  bool isWinner;            // Whether the player is on the winning team

  Player({
    required this.name,
    this.score = 0.0,
    this.throws = 0,
    this.misses = 0,
    this.airballs = 0,
    this.defended = 0,
    int? consecutiveHits,
    List<int>? cupsHit,
    this.hitThisRound = 0,
    this.onFire = 0,
    this.islandShotUsed = false,
    this.lastCupHit = false,
    this.user,
    this.isWinner = false,
  }) : 
    consecutiveHits = consecutiveHits ?? 0,
    cupsHit = cupsHit ?? [];

  /// Clone this player into a new object.
  Player clone() {
    return Player(name: name, user: user)
      ..score = score
      ..throws = throws
      ..misses = misses
      ..airballs = airballs
      ..defended = defended
      ..consecutiveHits = consecutiveHits
      ..onFire = onFire
      ..hitThisRound = hitThisRound
      ..islandShotUsed = islandShotUsed
      ..lastCupHit = lastCupHit
      ..cupsHit = List.from(cupsHit)
      ..isWinner = isWinner
      ..user = user;
  }

  /// Increments the player's score by 1.
  void incrementScore() {
    score++;
  }

  /// Increments the player's hit count this round & consecutive hits.
  void incrementHitThisRound() {
    hitThisRound++;
    consecutiveHits++;
  }

  /// Increments the player's score by a specific amount.
  void incrementScoreBy(double points) {
    score += points;
  }

  /// Decrements the player's score by 1.
  void decrementScore() {
    score--;
  }

  /// Increments the player's miss count and resets consecutive hits.
  void incrementMisses() {
    misses++;
    consecutiveHits = 0;
  }

  /// Increments the player's total throws count.
  void incrementThrows() {
    throws++;
  }

  /// Sets the lastCupHit flag.
  void hitLastCup() {
    lastCupHit = true;
  }

  /// Resets the hits for this round.
  void resetHitThisRound() {
    hitThisRound = 0;
  }

  /// Checks if the player has 3 consecutive hits and triggers "On Fire".
  bool isOnFire() {
    if (consecutiveHits == 3) {
      onFire++;
      consecutiveHits = 0;
      return true;
    }
    return false;
  }

  /// Increments the player's airballs (and also increments misses).
  void incrementAirballs() {
    misses++;
    airballs++;
  }

  /// Records that this player hit a cup of given index.
  void hitCup(int cupIndex) {
    cupsHit.add(cupIndex);
  }

  /// Encode this Player into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'throws': throws,
      'misses': misses,
      'airballs': airballs,
      'hitThisRound': hitThisRound,
      'cupsHit': cupsHit,
      'lastCupHit': lastCupHit,
      'islandShotUsed': islandShotUsed,
      'defended': defended,
      'consecutiveHits': consecutiveHits,
      'onFire': onFire,
      'isWinner': isWinner,
      'user': user?.toJson(), // Only if user is non-null
    };
  }

  /// Decode a Player from a JSON map.
  factory Player.fromJson(Map<String, dynamic> json) {
    // Handle cases where 'hitThisRound' might be stored as a bool
    if (json["hitThisRound"] is bool) {
      json["hitThisRound"] = json["hitThisRound"] ? 1 : 0;
    }

    return Player(
      name: json['name'],
      score: json['score'],
      throws: json['throws'],
      misses: json['misses'],
      airballs: json['airballs'],
      cupsHit: List<int>.from(json['cupsHit'] ?? []),
      hitThisRound: json['hitThisRound'],
      islandShotUsed: json['islandShotUsed'] ?? false,
      defended: json['defended'] ?? 0,
      consecutiveHits: json['consecutiveHits'] ?? json['consecuteiveHits'] ?? 0,
      onFire: json['onFire'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      lastCupHit: json['lastCupHit'] ?? false,
      isWinner: json['isWinner'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Player($name, score: $score, throws: $throws, misses: $misses, airballs: $airballs, hitThisRound: $hitThisRound, cupsHit: $cupsHit, lastCupHit: $lastCupHit, islandShotUsed: $islandShotUsed, defended: $defended, consecutiveHits: $consecutiveHits, onFire: $onFire, isWinner: $isWinner, user: $user)';
  }

  /// Equality based on name (and potentially user).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Player) return false;
    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode ^ score.hashCode;
}
