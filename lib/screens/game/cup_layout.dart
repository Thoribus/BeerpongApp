import 'package:beerpongapp/models/team.dart';
import 'package:flutter/material.dart';
import '../../models/cup.dart';

/// A utility class for building the UI layout of cups (default or rearranged).
class CupLayout {
  /// Builds the cup area for [team]. Pass [onCupTap] to make cups interactive.
  static Widget buildCupsArea({
    required Team team,
    void Function(int cupIndex)? onCupTap,
  }) {
    return team.isRearranged
        ? _buildRearrangedCupsLayout(team.cups, onCupTap)
        : _buildDefaultCupsLayout(team.cups, onCupTap);
  }

  static Widget _buildDefaultCupsLayout(
      List<Cup> cups, void Function(int)? onCupTap) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCupRow(cups.sublist(6, 10), onCupTap),
        _buildCupRow(cups.sublist(3, 6), onCupTap),
        _buildCupRow(cups.sublist(1, 3), onCupTap),
        _buildCupRow(cups.sublist(0, 1), onCupTap),
      ],
    );
  }

  static Widget _buildRearrangedCupsLayout(
      List<Cup> cups, void Function(int)? onCupTap) {
    switch (cups.length) {
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 3), onCupTap),
            _buildCupRow(cups.sublist(3, 5), onCupTap),
            _buildCupRow(cups.sublist(5, 6), onCupTap),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 1), onCupTap),
            _buildCupRow(cups.sublist(1, 3), onCupTap),
            _buildCupRow(cups.sublist(3, 4), onCupTap),
            _buildCupRow(cups.sublist(4, 5), onCupTap),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 1), onCupTap),
            _buildCupRow(cups.sublist(1, 3), onCupTap),
            _buildCupRow(cups.sublist(3, 4), onCupTap),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(cups.sublist(0, 2), onCupTap),
            _buildCupRow(cups.sublist(2, 3), onCupTap),
          ],
        );
      case 2:
        return _buildCupRow(cups.sublist(0, 2), onCupTap);
      default:
        return _buildCupRow(cups.take(1).toList(), onCupTap);
    }
  }

  static Widget _buildCupRow(List<Cup> cups, void Function(int)? onCupTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cups.map((cup) {
        return cup.widget(
          onTap: onCupTap != null ? () => onCupTap(cup.index) : () {},
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
