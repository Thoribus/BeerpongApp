# BeerPong

A mobile Beer Pong companion app for iOS and Android. Track live games, manage teams, view stats, compete with friends, and unlock cosmetics.

## Features

- **Live game tracking** — real-time cup layout, scoreboard, and timeline for active games
- **Spectate mode** — watch a friend's game in read-only view via invite
- **Statistics** — per-player and per-game history with charts
- **Friends** — add friends, compare stats, send game invitations via push notification
- **Achievements** — unlock titles and badges through gameplay milestones
- **Shop** — earn stars by playing or watching rewarded ads; spend on avatars, backgrounds, and titles
- **Supporter Pack** — one-time purchase for a permanent supporter badge
- **Auth** — Email/password, Google Sign-In, and Sign in with Apple

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter (Dart) |
| Backend | Firebase (Firestore, Auth, Functions, Messaging) |
| Ads | Google Mobile Ads (AdMob) |
| Payments | In-App Purchase (App Store + Play Store) |
| Error tracking | Sentry |
| Navigation | go_router |
| State | Provider |

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Firebase project with Firestore, Auth, and Cloud Messaging enabled
- `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) placed in their respective directories

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

## CI/CD

Pushing to `main` triggers the GitHub Actions workflow which:

1. Runs all tests
2. Builds a signed Android App Bundle
3. Deploys to the Google Play internal track

**Required GitHub secrets:**

| Secret | Description |
| --- | --- |
| `ANDROID_SIGNING_KEY` | Base64-encoded release keystore |
| `ANDROID_SIGNING_KEY_ALIAS` | Key alias inside the keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_SIGNING_KEY_PASSWORD` | Key password |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Play service account JSON |

## Project Structure

```text
lib/
├── models/          # Data models (User, Team, Player, Invitation, …)
├── screens/         # UI screens grouped by feature
├── services/        # NotificationService, PurchaseService
├── util/            # FirestoreService, UserProvider, router, logger
├── widgets/         # Shared widgets (AppTabBar, …)
├── constants/       # Route constants
├── theme.dart       # AppColors + theming
└── main.dart

functions/           # Firebase Cloud Functions (receipt validation, FCM triggers)
assets/              # Images, SVGs, custom font
```
