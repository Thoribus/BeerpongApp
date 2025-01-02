import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/user.dart';

void main() {
  test('User toJson and fromJson', () {
    final user = User(
      id: '123',
      username: 'john_doe',
      totalScore: 100.0,
      totalMisses: 10,
      totalAirballs: 5,
      totalThrows: 50,
      onFire: 3,
      defended: 2,
      hitLastCup: 1,
      cupsHit: [1, 2, 3],
      wins: 10,
      losses: 5,
      friends: ['friend1', 'friend2'],
      icon: Icons.person,
      iconColor: Colors.blue,
    );
    final json = user.toJson();
    final newUser = User.fromJson(json);

    expect(newUser.id, user.id);
    expect(newUser.username, user.username);
    expect(newUser.totalScore, user.totalScore);
    expect(newUser.totalMisses, user.totalMisses);
    expect(newUser.totalAirballs, user.totalAirballs);
    expect(newUser.totalThrows, user.totalThrows);
    expect(newUser.onFire, user.onFire);
    expect(newUser.defended, user.defended);
    expect(newUser.hitLastCup, user.hitLastCup);
    expect(newUser.cupsHit, user.cupsHit);
    expect(newUser.wins, user.wins);
    expect(newUser.losses, user.losses);
    expect(newUser.friends, user.friends);
    expect(newUser.icon.codePoint, user.icon.codePoint);
    expect(newUser.iconColor, user.iconColor);
  });

  test('User copyWith', () {
    final user = User(
      id: '123',
      username: 'john_doe',
      totalScore: 100.0,
      totalMisses: 10,
      totalAirballs: 5,
      totalThrows: 50,
      onFire: 3,
      defended: 2,
      hitLastCup: 1,
      cupsHit: [1, 2, 3],
      wins: 10,
      losses: 5,
      friends: ['friend1', 'friend2'],
      icon: Icons.person,
      iconColor: Colors.blue,
    );
    final newUser = user.copyWith(
      username: 'jane_doe',
      totalScore: 200.0,
    );

    expect(newUser.id, user.id);
    expect(newUser.username, 'jane_doe');
    expect(newUser.totalScore, 200.0);
    expect(newUser.totalMisses, user.totalMisses);
    expect(newUser.totalAirballs, user.totalAirballs);
    expect(newUser.totalThrows, user.totalThrows);
    expect(newUser.onFire, user.onFire);
    expect(newUser.defended, user.defended);
    expect(newUser.hitLastCup, user.hitLastCup);
    expect(newUser.cupsHit, user.cupsHit);
    expect(newUser.wins, user.wins);
    expect(newUser.losses, user.losses);
    expect(newUser.friends, user.friends);
    expect(newUser.icon.codePoint, user.icon.codePoint);
    expect(newUser.iconColor, user.iconColor);
  });

  test('User winRate', () {
    final user = User(
      id: '123',
      username: 'john_doe',
      wins: 10,
      losses: 5,
    );
    expect(user.winRate, 10 / 15);
  });

  test('User winRate with no games', () {
    final user = User(
      id: '123',
      username: 'john_doe',
      wins: 0,
      losses: 0,
    );
    expect(user.winRate, 0.0);
  });
}
