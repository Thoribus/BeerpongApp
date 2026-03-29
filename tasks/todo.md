# BeerpongApp — Task Tracker

## Phases 1–7: Completed ✓

All foundation work is done and committed (`16c4027` on `feature/improvements`).
287 tests passing. See `tasks/monetization_plan.md` for the strategy behind Phases 8–13.

---

## Phase 8 — Star Economy Foundation

Goal: Add stars as a first-class field on User, award them post-game, display them in the shop header. No purchasing yet — just the earning loop.

### 8.1 — User model

- [ ] Add `stars: int` to `User` constructor (default `0`)
- [ ] Add `purchasedItems: List<String>` to `User` constructor (default `const []`)
  - This is the source of truth for what a user has bought in the shop (distinct from level-gated unlocks)
- [ ] Add both fields to `toJson()` — key names: `'stars'`, `'purchasedItems'`
- [ ] Add both fields to `fromJson()` — with `?? 0` and `?? []` fallbacks
- [ ] Add both fields to `copyWith()`

### 8.2 — Star awards on game completion

- [ ] Add `calculateStarsGained()` to `LevelSystem` — mirrors `calculateXpGained()` signature, awards:
  - 10 ⭐ participation baseline
  - +20 ⭐ win
  - +2 ⭐ per cup hit
  - +5 ⭐ per on-fire trigger
  - +8 ⭐ per bounce make
  - +10 ⭐ per island make
  - +15 ⭐ per death cup hit
  - +30 ⭐ hitting the last cup (clutch bonus)
  - Typical game: 25–80 ⭐ (so a 100-star item takes ~2–5 games)
- [ ] Call `calculateStarsGained()` in `UserRepository.saveGame()` alongside the existing XP logic — add earned stars to `user.stars`
- [ ] Include updated `stars` in the batch `updateUser()` call that already happens in `saveGame()`

### 8.3 — Atomic star spend method

- [ ] Add `UserRepository.spendStars({ required String userId, required int amount, required String itemId })` using a **Firestore transaction**:
  1. Read current doc
  2. Check `stars >= amount` — throw if insufficient
  3. Atomically: decrement `stars`, append `itemId` to `purchasedItems`
  - This prevents double-spends and is client-safe (no Cloud Function needed for spending, only for IAP grants)
- [ ] Expose via `FirestoreService.spendStars()`

### 8.4 — Shop header

- [ ] Add a persistent `_ShopHeader` widget at the top of `ShopScreen` (above the tab bar)
  - Shows: ⭐ `{balance}` — reads from `UserProvider`
  - Shows: "Get Stars" button (tappable — opens bottom sheet, wired in Phase 11)
  - Collapses / shows "Sign in to earn Stars" when user is null

### 8.5 — Tests

- [ ] Unit test `calculateStarsGained()` in `test/util/level_system_stars_test.dart`
- [ ] Unit test `User` model: `stars` and `purchasedItems` in toJson/fromJson/copyWith
- [ ] Widget test: star balance appears in shop header when user is signed in

---

## Phase 9 — Shop Catalog

Goal: Replace the hardcoded dummy shop data with a real static catalog — same pattern as `AchievementEngine`.

### 9.1 — ShopItem model + ShopCatalog

- [ ] Create `lib/util/shop_catalog.dart`
- [ ] Define `ShopItem` class:

  ```dart
  class ShopItem {
    final String id;           // e.g. 'avatar_catbeer', 'bg_blue', 'title_king'
    final String name;         // Display name
    final ShopItemCategory category;
    final int starPrice;       // 0 = free / level-gated (not in shop)
    final String? assetPath;   // svg path for previews
  }
  enum ShopItemCategory { avatar, background, title, border, emblem, inGame }
  ```

- [ ] Populate initial catalog (all shop-exclusive items, not the level-gated ones):
  - Avatars: price 150–400 ⭐ each
  - Backgrounds: price 100–300 ⭐ each
  - Titles: price 200–500 ⭐ each (e.g. "Pong God", "The Untouchable", "Foam Legend")
  - Borders: price 200–350 ⭐ each (placeholder — awaiting real assets)
  - Emblems: price 150–300 ⭐ each (placeholder — awaiting real assets)
  - In-game: cup skins, table themes — price 100–300 ⭐ each (placeholder)
- [ ] Add `ShopCatalog.allItems` static getter
- [ ] Add `ShopCatalog.byCategory(ShopItemCategory)` helper

### 9.2 — Item ownership helpers on User

- [ ] Add `bool ownsItem(String itemId)` getter to `User`: returns `purchasedItems.contains(itemId)` OR the item is level-gated and `level >= requirement`
- [ ] Add `bool canAfford(String itemId)` getter: `stars >= ShopCatalog.priceOf(itemId)`

