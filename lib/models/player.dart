import 'user.dart';

// Class representing a player in the game
class Player {
  final String name; // The name of the player
  double score; // The score of the player
  int throws;
  int misses; // The number of misses by the player
  int airballs; // The number of airballs by the player
  bool hitThisRound; // Whether the player has hit a cup this round
  List<int> cupsHit = []; // List of cup indices hit by the player
  bool lastCupHit = false;
  bool islandShotUsed = false;
  User? user;

  // Constructor initializing the player's name and setting initial values for score, misses, airballs, and hitThisRound
  Player({
    required this.name,
    this.score = 0,
    this.throws = 0,
    this.misses = 0,
    this.airballs = 0,
    cupsHit,
    this.hitThisRound = false,
    this.islandShotUsed = false,
    this.user,
  }) : cupsHit = cupsHit ?? [];

  Player clone() {
    return Player(
      name: name,
      score: score,
      throws: throws,
      hitThisRound: hitThisRound,
      cupsHit: List<int>.from(cupsHit),
      misses: misses,
      airballs: airballs,
    );
  }

  // Method to increment the player's score
  void incrementScore() {
    score++; // Increase the score by 1
    hitThisRound = true; // Mark that the player hit a cup this round
  }

  void incrementScoreBy(double points) {
    score += points;
  }

  // Method to increment the player's misses
  void incrementMisses() {
    misses++; // Increase the misses count by 1
  }

  void incrementThrows() {
    throws++;
  }

  void hitLastCup() {
    lastCupHit = true;
  }

  // Method to reset the hitThisRound flag
  void resetHitThisRound() {
    hitThisRound = false; // Reset the flag to false
  }

  // Method to increment the player's airballs
  void incrementAirballs() {
    misses++; // Increase the misses count by 1
    airballs++; // Increase the airballs count by 1
  }

  void hitCup(int cupIndex) {
    cupsHit.add(cupIndex);
  }
}
