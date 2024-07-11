import 'dart:convert';
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
  int defended;
  User? user;

  // Constructor initializing the player's name and setting initial values for score, misses, airballs, and hitThisRound
  Player({
    required this.name,
    this.score = 0,
    this.throws = 0,
    this.misses = 0,
    this.airballs = 0,
    this.defended = 0,
    cupsHit,
    this.hitThisRound = false,
    this.islandShotUsed = false,
    this.user,
  }) : cupsHit = cupsHit ?? [];

  Player clone() {
    return Player(name: name, user: user)
      ..score = score
      ..misses = misses
      ..throws = throws
      ..airballs = airballs
      ..defended = defended
      ..hitThisRound = hitThisRound
      ..islandShotUsed = islandShotUsed
      ..cupsHit = List.from(cupsHit);
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

  // Method to encode Player instance to JSON
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
      'user': user?.toJson(), // Assuming User class has a toJson() method
    };
  }

  // Method to decode Player instance from JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      score: json['score'],
      throws: json['throws'],
      misses: json['misses'],
      airballs: json['airballs'],
      cupsHit: List<int>.from(json['cupsHit']),
      hitThisRound: json['hitThisRound'],
      islandShotUsed: json['islandShotUsed'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    )
      ..lastCupHit = json['lastCupHit'];
  }

  // Method to encode a list of Player instances to JSON
  static String encodeList(List<Player> players) {
    return json.encode(
      players.map<Map<String, dynamic>>((player) => player.toJson()).toList(),
    );
  }

  // Method to decode a list of Player instances from JSON
  static List<Player> decodeList(String players) {
    return (json.decode(players) as List<dynamic>)
        .map<Player>((item) => Player.fromJson(item))
        .toList();
  }
}
