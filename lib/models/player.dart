import 'user.dart';

/// A class representing a player in the game.
class Player {
  final String name;        // The player's name
  double score;             // The player's score
  int throws;               // Number of throws the player made
  int misses;               // Number of misses by the player
  int airballs;             // Number of airballs by the player
  int hitThisRound;         // Hits in the current round
  List<int> cupsHit;        // List of cup indices that the player has hit
  bool lastCupHit;          // Whether the player hit the last cup
  bool islandShotUsed;      // Whether the player used an island shot
  int islandMakes;          // Number of island cups successfully sunk
  int defended;             // Number of successful defenses
  int consecutiveHits;      // Tracks consecutive hits
  int onFire;               // Times the player triggered "On Fire"
  int heatingUp;            // Times the player reached 2 consecutive hits
  int bounceAttempts;       // Number of bounce shots attempted
  int bounceMakes;          // Number of bounce shots that sank a cup
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
    this.heatingUp = 0,
    this.bounceAttempts = 0,
    this.bounceMakes = 0,
    this.islandShotUsed = false,
    this.islandMakes = 0,
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
      ..heatingUp = heatingUp
      ..bounceAttempts = bounceAttempts
      ..bounceMakes = bounceMakes
      ..hitThisRound = hitThisRound
      ..islandShotUsed = islandShotUsed
      ..islandMakes = islandMakes
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
    if (consecutiveHits == 2) heatingUp++;
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
      'islandMakes': islandMakes,
      'defended': defended,
      'consecutiveHits': consecutiveHits,
      'onFire': onFire,
      'heatingUp': heatingUp,
      'bounceAttempts': bounceAttempts,
      'bounceMakes': bounceMakes,
      'isWinner': isWinner,
      'user': user?.toJson(), // Only if user is non-null
    };
  }

  /// Decode a Player from a JSON map.
  factory Player.fromJson(Map<String, dynamic> json) {
    // Handle cases where 'hitThisRound' might be stored as a bool
    if (json['hitThisRound'] is bool) {
      json['hitThisRound'] = json['hitThisRound'] ? 1 : 0;
    }

    return Player(
      name: json['name'],
      score: (json['score'] as num).toDouble(),
      throws: json['throws'],
      misses: json['misses'],
      airballs: json['airballs'],
      cupsHit: List<int>.from(json['cupsHit'] ?? []),
      hitThisRound: json['hitThisRound'],
      islandShotUsed: json['islandShotUsed'] ?? false,
      islandMakes: json['islandMakes'] ?? 0,
      defended: json['defended'] ?? 0,
      consecutiveHits: json['consecutiveHits'] ?? 0,
      onFire: json['onFire'] ?? 0,
      heatingUp: json['heatingUp'] ?? 0,
      bounceAttempts: json['bounceAttempts'] ?? 0,
      bounceMakes: json['bounceMakes'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      lastCupHit: json['lastCupHit'] ?? false,
      isWinner: json['isWinner'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Player($name, score: $score, throws: $throws, misses: $misses, airballs: $airballs, hitThisRound: $hitThisRound, cupsHit: $cupsHit, lastCupHit: $lastCupHit, islandShotUsed: $islandShotUsed, islandMakes: $islandMakes, defended: $defended, consecutiveHits: $consecutiveHits, onFire: $onFire, heatingUp: $heatingUp, bounceAttempts: $bounceAttempts, bounceMakes: $bounceMakes, isWinner: $isWinner, user: $user)';
  }

  /// Equality based on name (and potentially user).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Player) return false;
    return name == other.name;
  }

  Player copyWithResetStats() {
    return Player(
      name: name,
      user: user,
      score: 0,
      throws: 0,
      misses: 0,
      airballs: 0,
      hitThisRound: 0,
      cupsHit: [],
      lastCupHit: false,
      islandShotUsed: false,
      islandMakes: 0,
      defended: 0,
      consecutiveHits: 0,
      onFire: 0,
      heatingUp: 0,
      bounceAttempts: 0,
      bounceMakes: 0,
      isWinner: false,
    );
  }

  /// Merges the stats from another Player into this Player (used for updating tournament totals).
  Player mergedWith(Player matchResult) {
    // Names must match, optionally also check user
    if (name != matchResult.name) {
      throw Exception('Cannot merge: names do not match ($name != ${matchResult.name})');
    }
    return Player(
      name: name,
      user: user ?? matchResult.user,
      score: score + matchResult.score,
      throws: throws + matchResult.throws,
      misses: misses + matchResult.misses,
      airballs: airballs + matchResult.airballs,
      defended: defended + matchResult.defended,
      consecutiveHits: 0, // Optional: doesn't carry over in tournaments
      cupsHit: [...cupsHit, ...matchResult.cupsHit],
      hitThisRound: 0, // Not relevant for tournament totals
      onFire: onFire + matchResult.onFire,
      heatingUp: heatingUp + matchResult.heatingUp,
      bounceAttempts: bounceAttempts + matchResult.bounceAttempts,
      bounceMakes: bounceMakes + matchResult.bounceMakes,
      islandShotUsed: islandShotUsed || matchResult.islandShotUsed,
      islandMakes: islandMakes + matchResult.islandMakes,
      lastCupHit: lastCupHit || matchResult.lastCupHit,
      isWinner: isWinner || matchResult.isWinner,
    );
  }

  @override
  int get hashCode => name.hashCode;
}

extension PlayerCopyWith on Player {
  Player copyWithName(String newName) {
    return Player(
      name: newName,
      user: user,
      score: score,
      throws: throws,
      misses: misses,
      airballs: airballs,
      defended: defended,
      consecutiveHits: consecutiveHits,
      cupsHit: cupsHit,
      hitThisRound: hitThisRound,
      onFire: onFire,
      heatingUp: heatingUp,
      bounceAttempts: bounceAttempts,
      bounceMakes: bounceMakes,
      islandShotUsed: islandShotUsed,
      islandMakes: islandMakes,
      lastCupHit: lastCupHit,
    );
  }

  Player copyWithUser(User? newUser) {
    return Player(
      name: name,
      user: newUser,
      score: score,
      throws: throws,
      misses: misses,
      airballs: airballs,
      defended: defended,
      consecutiveHits: consecutiveHits,
      cupsHit: cupsHit,
      hitThisRound: hitThisRound,
      onFire: onFire,
      heatingUp: heatingUp,
      bounceAttempts: bounceAttempts,
      bounceMakes: bounceMakes,
      islandShotUsed: islandShotUsed,
      islandMakes: islandMakes,
      lastCupHit: lastCupHit,
    );
  }
}
