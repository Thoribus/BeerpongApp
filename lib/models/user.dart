import 'package:flutter/material.dart';

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
  IconData icon;
  Color iconColor;

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
    this.icon = Icons.person, // Default icon if not provided
    this.iconColor = Colors.blue, // Default color if not provided
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
      cupsHit: List<int>.from(json['cupsHit']),
      wins: json['wins'],
      losses: json['losses'],
      friends: List<String>.from(json['friends']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'), // Decode icon from integer
      iconColor: Color(json['iconColor']), // Decode color from integer
    );
  }
}
