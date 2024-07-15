import 'package:flutter/material.dart';

class User {
  final String id;
  String username;
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
  IconData icon;
  Color iconColor;

  User({
    required this.id,
    required this.username,
    this.totalScore = 0,
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
    this.icon = Icons.person, // Default icon if not provided
    this.iconColor = Colors.blue, // Default color if not provided
  });

  double get winRate {
    int totalGames = wins + losses;
    if (totalGames == 0) return 0.0;
    return wins / totalGames;
  }

  // Method to encode User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
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
      'icon': icon.codePoint, // Encode icon as an integer
      'iconColor': iconColor.value, // Encode color as an integer
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
      onFire: json['onFire'] ?? 0,
      defended: json['defended'] ?? 0,
      hitLastCup: json['hitLastCup'] ?? 0,
      cupsHit: List<int>.from(json['cupsHit']),
      wins: json['wins'],
      losses: json['losses'],
      friends: List<String>.from(json['friends']),
      icon: IconData(json['icon'], fontFamily: 'BeerpongIcons', fontPackage: null), // Decode icon from integer
      iconColor: Color(json['iconColor']), // Decode color from integer
    );
  }

  // Method to create a copy of the User with some properties changed
  User copyWith({
    String? id,
    String? username,
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
    IconData? icon,
    Color? iconColor,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
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
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}
