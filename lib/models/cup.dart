import 'dart:convert';
import 'package:flutter/material.dart';

// Class representing a cup in the game
class Cup {
  final int index; // The index of the cup
  bool isVisible; // Visibility status of the cup
  GlobalKey key; // Key to identify the cup widget
  Color color;

  // Constructor initializing the cup's index and setting it as visible by default
  Cup({required this.index, this.color = Colors.red, isVisible, key})
      : isVisible = isVisible ?? true,
        key = key ?? GlobalKey();

  // Method to create a clone of the cup
  Cup clone() {
    return Cup(
        index: index, isVisible: isVisible, color: color, key: GlobalKey());
  }

  // Method to create a widget representing the cup
  Widget widget(VoidCallback onTap) {
    return Visibility(
      visible: isVisible, // Determines whether the cup is visible
      maintainSize:
          true, // Maintains the size of the widget even when it's not visible
      maintainAnimation:
          true, // Maintains the animation state when visibility changes
      maintainState:
          true, // Maintains the state of the widget when visibility changes
      child: GestureDetector(
        onTap: onTap, // The function to call when the cup is tapped
        child: Container(
          key: key, // Key to identify the cup widget
          margin: const EdgeInsets.all(10.0), // Margin around the cup
          width: 60.0, // Width of the cup
          height: 60.0, // Height of the cup
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            color: color, // Color of the cup
            shape: BoxShape.circle, // Shape of the cup
          ),
        ),
      ),
    );
  }

  // Method to encode Cup instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'isVisible': isVisible,
      'color': color.value, // Encode the color as an integer value
    };
  }

  // Method to decode Cup instance from JSON
  factory Cup.fromJson(Map<String, dynamic> json) {
    return Cup(
      index: json['index'],
      isVisible: json['isVisible'],
      color: Color(json['color']), // Decode the color from an integer value
    );
  }

  // Method to encode a list of Cup instances to JSON string
  static String encodeList(List<Cup> cups) {
    return json.encode(cups.map((cup) => cup.toJson()).toList());
  }

  // Method to decode a list of Cup instances from JSON string
  static List<Cup> decodeList(String jsonString) {
    return (json.decode(jsonString) as List<dynamic>)
        .map((json) => Cup.fromJson(json))
        .toList();
  }
}
