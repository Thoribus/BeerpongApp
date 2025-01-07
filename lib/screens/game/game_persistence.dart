import 'dart:convert';
import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/team.dart';

/// A helper class to save/load/clear the game state from SharedPreferences.
class GamePersistence {
  static const String _gameStateKey = 'currentGameState';

  /// Saves the entire game state (team1, team2, flags) as a single JSON string.
  static Future<void> saveGameState({
    required String id,
    required Team team1,
    required Team team2,
    required bool isTeamOneTurn,
    required bool islandShotActive,
    required List<String> invitations,
    required Map<String, bool> selectedRules,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Build a big map with all we need
    final Map<String, dynamic> gameMap = {
      'id': id,
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'isTeamOneTurn': isTeamOneTurn,
      'islandShotActive': islandShotActive,
      'invitations': invitations,
      'selectedRules': selectedRules,
    };

    final jsonString = json.encode(gameMap);
    await prefs.setString(_gameStateKey, jsonString);
  }

  /// Loads the entire game state from SharedPreferences (if present).
  /// If there's no saved data, returns null.
  static Future<Map<String, dynamic>?> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getString(_gameStateKey);
    if (savedState == null) {
      return null; // No saved data
    }

    // Convert JSON back into a Map
    final map = json.decode(savedState) as Map<String, dynamic>;
    return map;
  }

  /// Clears the entire game state
  static Future<void> clearGameState(bool deleteGame) async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getString(_gameStateKey);
    if (savedState == null) {
      return; // No saved data
    }

    // Delete the game doc from Firestore if we don't continue the ongoing game
    if (deleteGame) {
      final map = await loadGameState() as Map<String, dynamic>;
      final id = map['id'];
      FirestoreService().deleteGameDoc(id);
      final List<Invitation> invitations = await FirestoreService()
          .getGameInvitationsByGameId(id); // Get all invitations for this game
      for (final invitation in invitations) {
        FirestoreService().deleteGameInvitation(invitation.id);
      }
    }
    await prefs.remove(_gameStateKey);
  }
}
