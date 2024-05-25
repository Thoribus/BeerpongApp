// Class representing a player in the game
class Player {
  final String name; // The name of the player
  int score; // The score of the player
  int misses; // The number of misses by the player
  int airballs; // The number of airballs by the player
  bool hitThisRound; // Whether the player has hit a cup this round

  // Constructor initializing the player's name and setting initial values for score, misses, airballs, and hitThisRound
  Player(this.name)
      : score = 0,
        misses = 0,
        airballs = 0,
        hitThisRound = false;

  // Method to increment the player's score
  void incrementScore() {
    score++; // Increase the score by 1
    hitThisRound = true; // Mark that the player hit a cup this round
  }

  // Method to increment the player's misses
  void incrementMisses() {
    misses++; // Increase the misses count by 1
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
}