### 9.3 — Tests

- [ ] Unit test: catalog has no duplicate IDs
- [ ] Unit test: `ownsItem()` returns true for level-gated items user has unlocked
- [ ] Unit test: `ownsItem()` returns false for shop items not yet purchased

---

## Phase 10 — Shop Screen Redesign

Goal: Wire the existing shell to real data. Remove physical products. Add purchase flow.

### 10.1 — Clean up existing screens

- [ ] Delete `Product` class and `_buildProductList()` from `shop_screen.dart`
- [ ] Rewrite `AvatarShopScreen` (`avatar_shop_view.dart`) to read from `ShopCatalog.byCategory(avatar)`
  - Show owned items with a checkmark (matches current avatar selection pattern)
  - Show locked items with a lock + star price
  - Show purchasable items with ⭐ price button
  - Tapping a purchasable item → `_confirmPurchase()` dialog
- [ ] Wire User Card tab: build `BackgroundShopView` (same structure, `ShopItemCategory.background`)
- [ ] Wire In-Game tab: build `InGameShopView` with cup skins + table themes from catalog (placeholder SVGs ok for now)

### 10.2 — Purchase confirmation dialog

- [ ] `_confirmPurchase(ShopItem item)` — uses `AwesomeDialog` (already in deps):
  - Shows item preview, star cost, current balance
  - "Buy for ⭐ X" → calls `FirestoreService.spendStars()` → on success: call `UserProvider.updateUser()` with updated user (re-fetched from Firestore)
  - Shows "Not enough stars — Get More" if balance insufficient → opens Get Stars bottom sheet

### 10.3 — Get Stars bottom sheet (placeholder for Phase 11/12)

- [ ] Create `_GetStarsSheet` bottom sheet stub:
  - Shows "Watch a video → +50 ⭐" row (disabled with "Coming soon" until Phase 11)
  - Shows 3 IAP pack tiers (disabled with "Coming soon" until Phase 12)
  - Good enough to ship the rest of Phase 10 without blocking

### 10.4 — Tests

- [ ] Widget test: shop tab renders catalog items (not the old Beach Volleyball etc.)
- [ ] Widget test: owned item shows checkmark
- [ ] Widget test: locked item shows lock + price

---

## Phase 11 — Rewarded Ads

Goal: Users can watch an optional video to earn stars. User-initiated only.

### 11.1 — Setup

