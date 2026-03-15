import 'package:flutter/material.dart';

/// A class representing a cup in the game.
class Cup {
  final int index; // The index of the cup
  bool isVisible; // Whether the cup is currently visible
  final GlobalKey key; // The key to identify the cup widget
  Color color; // The cup's color

  /// Constructor initializing the cup.
  Cup({
    required this.index,
    this.color = Colors.red,
    bool? isVisible,
    GlobalKey? key,
  })  : isVisible = isVisible ?? true,
        key = key ?? GlobalKey();

  /// Creates a clone of this cup.
  Cup clone() {
    return Cup(
      index: index,
      isVisible: isVisible,
      color: color,
      key: GlobalKey(),
    );
  }

  /// Builds the widget representing this cup.
  Widget widget({required VoidCallback onTap, int? hitCount}) {
    return Visibility(
      visible: isVisible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          key: key,
          margin: const EdgeInsets.all(10.0),
          width: 60.0,
          height: 60.0,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            color: color,
            shape: BoxShape.circle,
          ),
          child: hitCount != null
              ? Center(
                  child: Text(
                    '$hitCount', // Display the count in the cup
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// Encodes this Cup instance into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'isVisible': isVisible,
      'color': color.toARGB32(), // store color as integer
    };
  }

  /// Decodes a Cup instance from JSON.
  factory Cup.fromJson(Map<String, dynamic> json) {
    return Cup(
      index: json['index'],
      isVisible: json['isVisible'],
      color: Color(json['color']),
    );
  }
}
