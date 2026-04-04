import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/repositories/friend_repository.dart';
import 'package:beerpongapp/repositories/game_repository.dart';
import 'package:beerpongapp/repositories/invitation_repository.dart';
import 'package:beerpongapp/repositories/tournament_repository.dart';
import 'package:beerpongapp/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore access facade. Delegates to domain repositories.
///
/// Use [FirestoreService.instance] — do not instantiate directly.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  // ----- User -----

  Future<void> addUser(User user) => UserRepository.instance.addUser(user);

  Future<void> updateUser(User user) =>
      UserRepository.instance.updateUser(user);

  Future<User?> getUser(String userId) =>
      UserRepository.instance.getUser(userId);

  Future<void> deleteUser(String userId) =>
      UserRepository.instance.deleteUser(userId);

  Future<void> setActiveGameId(String userId, String gameId) =>
      UserRepository.instance.setActiveGameId(userId, gameId);

  Future<void> clearActiveGameId(String userId) =>
      UserRepository.instance.clearActiveGameId(userId);

  Future<bool> checkUsernameAvailable(
          String usernameLower, String currentUserId) =>
      UserRepository.instance
          .checkUsernameAvailable(usernameLower, currentUserId);

  Future<void> claimUsername({
    required String newUsername,
    required String oldUsernameLower,
    required String uid,
  }) =>
      UserRepository.instance.claimUsername(
        newUsername: newUsername,
        oldUsernameLower: oldUsernameLower,
        uid: uid,
      );

  Future<List<User>> saveGame({
    required List<Player> team1,
    required List<Player> team2,
  }) =>
      UserRepository.instance.saveGame(team1: team1, team2: team2);

  Future<void> spendStars({
    required String userId,
    required int amount,
    required String itemId,
  }) =>
      UserRepository.instance
          .spendStars(userId: userId, amount: amount, itemId: itemId);

  Future<void> equipItem({
    required String userId,
    required String field,
    required String? itemId,
  }) =>
      UserRepository.instance
          .equipItem(userId: userId, field: field, itemId: itemId);

  Future<void> creditStars({
    required String userId,
    required int amount,
  }) =>
      UserRepository.instance.creditStars(userId: userId, amount: amount);

  static User mapPlayerToUser(Player player) =>
      UserRepository.mapPlayerToUser(player);

  // ----- Game -----

  Future<String> createEmptyGameDoc({
    required Team team1,
    required Team team2,
  }) =>
      GameRepository.instance.createEmptyGameDoc(team1: team1, team2: team2);

  Future<void> updateGameDoc(
    String gameId, {
    Team? team1,
    Team? team2,
    String? winner,
    List<String>? invitations,
    List<String>? rules,
    String? gameMode,
    bool? started,
    String? startingTeam,
    bool? timestamp,
    String? tournamentId,
    bool? endedAt,
    int? roundCount,
    int? cupsRemainingWinner,
  }) =>
      GameRepository.instance.updateGameDoc(
        gameId,
        team1: team1,
        team2: team2,
        winner: winner,
        invitations: invitations,
        rules: rules,
        gameMode: gameMode,
        started: started,
        startingTeam: startingTeam,
        timestamp: timestamp,
        tournamentId: tournamentId,
        endedAt: endedAt,
        roundCount: roundCount,
        cupsRemainingWinner: cupsRemainingWinner,
      );

  Stream<DocumentSnapshot> getGameDocStream(String gameId) =>
      GameRepository.instance.getGameDocStream(gameId);

  Future<void> deleteGameDoc(String gameId) =>
      GameRepository.instance.deleteGameDoc(gameId);

  Future<Map<String, dynamic>?> retrieveGameById(String gameId) =>
      GameRepository.instance.retrieveGameById(gameId);

  Future<List<GameStatistics>> retrieveGames(User user) =>
      GameRepository.instance.retrieveGames(user);

  Future<List<UserStatsInGame>> retrieveUserStatsWithDate(User user) =>
      GameRepository.instance.retrieveUserStatsWithDate(user);

  Future<String> addEvent(
          String gameId, String eventType, Team team, Player? player,
          {int? roundNumber}) =>
      GameRepository.instance
          .addEvent(gameId, eventType, team, player, roundNumber: roundNumber);

  Future<List<GameEvent>> getEvents(String gameId) =>
      GameRepository.instance.getEvents(gameId);

  Future<void> deleteEvent(String gameId, String eventId) =>
      GameRepository.instance.deleteEvent(gameId, eventId);

  // ----- Friends -----

  Stream<List<String>> streamFriendIds(String userId) =>
      FriendRepository.instance.streamFriendIds(userId);

  Future<List<User>> getFriends(String userId) =>
      FriendRepository.instance.getFriends(userId);

  Future<void> addFriend(String userId, String friendId) =>
      FriendRepository.instance.addFriend(userId, friendId);

  Future<void> removeFriend(String userId, String friendId) =>
      FriendRepository.instance.removeFriend(userId, friendId);

  Future<List<User>> searchUsers(String query, {required String excludeId}) =>
      UserRepository.instance.searchUsers(query, excludeId: excludeId);

  // ----- Invitations -----

  Future<String> sendGameInvitation({
    required String fromUserId,
    required String toUserId,
    required int teamNumber,
    required int playerIndex,
    required String gameId,
    String fromUsername = '',
    String tournamentId = '',
    String gameType = 'regular',
  }) =>
      InvitationRepository.instance.sendGameInvitation(
        fromUserId: fromUserId,
        fromUsername: fromUsername,
        toUserId: toUserId,
        teamNumber: teamNumber,
        playerIndex: playerIndex,
        gameId: gameId,
        tournamentId: tournamentId,
        gameType: gameType,
      );

  Future<void> updateInvitationStatus(
          String invitationId, String newStatus) =>
      InvitationRepository.instance
          .updateInvitationStatus(invitationId, newStatus);

  Future<void> updateInvitationGameId(
          String invitationId, String gameId) =>
      InvitationRepository.instance
          .updateInvitationGameId(invitationId, gameId);

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamInvitation(
          String invitationId) =>
      InvitationRepository.instance.streamInvitation(invitationId);

  Future<void> deleteGameInvitation(String invitationId) =>
      InvitationRepository.instance.deleteGameInvitation(invitationId);

  Future<List<Invitation>> getGameInvitations(String userId) =>
      InvitationRepository.instance.getGameInvitations(userId);

  Future<List<Invitation>> getGameInvitationsByGameId(String gameId) =>
      InvitationRepository.instance.getGameInvitationsByGameId(gameId);

  Future<List<Invitation>> getAllInvitations(String userId) =>
      InvitationRepository.instance.getAllInvitations(userId);

  /// Real-time stream of pending invitations for [userId].
  Stream<List<Invitation>> pendingInvitationsStream(String userId) =>
      InvitationRepository.instance.pendingInvitationsStream(userId);

  // ----- FCM tokens -----

  Future<void> saveFcmToken(String userId, String token) =>
      UserRepository.instance.saveFcmToken(userId, token);

  Future<void> removeFcmToken(String userId, String token) =>
      UserRepository.instance.removeFcmToken(userId, token);

  // ----- Tournaments -----

  Future<String> createTournament(Tournament tournament) =>
      TournamentRepository.instance.createTournament(tournament);

  Future<void> updateTournament(Tournament tournament) =>
      TournamentRepository.instance.updateTournament(tournament);

  Future<Tournament?> getTournament(String tournamentId) =>
      TournamentRepository.instance.getTournament(tournamentId);

  Future<void> deleteTournament(String tournamentId) =>
      TournamentRepository.instance.deleteTournament(tournamentId);

  Future<List<Tournament>> getTournamentsForUser(String userId) =>
      TournamentRepository.instance.getTournamentsForUser(userId);

  Future<String> addMatchToTournament(
          String tournamentId, TournamentMatch match) =>
      TournamentRepository.instance
          .addMatchToTournament(tournamentId, match);

  Future<void> updateTournamentMatch(
          String tournamentId, TournamentMatch match) =>
      TournamentRepository.instance
          .updateTournamentMatch(tournamentId, match);

  Future<List<TournamentMatch>> getTournamentMatches(String tournamentId) =>
      TournamentRepository.instance.getTournamentMatches(tournamentId);

  Future<TournamentMatch?> getTournamentMatch(
          String tournamentId, String matchId) =>
      TournamentRepository.instance
          .getTournamentMatch(tournamentId, matchId);

  // ----- Feedback -----

  Future<void> submitFeedback({
    required String userId,
    required String username,
    required String platform,
    required String category,
    required String message,
  }) =>
      FirebaseFirestore.instance.collection('feedback').add({
        'userId': userId,
        'username': username,
        'platform': platform,
        'category': category,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
