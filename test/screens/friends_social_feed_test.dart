import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

User _user(String id, {int wins = 0, int onFire = 0, DateTime? lastGameAt}) =>
    User(
        id: id,
        username: id,
        wins: wins,
        onFire: onFire,
        lastGameAt: lastGameAt);

GameStatistics _game(
  String gameId, {
  required String userId,
  required String friendId,
  required bool userWon,
  DateTime? date,
}) {
  return GameStatistics(
    id: gameId,
    date: date ?? DateTime.now(),
    winningTeam: userWon ? 'Team 1' : 'Team 2',
    team1Players: [
      Player(
        name: userId,
        score: userWon ? 10 : 6,
        throws: 20,
        user: User(id: userId, username: userId),
      ),
    ],
    team2Players: [
      Player(
        name: friendId,
        score: userWon ? 6 : 10,
        throws: 20,
        user: User(id: friendId, username: friendId),
      ),
    ],
    participants: [userId, friendId],
  );
}

// ---------------------------------------------------------------------------
// Pure-logic feed event tests (inline the same algorithm as _buildFeedEvents)
// ---------------------------------------------------------------------------

// Mirrors the production logic so we can test it without a running widget tree.
List<
    ({
      String type,
      String title,
      String? friendId,
      bool? userWon,
      DateTime date
    })> _computeEvents(
  List<User> friends,
  List<GameStatistics> myGames,
  String currentUserId,
) {
  final results = <({
    String type,
    String title,
    String? friendId,
    bool? userWon,
    DateTime date
  })>[];
  final friendById = {for (final f in friends) f.id: f};

  // Shared-game events
  for (final game in myGames) {
    for (final pid in game.participants) {
      if (pid == currentUserId) continue;
      final friend = friendById[pid];
      if (friend == null) continue;
      final onTeam1 = game.team1Players.any((p) => p.user?.id == currentUserId);
      final userWon = game.winningTeam == (onTeam1 ? 'Team 1' : 'Team 2');
      results.add((
        type: 'sharedGame',
        title:
            userWon ? 'Beat ${friend.username}' : 'Lost to ${friend.username}',
        friendId: friend.id,
        userWon: userWon,
        date: game.date,
      ));
    }
  }

  // Win streak
  final sorted = [...myGames]..sort((a, b) => b.date.compareTo(a.date));
  var streak = 0;
  for (final g in sorted) {
    final onTeam1 = g.team1Players.any((p) => p.user?.id == currentUserId);
    final won = g.winningTeam == (onTeam1 ? 'Team 1' : 'Team 2');
    if (won) {
      streak++;
    } else {
      break;
    }
  }
  if (streak >= 3) {
    results.add((
      type: 'winStreak',
      title: '🔥 $streak-game win streak!',
      friendId: null,
      userWon: null,
      date: sorted.isNotEmpty ? sorted.first.date : DateTime.now(),
    ));
  }

  // Achievements
  const winMilestones = [200, 100, 50, 25, 10];
  const fireMilestones = [100, 50, 25];
  for (final friend in friends) {
    for (final m in winMilestones) {
      if (friend.wins >= m) {
        results.add((
          type: 'achievement',
          title: '🏆 ${friend.username} reached $m wins',
          friendId: friend.id,
          userWon: null,
          date: friend.lastGameAt ?? DateTime.now(),
        ));
        break;
      }
    }
    for (final m in fireMilestones) {
      if (friend.onFire >= m) {
        results.add((
          type: 'achievement',
          title: '🔥 ${friend.username} went on fire $m+ times',
          friendId: friend.id,
          userWon: null,
          date: friend.lastGameAt ?? DateTime.now(),
        ));
        break;
      }
    }
  }

  // Friend active (≤ 3 days)
  for (final friend in friends) {
    if (friend.lastGameAt != null &&
        DateTime.now().difference(friend.lastGameAt!).inDays <= 3) {
      results.add((
        type: 'friendActive',
        title: '${friend.username} is active',
        friendId: friend.id,
        userWon: null,
        date: friend.lastGameAt!,
      ));
    }
  }

  results.sort((a, b) => b.date.compareTo(a.date));
  return results;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Social feed — shared game events', () {
    test('generates a "Beat" event when user won', () {
      final friend = _user('f1');
      final games = [
        _game('g1', userId: 'u1', friendId: 'f1', userWon: true),
      ];
      final events = _computeEvents([friend], games, 'u1');
      expect(events.any((e) => e.type == 'sharedGame' && e.title == 'Beat f1'),
          isTrue);
    });

    test('generates a "Lost to" event when user lost', () {
      final friend = _user('f1');
      final games = [
        _game('g1', userId: 'u1', friendId: 'f1', userWon: false),
      ];
      final events = _computeEvents([friend], games, 'u1');
      expect(
          events.any((e) => e.type == 'sharedGame' && e.title == 'Lost to f1'),
          isTrue);
    });

    test('generates no shared events when no games overlap with friends', () {
      final friend = _user('f1');
      // Game with a stranger, not f1
      final games = [
        _game('g1', userId: 'u1', friendId: 'stranger', userWon: true),
      ];
      final events = _computeEvents([friend], games, 'u1');
      expect(events.where((e) => e.type == 'sharedGame'), isEmpty);
    });

    test('generates one event per friend per shared game', () {
      final f1 = _user('f1');
      final f2 = _user('f2');
      final game = GameStatistics(
        id: 'g1',
        date: DateTime.now(),
        winningTeam: 'Team 1',
        team1Players: [
          Player(name: 'u1', user: User(id: 'u1', username: 'u1')),
          Player(name: 'f1', user: User(id: 'f1', username: 'f1')),
        ],
        team2Players: [
          Player(name: 'f2', user: User(id: 'f2', username: 'f2')),
        ],
        participants: ['u1', 'f1', 'f2'],
      );
      final events = _computeEvents([f1, f2], [game], 'u1');
      final shared = events.where((e) => e.type == 'sharedGame').toList();
      // f1 is teammate (also in participants), f2 is opponent
      expect(shared.length, 2);
    });
  });

  group('Social feed — win streak', () {
    test('no streak event when fewer than 3 consecutive wins', () {
      final games = [
        _game('g1',
            userId: 'u1',
            friendId: 'f1',
            userWon: true,
            date: DateTime.now().subtract(const Duration(days: 2))),
        _game('g2',
            userId: 'u1',
            friendId: 'f1',
            userWon: true,
            date: DateTime.now().subtract(const Duration(days: 1))),
      ];
      final events = _computeEvents([_user('f1')], games, 'u1');
      expect(events.any((e) => e.type == 'winStreak'), isFalse);
    });

    test('streak event appears for 3 consecutive wins', () {
      final games = [
        _game('g1',
            userId: 'u1',
            friendId: 'f1',
            userWon: true,
            date: DateTime.now().subtract(const Duration(days: 3))),
        _game('g2',
            userId: 'u1',
            friendId: 'f1',
            userWon: true,
            date: DateTime.now().subtract(const Duration(days: 2))),
        _game('g3',
            userId: 'u1',
            friendId: 'f1',
            userWon: true,
            date: DateTime.now().subtract(const Duration(days: 1))),
      ];
      final events = _computeEvents([_user('f1')], games, 'u1');
      expect(events.any((e) => e.type == 'winStreak'), isTrue);
      expect(events.any((e) => e.title == '🔥 3-game win streak!'), isTrue);
    });

    test('streak breaks on a loss', () {
      final games = [
        _game('g1',
            userId: 'u1',
            friendId: 'f1',
            userWon: true,
            date: DateTime.now().subtract(const Duration(days: 3))),
        _game('g2',
            userId: 'u1',
            friendId: 'f1',
            userWon: false,
            date: DateTime.now().subtract(const Duration(days: 2))),
        _game('g3',
            userId: 'u1',
            friendId: 'f1',
            userWon: true,
            date: DateTime.now().subtract(const Duration(days: 1))),
        _game('g4',
            userId: 'u1', friendId: 'f1', userWon: true, date: DateTime.now()),
      ];
      final events = _computeEvents([_user('f1')], games, 'u1');
      // Only 2 wins at the end — no streak event
      expect(events.any((e) => e.type == 'winStreak'), isFalse);
    });
  });

  group('Social feed — achievements', () {
    test('shows highest win milestone only', () {
      // Friend has 60 wins → should show 50-win card, not 25 or 10
      final friend = _user('f1', wins: 60);
      final events = _computeEvents([friend], [], 'u1');
      final ach = events.where((e) => e.type == 'achievement').toList();
      expect(ach.length, 1);
      expect(ach.first.title, '🏆 f1 reached 50 wins');
    });

    test('no achievement when wins below lowest milestone', () {
      final friend = _user('f1', wins: 5);
      final events = _computeEvents([friend], [], 'u1');
      expect(events.where((e) => e.type == 'achievement'), isEmpty);
    });

    test('shows 200-win milestone for top-tier player', () {
      final friend = _user('f1', wins: 250);
      final events = _computeEvents([friend], [], 'u1');
      final ach = events.where((e) => e.type == 'achievement').toList();
      expect(ach.first.title, '🏆 f1 reached 200 wins');
    });

    test('shows on-fire milestone achievement card', () {
      final friend = _user('f1', onFire: 80);
      final events = _computeEvents([friend], [], 'u1');
      expect(
        events.any((e) =>
            e.type == 'achievement' &&
            e.title == '🔥 f1 went on fire 50+ times'),
        isTrue,
      );
    });

    test('can emit both win and on-fire achievements for one friend', () {
      final friend = _user('f1', wins: 120, onFire: 60);
      final events = _computeEvents([friend], [], 'u1');
      final ach = events.where((e) => e.type == 'achievement').toList();
      expect(ach.length, 2);
      expect(ach.any((e) => e.title == '🏆 f1 reached 100 wins'), isTrue);
      expect(ach.any((e) => e.title == '🔥 f1 went on fire 50+ times'), isTrue);
    });
  });

  group('Social feed — friend active', () {
    test('shows friendActive event when lastGameAt within 3 days', () {
      final friend = _user('f1',
          lastGameAt: DateTime.now().subtract(const Duration(days: 2)));
      final events = _computeEvents([friend], [], 'u1');
      expect(events.any((e) => e.type == 'friendActive' && e.friendId == 'f1'),
          isTrue);
    });

    test('no friendActive event when lastGameAt is null', () {
      final friend = _user('f1');
      final events = _computeEvents([friend], [], 'u1');
      expect(events.any((e) => e.type == 'friendActive'), isFalse);
    });

    test('no friendActive event when lastGameAt is 5 days ago', () {
      final friend = _user('f1',
          lastGameAt: DateTime.now().subtract(const Duration(days: 5)));
      final events = _computeEvents([friend], [], 'u1');
      expect(events.any((e) => e.type == 'friendActive'), isFalse);
    });

    test('shows friendActive event when lastGameAt is exactly 3 days ago', () {
      final friend = _user(
        'f1',
        lastGameAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      final events = _computeEvents([friend], [], 'u1');
      expect(events.any((e) => e.type == 'friendActive'), isTrue);
    });
  });

  group('Social feed — sorting', () {
    test('events are sorted descending by date', () {
      final now = DateTime.now();
      final friend = _user('f1',
          wins: 60, lastGameAt: now.subtract(const Duration(hours: 1)));
      final events = _computeEvents(
        [friend],
        [
          _game('g-old',
              userId: 'u1',
              friendId: 'f1',
              userWon: true,
              date: now.subtract(const Duration(days: 5))),
        ],
        'u1',
      );
      for (int i = 1; i < events.length; i++) {
        expect(
            events[i - 1].date.isAfter(events[i].date) ||
                events[i - 1].date == events[i].date,
            isTrue);
      }
    });
  });

}
