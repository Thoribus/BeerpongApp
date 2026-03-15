import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';

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
            'Select the player for the cup action:',
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
                child: _buildPlayerName(player),
              );
            }).toList(),
          ),
        ],
      ),
      btnCancelOnPress: () {},
      btnCancelText: 'Cancel',
    ).show().ignore();
  }

  /// Dialog to pick a player for the Airball rule.
  static Future<void> showAirballPlayerSelectionDialog(
    BuildContext context,
    Team currentTeam,
    Function(Player) onSelected,
  ) async {
    await DialogHelpers.showSelectionDialog(
      context,
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
            'Select the player for the cup action:',
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
                  if (!completer.isCompleted) {
                    completer.complete(player);
                  }
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
      btnCancelText: 'Cancel',
      btnCancelOnPress: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    ).show().ignore();

    return completer.future;
  }

  /// Dialog for picking a player for the Death Cup rule.
  static Future<void> showDeathcupSelectionDialog(
    BuildContext context,
    Team currentTeam,
    Function(Player) onSelected,
  ) async {
    await DialogHelpers.showSelectionDialog(
      context,
      'Select Player',
      currentTeam.currentPlayers,
      onSelected,
    );
  }

  /// Shows a dialog for rearrange-error if more than 6 cups remain.
  static Future<void> showRearrangeErrorDialog(BuildContext context) async {
    AwesomeDialog(
      context: context,
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
      btnCancelText: 'OK',
    ).show().ignore();
  }

  /// Confirmation dialog to end the turn.
  static Future<void> confirmEndTurn(BuildContext context, GameController ctrl) async {
    AwesomeDialog(
      context: context,
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
      btnCancelText: 'Cancel',
      btnOkOnPress: () {
        ctrl.saveCurrentState();
        ctrl.endTurn();
      },
      btnOkText: 'End Turn',
    ).show().ignore();
  }

  /// Shows an airball milestone dialog when airballs % 3 == 0.
  static Future<void> showAirballDialog(BuildContext context, int airballs) async {
    AwesomeDialog(
      context: context,
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
      btnOkText: 'OK',
    ).show().ignore();
  }

  /// Shows an AwesomeDialog indicating the team got Balls Back.
  static Future<void> showBallsBackDialog(BuildContext context) async {
    AwesomeDialog(
      context: context,
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
      btnOkText: 'OK',
    ).show().ignore();
  }

  /// Shows an AwesomeDialog indicating the player is "On Fire."
  static Future<void> showOnFireDialog(BuildContext context) async {
    AwesomeDialog(
      context: context,
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
      btnOkText: 'OK',
    ).show().ignore();
  }

  /// Shows an AwesomeDialog for the "Bitch Cup."
  static Future<void> showBitchCupDialog(BuildContext context) async {
    AwesomeDialog(
      context: context,
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
              Icon(Icons.directions_walk_outlined, size: 50.0, color: Colors.red),
              SizedBox(width: 10.0),
              Icon(Icons.arrow_downward_outlined, size: 50.0, color: Colors.red),
              SizedBox(width: 10.0),
              Icon(Icons.dry_cleaning_outlined, size: 50.0, color: Colors.red),
            ],
          ),
          SizedBox(height: 20.0),
        ],
      ),
      btnCancelOnPress: () {},
      btnCancelText: 'OK',
    ).show().ignore();
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
            '${players.map((p) => p.name).join(', ')} have won the game!',
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
        context.go('/games');
      },
      btnOkText: 'Go to Stats',
      btnCancelOnPress: () {
        context.go('/home');
      },
      btnCancelText: 'Go to Home',
    ).show().ignore();
  }
}

Widget _buildPlayerName(Player player) {
  return Container(
    padding: const EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      color: Colors.brown.shade600,
      border: Border.all(
        color: Colors.grey.withValues(alpha: 0.5),
        width: 0.5,
      ),
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Row(
      children: [
        player.user == null
            ? const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: SvgPicture.asset(
                    player.user!.mapAvatarKeyToAsset(),
                    fit: BoxFit.cover,
                    width: 20 * 2,
                    height: 20 * 2,
                  ),
                ),
              ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name.length > 13
                    ? '${player.name.substring(0, 12)}...'
                    : player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              const Text(
                'Title: X',
                style: TextStyle(color: Colors.grey, fontSize: 12.0),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
