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
  ///
  /// Visual design: outer rim (colored circle with white border + colored glow)
  /// wrapping an inner circle (darker fill) to simulate a top-down cup view.
  Widget widget({required VoidCallback onTap, int? hitCount, Color? overrideColor}) {
    final displayColor = overrideColor ?? color;
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
            border: Border.all(color: Colors.white60, width: 2),
            color: displayColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: displayColor.withValues(alpha: 0.55),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.18),
              ),
              child: hitCount != null
                  ? Center(
                      child: Text(
                        '$hitCount',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            ),
          ),
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
