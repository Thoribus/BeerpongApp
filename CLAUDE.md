# CLAUDE.md — BeerpongApp + RuFlo V3

This file provides guidance to Claude Code when working with this repository. **Always use claude-flow (RuFlo V3) for every task.**

## Behavioral Rules (Always Enforced)

- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested
- NEVER commit secrets, credentials, or .env files
- ALWAYS read a file before editing it
- Never continuously check status after spawning a swarm — wait for results

## Always Use claude-flow

For every prompt, use claude-flow swarm orchestration:

```bash
# Initialize a swarm for complex tasks
npx @claude-flow/cli@latest swarm init --topology hierarchical --max-agents 8 --strategy specialized

# Spawn agents for specific roles
npx @claude-flow/cli@latest agent spawn -t coder --name my-coder
npx @claude-flow/cli@latest agent spawn -t reviewer --name my-reviewer

# Memory operations
npx @claude-flow/cli@latest memory search --query "relevant pattern"
npx @claude-flow/cli@latest memory store --key "key" --value "value" --namespace patterns
```

### 3-Tier Model Routing

| Tier | Handler | Use Cases |
|------|---------|-----------|
| **1** | Agent Booster (WASM) | Simple transforms — skip LLM |
| **2** | Haiku | Simple tasks, low complexity (<30%) |
| **3** | Sonnet/Opus | Complex reasoning, architecture, security (>30%) |

- Always check for `[AGENT_BOOSTER_AVAILABLE]` or `[TASK_MODEL_RECOMMENDATION]` before spawning agents

### Concurrency Rules

- All operations MUST be concurrent/parallel in a single message
- ALWAYS batch ALL todos in ONE TodoWrite call
- ALWAYS spawn ALL agents in ONE message with full instructions via Task tool
- ALWAYS batch ALL file reads/writes/edits in ONE message
- ALWAYS batch ALL Bash commands in ONE message
- Use `run_in_background: true` for all agent Task calls

### Swarm Anti-Drift

- ALWAYS use hierarchical topology for coding swarms
- Keep maxAgents at 6-8 for tight coordination
- Use `raft` consensus for hive-mind
- Keep shared memory namespace for all agents

## Flutter Commands

```bash
# Install dependencies
flutter pub get

# Run the app (connected device or emulator required)
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/foo_test.dart

# Analyze / lint
flutter analyze

# Build Android release bundle (CI uses this)
flutter build appbundle --release --no-tree-shake-icons
```

## Architecture

### Entry point & providers
`lib/main.dart` initializes Firebase and wraps the app in two global providers:
- **`UserProvider`** (`lib/util/user_provider.dart`) — holds the signed-in `User`, handles Google Sign-In / Firebase Auth, and exposes `signIn()` / `signOut()` / `updateUser()`.
- **`ThemeProvider`** (`lib/util/theme_provider.dart`) — toggles light/dark mode. Theme definitions live in `lib/theme.dart` (`AppTheme.light` / `AppTheme.dark`).

### Navigation shell
`lib/screens/base/base_screen.dart` is the top-level shell. It renders a 5-tab bottom nav via `StatefulShellRoute.indexedStack`:

| Index | Screen | Route |
|-------|--------|-------|
| 0 | `ShopScreen` | `/shop` |
| 1 | `FriendsListScreen` | `/friends` |
| 2 | `HomeScreen` | `/home` |
| 3 | `StatisticsScreen` | `/games` |
| 4 | `AccountScreen` | `/profile` |

#### GoRouter + `refreshListenable` pitfall
`UserProvider` is passed as `refreshListenable` to GoRouter. Any call to `UserProvider.updateUser()` triggers `notifyListeners()`, which causes GoRouter to re-evaluate all redirects and rebuild the current route's widget tree. **Do not call `updateUser()` while a dialog is visible** — it will dispose the dialog's `BuildContext` mid-flight, crashing AwesomeDialog's `dismiss()`. Always call `updateUser()` after navigation has completed.

### Data layer
**`FirestoreService`** (`lib/util/firestoreservice.dart`) is the single Firestore access point. It is instantiated inline (not injected) wherever needed. It covers:
- Users: CRUD on `users` collection
- Games: `games` collection with sub-collection `events`
- Friends: stored as arrays on user documents
- Invitations: `invitations` collection
- Tournaments: `tournaments` collection with sub-collection `matches`

