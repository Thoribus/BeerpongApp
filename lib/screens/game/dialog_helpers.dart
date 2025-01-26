import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/base_screen.dart';
import 'package:flutter/material.dart';
import 'game_screen.dart';

/// A utility class to hold all the AwesomeDialog-based methods.
class DialogHelpers {
  /// Generic selection dialog for choosing players.
  static Future<void> showSelectionDialog(
    BuildContext context,
    String title,
    List<Player> players,
    Function(Player) onSelected,
  ) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.amberAccent,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10.0),
          const Text(
            "Select the player for the cup action:",
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: players.map((player) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(player);
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4.0,
                  child: SizedBox(
                    width: 120.0,
                    height: 150.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35.0,
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(
                              Icons.person,
                              size: 50.0,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      btnCancelOnPress: () {},
      btnCancelText: "Cancel",
    ).show();
  }

  /// Dialog to pick a player for the Airball rule.
  static Future<void> showAirballPlayerSelectionDialog(GameScreenState state,
      Team currentTeam, Function(Player) onSelected) async {
    await DialogHelpers.showSelectionDialog(
      state.context,
      'Select Player',
      currentTeam.currentPlayers,
      onSelected,
    );
  }

  static Future<Player?> showNachwurfSelectionDialog(
    BuildContext context,
    String title,
    List<Player> players,
  ) {
    // Create a Completer that we'll complete when user picks or cancels.
    final completer = Completer<Player?>();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.amberAccent,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10.0),
          const Text(
            "Select the player for the cup action:",
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: players.map((player) {
              return GestureDetector(
                onTap: () {
                  // Complete with this player's choice
                  if (!completer.isCompleted) {
                    completer.complete(player);
                  }
                  // Dismiss the dialog
                  Navigator.of(context).pop();
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4.0,
                  child: SizedBox(
                    width: 120.0,
                    height: 150.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35.0,
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(
                              Icons.person,
                              size: 50.0,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      btnCancelText: "Cancel",
      btnCancelOnPress: () {
        // If user cancels, we complete with null
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    ).show();

    // Return the Future that completes when user picks a player or cancels
    return completer.future;
  }

  /// Dialog for picking a player for the Death Cup rule.
  static Future<void> showDeathcupSelectionDialog(GameScreenState state,
      Team currentTeam, Function(Player) onselected) async {
    await DialogHelpers.showSelectionDialog(
        state.context, 'Select Player', currentTeam.currentPlayers, onselected);
  }

  static Future<void> highlightIslandCups(GameScreenState state) async {
    // logic for picking the island-shooter
  }

  /// Shows a dialog for rearrange-error if more than 6 cups remain.
  static Future<void> showRearrangeErrorDialog(GameScreenState state) async {
    AwesomeDialog(
      context: state.context,
      dialogType: DialogType.error,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.redAccent.shade100,
      body: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rearrange Error!',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.0),
          Text(
            'You can only rearrange if you have 6 or fewer cups!',
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.scatter_plot_outlined, size: 50.0, color: Colors.red),
              SizedBox(width: 10.0),
              Icon(Icons.arrow_forward_outlined, size: 50.0, color: Colors.red),
              SizedBox(width: 10.0),
              Icon(Icons.workspaces_outlined, size: 50.0, color: Colors.red),
            ],
          ),
          SizedBox(height: 20.0),
        ],
      ),
      btnCancelOnPress: () {},
      btnCancelText: "OK",
    ).show();
  }

  /// Confirmation dialog to end the turn.
  static Future<void> confirmEndTurn(GameScreenState state) async {
    AwesomeDialog(
      context: state.context,
      dialogType: DialogType.success,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.amberAccent.shade100,
      body: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'End your turn!',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.0),
          Text(
            'Confirm that all cup actions were selected!',
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle_outlined, size: 50.0, color: Colors.red),
              SizedBox(width: 10.0),
              Icon(Icons.circle_outlined, size: 50.0, color: Colors.green),
            ],
          ),
          SizedBox(height: 20.0),
        ],
      ),
      btnCancelOnPress: () {},
      btnCancelText: "Cancel",
      btnOkOnPress: () {
        state.saveCurrentState(GameEvent(eventType: "End Turn", team: state.currentTeam.color.value.toString()));
        state.endTurn();
      },
      btnOkText: "End Turn",
    ).show();
  }

  /// Shows an airball milestone dialog when airballs % 3 == 0.
  static Future<void> showAirballDialog(
      GameScreenState state, int airballs) async {
    AwesomeDialog(
      context: state.context,
      dialogType: DialogType.success,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.greenAccent.shade100,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Airball Milestone',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10.0),
          const Text(
            'All players need to drink a shot!',
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          Text('Total airballs: $airballs'),
          const SizedBox(height: 20.0),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wine_bar_outlined, size: 50.0, color: Colors.green),
            ],
          ),
          const SizedBox(height: 20.0),
        ],
      ),
      btnOkOnPress: () {},
      btnOkText: "OK",
    ).show();
  }

  /// Shows an AwesomeDialog indicating the team got Balls Back.
  static Future<void> showBallsBackDialog(GameScreenState state) async {
    AwesomeDialog(
      context: state.context,
      dialogType: DialogType.infoReverse,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.blueAccent.shade100,
      body: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Balls Back!',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.0),
          Text(
            'All players hit this round!',
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle_outlined, size: 50.0, color: Colors.green),
              SizedBox(width: 10.0),
              Icon(Icons.circle_outlined, size: 50.0, color: Colors.green),
            ],
          ),
          SizedBox(height: 20.0),
        ],
      ),
      btnOkOnPress: () {},
      btnOkText: "OK",
    ).show();
  }

  /// Shows an AwesomeDialog indicating the player is “On Fire.”
  static Future<void> showOnFireDialog(GameScreenState state) async {
    AwesomeDialog(
      context: state.context,
      dialogType: DialogType.success,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.redAccent.shade100,
      body: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'On Fire!',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.0),
          Text(
            'Three consecutive hits!',
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.0),
          Icon(Icons.fireplace_outlined, size: 50.0, color: Colors.red),
          SizedBox(height: 20.0),
        ],
      ),
      btnOkOnPress: () {},
      btnOkText: "OK",
    ).show();
  }

  /// Shows an AwesomeDialog for the “Bitch Cup.”
  static Future<void> showBitchCupDialog(GameScreenState state) async {
    AwesomeDialog(
      context: state.context,
      dialogType: DialogType.error,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.redAccent.shade100,
      body: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bitch Cup!',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.0),
          Text(
            'Drop your pants!',
            style: TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_walk_outlined,
                  size: 50.0, color: Colors.red),
              SizedBox(width: 10.0),
              Icon(Icons.arrow_downward_outlined,
                  size: 50.0, color: Colors.red),
              SizedBox(width: 10.0),
              Icon(Icons.dry_cleaning_outlined, size: 50.0, color: Colors.red),
            ],
          ),
          SizedBox(height: 20.0),
        ],
      ),
      btnCancelOnPress: () {},
      btnCancelText: "OK",
    ).show();
  }

  /// Shows the game-over dialog and navigates to Stats or Home screen.
  static Future<void> showGameEndDialog(
      BuildContext context, List<Player> players) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.topSlide,
      headerAnimationLoop: false,
      dialogBackgroundColor: Colors.amber.shade100,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Over',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10.0),
          Text(
            "${players.map((p) => p.name).join(', ')} have won the game!",
            style: const TextStyle(fontSize: 16.0, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(BeerpongIcons.medal, size: 50.0, color: Colors.amber),
              SizedBox(width: 10.0),
              Icon(BeerpongIcons.medal, size: 50.0, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 20.0),
        ],
      ),
      btnOkOnPress: () {
        // Go to Stats
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BaseScreen(selectedIndex: 3)),
        );
      },
      btnOkText: "Go to Stats",
      btnCancelOnPress: () {
        // Go to Home
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BaseScreen(selectedIndex: 2)),
        );
      },
      btnCancelText: "Go to Home",
    ).show();
  }
}
