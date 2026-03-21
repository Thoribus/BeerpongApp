/// Centralised route path constants.
///
/// Use [AppRoutes.*] everywhere instead of string literals so that typos are
/// caught at compile time and path changes are made in one place.
abstract final class AppRoutes {
  static const login         = '/login';
  static const home          = '/home';
  static const shop          = '/shop';
  static const friends       = '/friends';
  static const games         = '/games';
  static const profile       = '/profile';
  static const game          = '/game';
  static const gameMode      = '/game-mode';
  static const tournament    = '/tournament/:id';
  static const spectateLobby = '/spectate-lobby/:gameId';
  static const spectateLive  = '/spectate-live/:gameId';
  static const compare       = '/compare';
  static const invitations   = '/invitations';
  static const waiting       = '/waiting';
  static const achievements  = '/achievements';

  // Parameterised helpers
  static String tournamentPath(String id)       => '/tournament/$id';
  static String spectateLobbyPath(String gameId) => '/spectate-lobby/$gameId';
  static String spectateLivePath(String gameId)  => '/spectate-live/$gameId';
}