**`GamePersistence`** (`lib/screens/game/game_persistence.dart`) serializes active game state to `SharedPreferences` so a game survives app restarts. It is keyed under `currentGameState`.

### Models (`lib/models/`)
- `User` — account data + cumulative stats (wins, losses, totalScore, cupsHit, etc.)
- `Player` — in-game representation of a user or guest; stats accumulated during a game and merged into `User` on `FirestoreService.saveGame()`
- `Team` — color-identified list of `Player`s
- `Cup` — individual cup state (hit, defended, island)
- `GameStatistics` — read-only view of a completed game from Firestore
- `Tournament` / `TournamentMatch` — bracket data
- `GameEvent` — timeline event stored in the `events` sub-collection
- `Invitation` — pending game invite between users

### Game flow
`HomeScreen` → `GameModeDetailsScreen` → `GameScreen`.
`GameScreen` (`lib/screens/game/game_screen.dart`) owns all live game state. It uses:
- `dialog_helpers.dart` for rule/scoring dialogs
- `game_persistence.dart` to checkpoint state
- `FirestoreService.getGameDocStream()` for real-time Firestore updates (spectators via `lib/screens/liveticker/`)

### Game mechanics — scoring rules

All scoring calls go through `GameController` accessor methods (`incrementPlayerScore`, `incrementPlayerThrows`, etc.) which each call `notifyListeners()`. Never mutate `Player` fields directly from `GameScreen`.

#### Normal hit (`_handleNormalHit`)
- `+1` throw, `+1` hit-this-round, `+1` score, cup turns green.
- Green cups are hidden (`isVisible = false`) at `endTurn()`.

#### Bomb (hitting a green/already-sunk cup)
Detected in `_handleNormalHit` by checking `cup.color == Colors.green` before calling `handleCupHit`.
- The bombed cup is **not scored and not removed** — `_checkProximity` restores it to the team colour so it stays visible.
- `_checkProximity` marks all physically adjacent cups green (removed at end-turn).
- Score awarded = `(adjacentHits − 1) / players.length` per player. The `−1` offsets the `+1` already given to the original hitter when they first sank that cup.
- Hit-rate tracking (`cupsHit`) is still updated for the bomber.

#### Bounce shot (`_handleBounceCupTap`)
- `+1` throw, `+1` score for the primary cup, plus a random second cup is also removed (`+1` score).
- Total: `+1` throw, `+2` score.

#### Island shot (`handleIslandShot`)
- If the throwing player **is** the designated island shooter: hits the target cup + a random bonus cup (`+2` score, `+1` throw).
- Otherwise: standard `+1` score, `+1` throw.

#### Death cup (`_handleDeathCup`)
- One throw triggered it — `incrementPlayerThrows` and `incrementPlayerHitThisRound` are called **once** before the loop.
- All remaining non-green cups are cleared in the loop (`+1` score per cup); **no extra throws** are added per cup.

### Logging
Use `AppLogger` (`lib/util/app_logger.dart`) — never `print()`. Methods: `AppLogger.debug()`, `.info()`, `.warning()`, `.error(message, [error, stackTrace])`.

## CI / CD
`.github/workflows/main.yml` triggers on push to `main`: builds a signed AAB and uploads it to the Google Play **internal** track. Signing credentials come from repository secrets (`ANDROID_SIGNING_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_SIGNING_KEY_PASSWORD`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`).

## Firebase collections (Firestore schema summary)

| Collection | Purpose |
|-----------|---------|
| `users` | User profiles and cumulative stats |
| `games` | Game documents; `events` sub-collection holds timeline |
| `invitations` | In-flight game invites |
| `tournaments` | Tournament brackets; `matches` sub-collection |

## Security Rules

- NEVER hardcode API keys, secrets, or credentials in source files
- Always validate user input at system boundaries
- Always sanitize file paths to prevent directory traversal
- Run `npx @claude-flow/cli@latest security scan` after security-related changes

## claude-flow Quick Reference

```bash
# MCP server (already registered)
claude mcp add claude-flow -- npx -y @claude-flow/cli@latest mcp start

# Diagnostics
npx @claude-flow/cli@latest doctor --fix

# Memory
npx @claude-flow/cli@latest memory search --query "authentication patterns"
npx @claude-flow/cli@latest memory store --key "key" --value "val" --namespace patterns
```

- Documentation: https://github.com/ruvnet/claude-flow
