import 'package:beerpongapp/models/team.dart';
import 'package:flutter/material.dart';
import '../../models/cup.dart';

/// A utility class for building the UI layout of cups (default or rearranged).
class CupLayout {
  /// Builds the cup area for [team]. Pass [onCupTap] to make cups interactive.
  /// [skinColor] overrides the visual colour of cups that are in their normal
  /// (un-hit, non-island) state — yellow and green cups are unaffected.
  static Widget buildCupsArea({
    required Team team,
    void Function(int cupIndex)? onCupTap,
    Color? skinColor,
    bool showNumbers = false,
  }) {
    return team.isRearranged
        ? _buildRearrangedCupsLayout(team.cups, onCupTap, skinColor, showNumbers)
        : _buildDefaultCupsLayout(team.cups, onCupTap, skinColor, showNumbers);
  }

  static Widget _buildDefaultCupsLayout(
      List<Cup> cups, void Function(int)? onCupTap, Color? skinColor, bool showNumbers) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCupRow(cups.sublist(6, 10), onCupTap, skinColor, showNumbers),
        _buildCupRow(cups.sublist(3, 6), onCupTap, skinColor, showNumbers),
        _buildCupRow(cups.sublist(1, 3), onCupTap, skinColor, showNumbers),
        _buildCupRow(cups.sublist(0, 1), onCupTap, skinColor, showNumbers),
      ],
    );
  }

  static Widget _buildRearrangedCupsLayout(
      List<Cup> cups, void Function(int)? onCupTap, Color? skinColor, bool showNumbers) {
    switch (cups.length) {
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 3), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(3, 5), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(5, 6), onCupTap, skinColor, showNumbers),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 1), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(1, 3), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(3, 4), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(4, 5), onCupTap, skinColor, showNumbers),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 1), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(1, 3), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(3, 4), onCupTap, skinColor, showNumbers),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 2), onCupTap, skinColor, showNumbers),
            _buildCupRow(cups.sublist(2, 3), onCupTap, skinColor, showNumbers),
          ],
        );
      case 2:
        return _buildCupRow(cups.sublist(0, 2), onCupTap, skinColor, showNumbers);
      default:
        return _buildCupRow(cups.take(1).toList(), onCupTap, skinColor, showNumbers);
    }
  }

  static Widget _buildCupRow(
      List<Cup> cups, void Function(int)? onCupTap, Color? skinColor, bool showNumbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cups.map((cup) {
        // Apply skin only to normal cups — yellow (island) and green (hit) keep
        // their semantic colours for correct game-logic reads.
        final override = (skinColor != null &&
                cup.color != Colors.yellow &&
                cup.color != Colors.green)
            ? skinColor
            : null;
        return cup.widget(
          onTap: onCupTap != null ? () => onCupTap(cup.index) : () {},
          overrideColor: override,
          hitCount: showNumbers && cup.isVisible && cup.color != Colors.green
              ? cup.index + 1
              : null,
        );
      }).toList(),
    );
  }

  //region ----- Assign Indices for Rearranged Cups -----
  /// Assigns new indices to the given cups based on how many are left.
  static List<Cup> assignSpecificIndices(List<Cup> cups) {
    List<int> newIndices;
    switch (cups.length) {
      case 6:
        newIndices = [6, 7, 8, 3, 4, 1];
        break;
      case 5:
        newIndices = [7, 3, 4, 1, 0];
        break;
      case 4:
        newIndices = [7, 3, 4, 1];
        break;
      case 3:
        newIndices = [7, 8, 4];
        break;
      case 2:
        newIndices = [7, 3];
        break;
      case 1:
        newIndices = [7];
        break;
      default:
        newIndices = cups.map((c) => c.index).toList();
    }

    for (int i = 0; i < cups.length; i++) {
      cups[i] = Cup(index: newIndices[i], color: cups[i].color, isVisible: true);
    }
    return cups;
  }
  //endregion
}