- [ ] Add `google_mobile_ads: ^5.x.x` to `pubspec.yaml`
- [ ] Add AdMob App ID to `AndroidManifest.xml` (`<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">`)
- [ ] Add AdMob App ID to `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
- [ ] Use test ad unit IDs during development (AdMob provides official test IDs)

### 11.2 — AdService

- [ ] Create `lib/services/ad_service.dart` — singleton with lifecycle management:

  ```dart
  class AdService {
    static final instance = AdService._();
    RewardedAd? _rewardedAd;

    Future<void> preload();          // loads ad in background
    Future<bool> showRewardedAd({   // returns true if reward was earned
      required VoidCallback onRewarded,
    });
    void dispose();
  }
  ```

- [ ] Call `AdService.instance.preload()` on app startup (in `main.dart` after Firebase init)
- [ ] After showing: immediately preload next ad

### 11.3 — Wire into Get Stars sheet

- [ ] Enable "Watch a video → +50 ⭐" row in `_GetStarsSheet`
- [ ] On tap: show ad → on reward callback: call `UserRepository.creditStars()` (dedicated add method, mirrors `spendStars`)
- [ ] Show success snackbar "You earned 50 ⭐!" after reward
- [ ] Disable button while ad is loading; show spinner

### 11.4 — Rate limiting (prevent abuse)

- [ ] Track `lastAdWatchedAt` on User (DateTime, stored in SharedPreferences locally — not Firestore)
- [ ] Limit to 5 rewarded ads per 24 hours (soft limit — purely local, not server-enforced)
- [ ] Show remaining daily ad views in the sheet: "3 of 5 watches remaining today"

### 11.5 — Tests

- [ ] Unit test: daily ad limit logic (count resets after 24h)
- [ ] Widget test: "Watch video" button is visible in Get Stars sheet (mock AdService)

---

## Phase 12 — In-App Purchases

Goal: Star packs + one-time Supporter Pack. Receipt validation via Cloud Functions.

### 12.1 — Setup

- [ ] Add `in_app_purchase: ^3.x.x` to `pubspec.yaml`
- [ ] Register product IDs in **App Store Connect** (Consumable IAP):
  - `com.tecbreak.beerpongapp.stars_200` → €1.99
  - `com.tecbreak.beerpongapp.stars_600` → €4.99
  - `com.tecbreak.beerpongapp.stars_1500` → €9.99
  - `com.tecbreak.beerpongapp.supporter_pack` → €2.99 (Non-Consumable)
- [ ] Register same product IDs in **Google Play Console** (In-app products)

### 12.2 — PurchaseService

- [ ] Create `lib/services/purchase_service.dart` — ChangeNotifier:

  ```dart
  class PurchaseService extends ChangeNotifier {
    List<ProductDetails> get availableProducts;
    bool get isAvailable;           // store available?

    Future<void> initialize();      // load products
    Future<void> buyConsumable(ProductDetails product);
    Future<void> buyNonConsumable(ProductDetails product);
    Future<void> restorePurchases();
    Stream<PurchaseDetails> get purchaseStream;
  }
  ```

- [ ] Listen to `InAppPurchase.instance.purchaseStream` in `main.dart`
- [ ] Handle `PurchaseStatus.purchased` → forward to Cloud Function for validation

### 12.3 — Cloud Function: receipt validation

- [ ] Create `functions/src/validatePurchase.ts` (Node.js):
  - Accepts: `{ userId, productId, receiptData, platform }`
  - Validates with App Store receipt API / Google Play Developer API
  - On valid: increments `users/{userId}.stars` via `FieldValue.increment()`
  - On valid Supporter Pack: sets `users/{userId}.isSupporter = true`, adds `'Supporter'` to `unlockedTitles`
  - Returns: `{ success: bool, newBalance: int }`
  - Idempotent: stores processed transaction IDs in `processedPurchases` collection to prevent replay
- [ ] Deploy to Firebase Functions

### 12.4 — Wire into Get Stars sheet

- [ ] Enable the 3 pack tiers in `_GetStarsSheet` with real prices from `PurchaseService.availableProducts`
- [ ] Show platform-appropriate localized price strings via `ProductDetails.price`
- [ ] On purchase stream `purchased` event: call Cloud Function, show success snackbar with new balance
- [ ] Add "Restore Purchases" text button at bottom (required by App Store guidelines)

### 12.5 — Tests

- [ ] Unit test: Cloud Function correctly rejects replayed transaction IDs
- [ ] Widget test: pack tiers display correctly when products are loaded (mock PurchaseService)
- [ ] Widget test: "Restore Purchases" button is visible

---

## Phase 13 — Supporter Pack & Badge

Goal: Surface the Supporter identity in the UI so buyers feel recognized.

### 13.1 — User model

- [ ] Add `isSupporter: bool` to `User` (default `false`)
- [ ] Add to `toJson()`, `fromJson()`, `copyWith()`
- [ ] `isSupporter` is set server-side by the Cloud Function — never trust client-side claims

### 13.2 — Supporter badge in UI

- [ ] Small ⭐ orange badge on `UserCard` when `user.isSupporter` is true (next to username or corner)
- [ ] Supporter badge on `AccountScreen` profile header
- [ ] "Supporter" appears as a selectable title in `CustomUserScreen` when `user.isSupporter`

### 13.3 — Supporter Pack entry in Get Stars sheet

- [ ] Show as a distinct row above the star packs: "Support the Devs — ⭐ Supporter Badge + 300 Stars · €2.99"
- [ ] After purchase: show a thank-you dialog ("Thank you for supporting BeerpongApp! 🎉")
- [ ] If already purchased: show "You're a Supporter ✓" (non-purchasable state, use `restorePurchases`)

### 13.4 — Tests

- [ ] Widget test: Supporter badge visible on `UserCard` when `isSupporter: true`
- [ ] Widget test: Supporter badge absent when `isSupporter: false`
- [ ] Unit test: `isSupporter` round-trips through toJson/fromJson

---

## Deferred (Post-Launch)

- [ ] Seasonal cosmetic bundles (Halloween, Summer, etc.) — sell for stars, no expiry
- [ ] In-game cosmetics (cup skins, table themes) — requires `GameScreen` to read user's cosmetic preferences
- [ ] Star leaderboard / "most generous supporter" social feature
- [ ] Push notification for "Your daily ad watch is available again"

---

## Anti-Dark-Pattern Sign-Off Checklist

Before any monetization feature ships to production:

- [ ] No ad plays without user tapping "Watch"
- [ ] Rewarded ad daily limit is visible to the user (not a hidden throttle)
- [ ] All IAP prices displayed in local currency (handled by `ProductDetails.price` — verify)
- [ ] Supporter Pack has no recurring billing (Non-Consumable type, confirmed in store consoles)
- [ ] "Restore Purchases" button exists and works (App Store requirement)
- [ ] Free players can still earn all level-gated cosmetics through play
- [ ] No countdown timers on non-expiring items
- [ ] Stars balance is always visible before a purchase confirmation
- [ ] Insufficient stars shows "earn more" path, not a paywall dead-end
