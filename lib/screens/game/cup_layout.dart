import 'package:flutter/material.dart';
import '../../models/cup.dart';
import 'game_screen.dart'; // so we can reference _GameScreenState

/// A utility class for building the UI layout of cups (default or rearranged).
class CupLayout {
  /// The top-level method that decides whether to build default or rearranged layout.
  static Widget buildCupsArea({
    required GameScreenState state,
  }) {
    final isRearranged = state.currentTeam.isRearranged;
    final cups = state.currentTeam.cups;

    return isRearranged
        ? _buildRearrangedCupsLayout(state, cups)
        : _buildDefaultCupsLayout(state, cups);
  }

  static Widget _buildDefaultCupsLayout(GameScreenState state, List<Cup> cups) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCupRow(state, cups.sublist(6, 10)),
        _buildCupRow(state, cups.sublist(3, 6)),
        _buildCupRow(state, cups.sublist(1, 3)),
        _buildCupRow(state, cups.sublist(0, 1)),
      ],
    );
  }

  static Widget _buildRearrangedCupsLayout(GameScreenState state, List<Cup> cups) {
    switch (cups.length) {
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(state, cups.sublist(0, 3)),
            _buildCupRow(state, cups.sublist(3, 5)),
            _buildCupRow(state, cups.sublist(5, 6)),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(state, cups.sublist(0, 1)),
            _buildCupRow(state, cups.sublist(1, 3)),
            _buildCupRow(state, cups.sublist(3, 4)),
            _buildCupRow(state, cups.sublist(4, 5)),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(state, cups.sublist(0, 1)),
            _buildCupRow(state, cups.sublist(1, 3)),
            _buildCupRow(state, cups.sublist(3, 4)),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCupRow(state, cups.sublist(0, 2)),
            _buildCupRow(state, cups.sublist(2, 3)),
          ],
        );
      case 2:
        return _buildCupRow(state, cups.sublist(0, 2));
      default:
        // fallback for 1 or 0
        return _buildCupRow(state, cups.take(1).toList());
    }
  }

  static Widget _buildCupRow(GameScreenState state, List<Cup> cups) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cups.map((cup) {
        return cup.widget(
          () => state.islandShotActive
              ? state.handleIslandShot(cup.index)
              : state.showPlayerSelectionDialog(state.context, cup.index),
        );
      }).toList(),
    );
  }

    //region ----- Assign Indices for Rearranged Cups -----
  /// Assigns new indices to the given cups based on how many are left for the rearranged layout.
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
        // fallback if more than 6 or no special arrangement
        newIndices = cups.map((c) => c.index).toList();
    }

    for (int i = 0; i < cups.length; i++) {
      cups[i] =
          Cup(index: newIndices[i], color: cups[i].color, isVisible: true);
    }
    return cups;
  }
  //endregion
}
