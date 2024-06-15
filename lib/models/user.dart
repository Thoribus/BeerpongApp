class User {
  final String id;
  String username;
  double totalScore;
  int totalMisses;
  int totalAirballs;
  List<int> cupsHit;
  int wins;
  int losses;

  User({
    required this.id,
    required this.username,
    this.totalScore = 0,
    this.totalMisses = 0,
    this.totalAirballs = 0,
    this.cupsHit = const [],
    this.wins = 0,
    this.losses = 0,
  });

}
