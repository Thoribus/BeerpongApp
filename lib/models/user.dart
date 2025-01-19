/// Represents the user in your Beer Pong app.
class User {
  final String id;
  String username;

  /// A short descriptor or rank the user can display (e.g., "Beer Pong King").
  String title;

  /// Keys identifying which of your pre-defined images they chose. 
  /// For example, "avatar_1", "avatar_2", "background_blue", etc.
  String avatarKey;
  String backgroundKey;

  /// Various gameplay stats
  double totalScore;
  int totalMisses;
  int totalAirballs;
  int totalThrows;
  int onFire;
  int defended;
  int hitLastCup;
  List<int> cupsHit;
  int wins;
  int losses;
  List<String> friends;
  List<String> unlockedTitles;

  User({
    required this.id,
    required this.username,
    this.title = '',
    this.avatarKey = '',
    this.backgroundKey = '',
    this.totalScore = 0.0,
    this.totalMisses = 0,
    this.totalAirballs = 0,
    this.totalThrows = 0,
    this.onFire = 0,
    this.defended = 0,
    this.hitLastCup = 0,
    this.cupsHit = const [],
    this.wins = 0,
    this.losses = 0,
    this.friends = const [],
    this.unlockedTitles = const [],
  });

  /// Convenience getter to compute the user's overall win rate.
  double get winRate {
    final totalGames = wins + losses;
    if (totalGames == 0) return 0.0;
    return wins / totalGames;
  }

  double get hitRate {
    return totalThrows > 0 ? totalScore / totalThrows : 0.0;
  }

  /// Encode this user into a JSON-compatible map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'title': title,
      'avatarKey': avatarKey,
      'backgroundKey': backgroundKey,
      'totalScore': totalScore,
      'totalMisses': totalMisses,
      'totalAirballs': totalAirballs,
      'totalThrows': totalThrows,
      'onFire': onFire,
      'defended': defended,
      'hitLastCup': hitLastCup,
      'cupsHit': cupsHit,
      'wins': wins,
      'losses': losses,
      'friends': friends,
      'unlockedTitles': unlockedTitles,
    };
  }

  /// Decode a User from a Firestore or JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      title: json['title'] ?? '',
      avatarKey: json['avatarKey'] ?? '',
      backgroundKey: json['backgroundKey'] ?? '',

      totalScore: (json['totalScore'] ?? 0.0).toDouble(),
      totalMisses: json['totalMisses'] ?? 0,
      totalAirballs: json['totalAirballs'] ?? 0,
      totalThrows: json['totalThrows'] ?? 0,
      onFire: json['onFire'] ?? 0,
      defended: json['defended'] ?? 0,
      hitLastCup: json['hitLastCup'] ?? 0,
      cupsHit: List<int>.from(json['cupsHit'] ?? []),
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      friends: List<String>.from(json['friends'] ?? []),
      unlockedTitles: List<String>.from(json['unlockedTitles'] ?? []),
    );
  }

  /// Creates a copy of this user with optionally updated fields.
  User copyWith({
    String? username,
    String? title,
    String? avatarKey,
    String? backgroundKey,
    double? totalScore,
    int? totalMisses,
    int? totalAirballs,
    int? totalThrows,
    int? onFire,
    int? defended,
    int? hitLastCup,
    List<int>? cupsHit,
    int? wins,
    int? losses,
    List<String>? friends,
    List<String>? unlockedTitles,
  }) {
    return User(
      id: id, // The ID never changes in this example
      username: username ?? this.username,
      title: title ?? this.title,
      avatarKey: avatarKey ?? this.avatarKey,
      backgroundKey: backgroundKey ?? this.backgroundKey,
      totalScore: totalScore ?? this.totalScore,
      totalMisses: totalMisses ?? this.totalMisses,
      totalAirballs: totalAirballs ?? this.totalAirballs,
      totalThrows: totalThrows ?? this.totalThrows,
      onFire: onFire ?? this.onFire,
      defended: defended ?? this.defended,
      hitLastCup: hitLastCup ?? this.hitLastCup,
      cupsHit: cupsHit ?? this.cupsHit,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      friends: friends ?? this.friends,
      unlockedTitles: unlockedTitles ?? this.unlockedTitles,
    );
  }
}
