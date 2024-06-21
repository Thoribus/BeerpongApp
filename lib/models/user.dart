class User {
  final String id;
  String username;
  double totalScore;
  int totalMisses;
  int totalAirballs;
  int totalThrows;
  List<int> cupsHit;
  int wins;
  int losses;
  List<String> friends;

  User({
    required this.id,
    required this.username,
    this.totalScore = 0,
    this.totalMisses = 0,
    this.totalAirballs = 0,
    this.totalThrows = 0,
    this.cupsHit = const [],
    this.wins = 0,
    this.losses = 0,
    this.friends = const [],
  });

  // Method to encode User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'totalScore': totalScore,
      'totalMisses': totalMisses,
      'totalAirballs': totalAirballs,
      'totalThrows': totalThrows,
      'cupsHit': cupsHit,
      'wins': wins,
      'losses': losses,
      'friends': friends,
    };
  }

  // Method to decode User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      totalScore: json['totalScore'],
      totalMisses: json['totalMisses'],
      totalAirballs: json['totalAirballs'],
      totalThrows: json['totalThrows'],
      cupsHit: List<int>.from(json['cupsHit']),
      wins: json['wins'],
      losses: json['losses'],
      friends: List<String>.from(json['friends']),
    );
  }
}
