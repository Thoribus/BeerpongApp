import 'package:flutter/material.dart';

// Class representing a cup in the game
class Cup {
  final int index; // The index of the cup
  bool isVisible; // Visibility status of the cup

  // Constructor initializing the cup's index and setting it as visible by default
  Cup(this.index) : isVisible = true;

  // Method to create a widget representing the cup
  Widget widget(VoidCallback onTap) {
    return Visibility(
      visible: isVisible, // Determines whether the cup is visible
      maintainSize: true, // Maintains the size of the widget even when it's not visible
      maintainAnimation: true, // Maintains the animation state when visibility changes
      maintainState: true, // Maintains the state of the widget when visibility changes
      child: GestureDetector(
        onTap: onTap, // The function to call when the cup is tapped
        child: Container(
          margin: const EdgeInsets.all(10.0), // Margin around the cup
          width: 60.0, // Width of the cup
          height: 60.0, // Height of the cup
          decoration: const BoxDecoration(
            color: Colors.red, // Color of the cup
            shape: BoxShape.circle, // Shape of the cup
          ),
        ),
      ),
    );
  }
}
