# BeerpongApp — Task Tracker

## 1. Game & Lobby Logic

- [X] **Fix Game Start Exception:** `removePlayer` now removes stale invite ID from `acceptedInvites`; `updateInvitationGameId` silently handles not-found.
- [X] **Bitchcup Event:** Fixed inverted condition — now checks that cup 4 is the last standing cup (all others invisible) instead of all cups being untouched.
- [X] **Lobby Spectate Transition:** Already correctly implemented via StreamBuilder in `ReadOnlyLobbyScreen`.
- [X] **Lobby Rules Live Sync:** `toggleRule` now calls `updateGameDoc()` so rule changes are persisted to Firestore and visible to spectators in real time.
- [X] **Lobby Kick Handling:** `ReadOnlyLobbyScreen` now listens to its invitation doc; navigates to home when invitation is deleted (kicked).
- [X] **Lobby Leave Action:** Host lobby now handles `cancelled` status (player left); clears their slot and updates game doc. `ReadOnlyLobbyScreen._cancel()` already worked correctly.
- [X] **Specify Spectate Bug:** Found and fixed two issues: (1) null crash when `timestamp` not yet set; (2) `_gameAlreadyOver` flag never set due to ordering bug, causing game-over dialog to appear for already-finished games.

## 2. Social & Friends
- [X] **Friend List Real-time Sync:** Fix the friend list stream/listener so it updates automatically when the current user is added by someone else.
- [X] **Add Friend 'Not Found' State:** Improve error handling and UI state when searching for a username that does not exist.
- [X] **Friend List Performance:** Investigate and optimize the performance issues related to rendering the friend list and adding new friends.

## 3. Profile & Achievements
- [X] **Achievements Progress Bar:** Fix the logic/UI for the achievement progress bar so it displays progress correctly.
- [X] **Achievements RenderFlex Overflow:** Fix the "yellow lines" (RenderFlex overflow) UI bug on the Achievements screen.
- [X] **Account Screen Performance:** Profile and resolve jank/performance issues on the Account screen.

## 4. System & Infrastructure
- [X] **Push Notifications:** Debug and fix the push notification configuration to ensure reliable message delivery.
