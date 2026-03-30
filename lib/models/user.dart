import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, int> cupsHitCount;
  int wins;
  int losses;
  List<String> friends;
  List<String> unlockedTitles;
  int totalHeatingUp;
  int bounceAttempts;
  int bounceMakes;
  int islandAttempts;
  int islandMakes;
  int deathCupHits;

  /// XP earned across all games. Drives the level system.
  int xp;

  /// Games won in a row right now. Reset to 0 on any loss.
  int currentWinStreak;

  /// All-time best consecutive-win streak.
  int bestWinStreak;

  /// Games completed with zero misses.
  int perfectGames;

  /// Games played after 23:00 local time.
  int nightGames;

  /// Highest achievement stage unlocked per achievement ID.
  /// e.g. `{'cups_hit': 2, 'on_fire': 1}` — 0 = locked, 1 = Bronze, …, 4 = Diamond.
  /// Written by [AchievementEngine.checkAndGrantTitles] after each game.
  Map<String, int> unlockedAchievementStages;

  /// Stars earned through gameplay and rewarded ads. Spent in the shop.
  int stars;

  /// IDs of shop items the user has purchased (distinct from level-gated unlocks).
  List<String> purchasedItems;

  /// True when the user has purchased the Supporter Pack.
  /// Set server-side by [validatePurchase] — never trust a client-supplied value.
  bool isSupporter;

  /// Timestamp of the last completed game. Written by the server via
  /// [FieldValue.serverTimestamp()] in [UserRepository.saveGame].
  /// Used by the friends list to show "last seen" without extra queries.
  DateTime? lastGameAt;

  /// The Firestore game document ID of an in-progress game the user is
  /// currently playing. Set when the host starts a game; cleared when the game
  /// ends. Used by the friends list to surface a "Watch" button.
  String? activeGameId;

  /// ID of the equipped cup skin shop item (e.g. 'ingame_gold_cups'), or null.
  String? activeCupSkin;

  /// ID of the equipped table theme shop item (e.g. 'ingame_dark_table'), or null.
  String? activeTableTheme;

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
    this.cupsHitCount = const {},
    this.wins = 0,
    this.losses = 0,
    this.friends = const [],
    this.unlockedTitles = const [],
    this.totalHeatingUp = 0,
    this.bounceAttempts = 0,
    this.bounceMakes = 0,
    this.islandAttempts = 0,
    this.islandMakes = 0,
    this.deathCupHits = 0,
    this.xp = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    this.perfectGames = 0,
    this.nightGames = 0,
    this.unlockedAchievementStages = const {},
    this.stars = 0,
    this.purchasedItems = const [],
    this.isSupporter = false,
    this.lastGameAt,
    this.activeGameId,
    this.activeCupSkin,
    this.activeTableTheme,
  });

  /// Lowercase version of username, used for case-insensitive uniqueness checks.
  String get usernameLower => username.toLowerCase();

  /// Convenience getter to compute the user's overall win rate.
  double get winRate {
    final totalGames = wins + losses;
    if (totalGames == 0) return 0.0;
    return wins / totalGames;
  }

  double get hitRate {
    return totalThrows > 0 ? totalScore / totalThrows : 0.0;
  }

  /// Flat list of cup positions hit, reconstructed from counts. Used by legacy stats screens.
  List<int> get cupsHit {
    final result = <int>[];
    cupsHitCount.forEach((k, hitCount) {
      final idx = int.tryParse(k);
      if (idx != null) {
        for (var i = 0; i < hitCount; i++) {
          result.add(idx);
        }
      }
    });
    return result;
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
      'cupsHitCount': cupsHitCount,
      'wins': wins,
      'losses': losses,
      'friends': friends,
      'unlockedTitles': unlockedTitles,
      'usernameLower': usernameLower,
      'totalHeatingUp': totalHeatingUp,
      'totalBounceAttempts': bounceAttempts,
      'totalBounceMakes': bounceMakes,
      'totalIslandAttempts': islandAttempts,
      'totalIslandMakes': islandMakes,
      'totalDeathCupHits': deathCupHits,
      'xp': xp,
      'currentWinStreak': currentWinStreak,
      'bestWinStreak': bestWinStreak,
      'perfectGames': perfectGames,
      'nightGames': nightGames,
      'unlockedAchievementStages': unlockedAchievementStages,
      'stars': stars,
      'purchasedItems': purchasedItems,
      'isSupporter': isSupporter,
      'activeCupSkin': activeCupSkin,
      'activeTableTheme': activeTableTheme,
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
      cupsHitCount: Map<String, int>.from(
        (json['cupsHitCount'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ) ??
            {},
      ),
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      friends: List<String>.from(json['friends'] ?? []),
      unlockedTitles: List<String>.from(json['unlockedTitles'] ?? []),
      totalHeatingUp: json['totalHeatingUp'] ?? 0,
      bounceAttempts: json['totalBounceAttempts'] ?? 0,
      bounceMakes: json['totalBounceMakes'] ?? 0,
      islandAttempts: json['totalIslandAttempts'] ?? 0,
      islandMakes: json['totalIslandMakes'] ?? 0,
      deathCupHits: json['totalDeathCupHits'] ?? 0,
      xp: json['xp'] ?? 0,
      currentWinStreak: json['currentWinStreak'] ?? 0,
      bestWinStreak: json['bestWinStreak'] ?? 0,
      perfectGames: json['perfectGames'] ?? 0,
      nightGames: json['nightGames'] ?? 0,
      unlockedAchievementStages: Map<String, int>.from(
        (json['unlockedAchievementStages'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ) ??
            {},
      ),
      stars: json['stars'] ?? 0,
      purchasedItems: List<String>.from(json['purchasedItems'] ?? []),
      isSupporter: json['isSupporter'] as bool? ?? false,
      activeCupSkin: json['activeCupSkin'] as String?,
      activeTableTheme: json['activeTableTheme'] as String?,
      lastGameAt: () {
        final v = json['lastGameAt'];
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.tryParse(v);
        return null;
      }(),
      activeGameId: json['activeGameId'] as String?,
    );
  }

  String mapAvatarKeyToAsset() {
    if (avatarKey.isEmpty) return '';
    return 'assets/avatars/$avatarKey.svg';
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
    Map<String, int>? cupsHitCount,
    int? wins,
    int? losses,
    List<String>? friends,
    List<String>? unlockedTitles,
    int? totalHeatingUp,
    int? bounceAttempts,
    int? bounceMakes,
    int? islandAttempts,
    int? islandMakes,
    int? deathCupHits,
    int? xp,
    int? currentWinStreak,
    int? bestWinStreak,
    int? perfectGames,
    int? nightGames,
    Map<String, int>? unlockedAchievementStages,
    int? stars,
    List<String>? purchasedItems,
    bool? isSupporter,
    DateTime? lastGameAt,
    String? activeGameId,
  }) {
    // activeCupSkin / activeTableTheme are nullable and cleared via equipItem +
    // refreshUser, not through copyWith, so they are intentionally omitted here.
    return User(
      id: id,
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
      cupsHitCount: cupsHitCount ?? this.cupsHitCount,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      friends: friends ?? this.friends,
      unlockedTitles: unlockedTitles ?? this.unlockedTitles,
      totalHeatingUp: totalHeatingUp ?? this.totalHeatingUp,
      bounceAttempts: bounceAttempts ?? this.bounceAttempts,
      bounceMakes: bounceMakes ?? this.bounceMakes,
      islandAttempts: islandAttempts ?? this.islandAttempts,
      islandMakes: islandMakes ?? this.islandMakes,
      deathCupHits: deathCupHits ?? this.deathCupHits,
      xp: xp ?? this.xp,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      perfectGames: perfectGames ?? this.perfectGames,
      nightGames: nightGames ?? this.nightGames,
      unlockedAchievementStages:
          unlockedAchievementStages ?? this.unlockedAchievementStages,
      stars: stars ?? this.stars,
      purchasedItems: purchasedItems ?? this.purchasedItems,
      isSupporter: isSupporter ?? this.isSupporter,
      lastGameAt: lastGameAt ?? this.lastGameAt,
      activeGameId: activeGameId ?? this.activeGameId,
      activeCupSkin: activeCupSkin,
      activeTableTheme: activeTableTheme,
    );
  }
}
