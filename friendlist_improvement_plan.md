Audit Findings
Naming Convention
friendlist.dart violates Dart/Flutter convention — should be friends_screen.dart (snake_case, _screen suffix). The class FriendsListScreen is fine.
Friends Tab problems
N+1 Firestore reads: each friend card fires its own retrieveUserStatsWithDate query just to show a "last seen" date — expensive and slow
Add friend by raw Firebase UID — terrible UX; no username search
"last seen" shows absolute date (dd.MM.yyyy) — should be relative ("3 days ago")
No remove-friend action visible on cards
No head-to-head context on friend cards (you already computed it in BreakdownScreen but it's not surfaced here)
No recent form strip for friends
Leaderboard Tab problems
Only 2 sort criteria: Total Score, Win Rate — misses Hit Rate, On Fire, Bounce %, Win Streak
Amber ListTile sort control clashes with dark theme
Current user row not highlighted — hard to find yourself in the list
Hardcoded podium positions break on narrow screens
No rank-change indicator (↑↓ vs last session)
Socials Tab problems
Dead code: ActionType.achievement is defined and colored but never emitted
Feed is near-empty: "recently played a game" with a date — no score, no opponent, no outcome
No challenge / invite action from this surface
No streak or milestone events in the feed
Compare Screen
Already overhauled — no major issues.

Implementation Plan
Phase 1 — Rename & Quick Fixes (no new features)
Rename friendlist.dart → friends_screen.dart and update the import in router.dart / wherever it's referenced.
Relative timestamps: Replace DateFormat('dd.MM.yyyy').format(date) with a _timeAgo(DateTime) helper ('2d ago', 'just now', etc.).
Leaderboard sort control: Replace the amber ListTile+DropdownButton with themed filter chips (same style as the Performance tab) that include Hit Rate, On Fire, Bounce %, and Games Played as additional options.
Highlight current user in the leaderboard list with a distinct border/color so they can always locate themselves.
Fix dead code: Either emit ActionType.achievement from _buildFriendActions (e.g. when user.wins crossed a milestone), or remove the enum value and its color.
Phase 2 — Friend Card Overhaul
Batch load friends — load all friends in one call, then derive "last seen" from data already in the User document (e.g. a lastGameAt: Timestamp field updated by saveGame) rather than a per-friend stats query. Eliminates N+1.
Richer friend card — add per-card:
Mini W/L form strip (last 5 circles, computed from the user's local game list filtered by friend participants)
Head-to-head chip: "You: 3W – 1L" derived from games already loaded on StatisticsScreen; pass via constructor or compute from shared GameStatistics
Active indicator: green dot if last game within 7 days
Remove friend: swipe-to-dismiss (or long-press → context menu) with a confirmation dialog.
Phase 3 — Social Feed (Activity tab)
Replace the thin feed with rich activity cards:

Event type	Card content
Game played	Avatar · "Beat [opponent] 10–6 · 65% hit rate · 2d ago" + W/L badge
Win streak	🔥 "On a 4-game win streak" milestone card
Achievement unlocked	🏆 "[Friend] unlocked 'On Fire' (50 times)"
New friend added	👥 "[Friend] joined your network"
Tap a game card → navigate to that game's spectate/history view
Tap a friend's name → compare screen
"Play again" action button on recent shared-game cards
Phase 4 — Add Friend UX
Replace raw UID entry with:

Username search — a TextField that fires a Firestore query on users collection by username field (requires a Firestore index on username)
Search results list — shows avatar + username + title; tap to send a friend request
Keep QR scan as the secondary option
Share your profile link — deep link (beerpongapp://user/{id}) or a simple share sheet with your QR code
Phase 5 — Challenge System (new)
A Challenge is a lightweight document in a new challenges collection:


challenges/{id}: {
  fromUserId, fromUsername,
  toUserId,
  status: 'pending' | 'accepted' | 'declined',
  createdAt
}
Friend card gains a ⚡ Challenge button → creates the document + sends FCM notification
The recipient sees a badge on the Friends tab and a card in the Social feed: "Alice challenged you to a game" → tap → launches GameModeDetailsScreen pre-filled with Alice as an invited player
Declined challenges auto-delete after 48 h
Files to create / modify
File	Change
friendlist.dart → friends_screen.dart	Rename
friends_screen.dart	Relative timestamps, batch load, rich cards, swipe-to-delete, themed sort chips, user highlight
friends_screen.dart	Rich social feed (Phase 3)
friends_screen.dart	Username search in add-friend dialog (Phase 4)
lib/models/user.dart	Add lastGameAt: DateTime? written by saveGame
lib/util/repositories/friend_repository.dart	searchByUsername(String q) method
lib/util/repositories/friend_repository.dart	removeFriend method (if not present)
lib/models/challenge.dart	CREATE — new model
lib/util/repositories/challenge_repository.dart	CREATE — Firestore CRUD for challenges
lib/util/router.dart	Update import path after rename