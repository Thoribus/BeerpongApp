import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/player.dart';
import 'models/game_statistics.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Future<Database> get database async {
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'game_statistics.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE players ADD COLUMN team_id INTEGER');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE game_statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        winningTeam TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER,
        team_id INTEGER,
        name TEXT,
        score REAL,
        misses INTEGER,
        airballs INTEGER,
        FOREIGN KEY (game_id) REFERENCES game_statistics (id)
      )
    ''');
  }

  Future<int> insertGame(GameStatistics game) async {
    final db = await database;
    int gameId = await db.insert('game_statistics', {
      'date': game.date.toIso8601String(),
      'winningTeam': game.winningTeam,
    });

    for (var player in game.team1Players) {
      await db.insert('players', {
        'game_id': gameId,
        'team_id': 1,
        'name': player.name,
        'score': player.score,
        'misses': player.misses,
      });
    }

    for (var player in game.team2Players) {
      await db.insert('players', {
        'game_id': gameId,
        'team_id': 2,
        'name': player.name,
        'score': player.score,
        'misses': player.misses,
      });
    }

    return gameId;
  }

  Future<List<GameStatistics>> retrieveGames() async {
    final db = await database;
    final List<Map<String, dynamic>> games = await db.query('game_statistics');

    List<GameStatistics> gameList = [];

    for (var gameMap in games) {
      int gameId = gameMap['id'];
      List<Map<String, dynamic>> team1PlayersMap = await db.query(
        'players',
        where: 'game_id = ? and team_id = 1',
        whereArgs: [gameId],
      );
      List<Map<String, dynamic>> team2PlayersMap = await db.query(
        'players',
        where: 'game_id = ? and team_id = 2',
        whereArgs: [gameId],
      );

      List<Player> team1Players = team1PlayersMap.map((playerMap) {
        return Player(
          name: playerMap['name'],
          score: playerMap['score'],
          misses: playerMap['misses'],
        );
      }).toList();

      List<Player> team2Players = team2PlayersMap.map((playerMap) {
        return Player(
          name: playerMap['name'],
          score: playerMap['score'],
          misses: playerMap['misses'],
        );
      }).toList();

      GameStatistics game = GameStatistics(
        date: DateTime.parse(gameMap['date']),
        team1Players: team1Players,
        team2Players: team2Players,
        winningTeam: gameMap['winningTeam'],
      );

      gameList.add(game);
    }

    return gameList;
  }
}
