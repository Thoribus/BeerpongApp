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
  final IconData icon;
  final Color iconColor;

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
}
