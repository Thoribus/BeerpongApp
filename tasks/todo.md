# BeerpongApp — Task Tracker

## 1. Game & Lobby Logic
- [ ] **Fix Game Start Exception:** Handle `[cloud_firestore/not-found]` exception in `InvitationRepository.updateInvitationGameId` triggered from `_GameModeDetailsScreenState._onStartGame`.
- [ ] **Bitchcup Event:** Investigate and fix the issue where the "Bitchcup" dialog/event does not trigger during gameplay.
- [ ] **Lobby Spectate Transition:** Ensure users in the lobby screen correctly navigate to the Spectate view when the host starts the game.
- [ ] **Lobby Rules Live Sync:** Update the lobby screen to dynamically listen to and display changes in selected rules, rather than only showing the initial selection.
- [ ] **Lobby Kick Handling:** Listen for changes to the lobby state so that players are forcibly navigated away when the host kicks them from the lobby.
- [ ] **Lobby Leave Action:** Implement/fix the feature allowing invited players to manually leave the lobby screen.
- [ ] **Specify Spectate Bug:** Investigate and provide specifics for the unknown "spectate bug" to make it actionable.

## 2. Social & Friends
- [ ] **Friend List Real-time Sync:** Fix the friend list stream/listener so it updates automatically when the current user is added by someone else.
- [ ] **Add Friend 'Not Found' State:** Improve error handling and UI state when searching for a username that does not exist.
- [ ] **Friend List Performance:** Investigate and optimize the performance issues related to rendering the friend list and adding new friends.

## 3. Profile & Achievements
- [ ] **Achievements Progress Bar:** Fix the logic/UI for the achievement progress bar so it displays progress correctly.
- [ ] **Achievements RenderFlex Overflow:** Fix the "yellow lines" (RenderFlex overflow) UI bug on the Achievements screen.
- [ ] **Account Screen Performance:** Profile and resolve jank/performance issues on the Account screen.

## 4. System & Infrastructure
- [ ] **Push Notifications:** Debug and fix the push notification configuration to ensure reliable message delivery.
