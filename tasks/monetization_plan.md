# Monetization Plan — BeerpongApp

> Goal: Users should think "I'm happy to support the creators" — not feel milked.

---

## Research Summary: What Users Hate vs. What They Respect

### Never Do (Predatory — causes uninstalls)
- **Forced interstitial ads** at frustrating moments (mid-game, right after losing)
- **Pay-to-win** — anything that makes a paying player better at the game itself
- **FOMO dark patterns** — countdown timers, "limited time!" pressure on basics
- **Subscription traps** — hard-to-cancel, auto-renewing without reminders, paywalling features people already used for free
- **Paywalling social features** — friends, stats, sharing. These are the app's core.
- **Bait-and-switch** — giving something free then pulling it behind a paywall later

### Do (Ethical — builds loyalty)
- **Rewarded ads** users choose to watch (4:1 preferred over forced ads; 85% enjoy them)
- **Cosmetics-only purchases** — pay for appearance, never for gameplay advantage
- **Transparent flat pricing** — clear what you get, no confusing "coin tier" math
- **One-time purchases** over subscriptions for a party game context
- **"Thank you" framing** — optional support, not required participation

---

## What Already Exists (Don't Throw Away)

The shop skeleton and user model already lay the right foundation:

| What exists | Notes |
|---|---|
| Star ⭐ currency icon in shop | Good — keep this as the coin metaphor |
| `unlockedTitles` / `title` on `User` | Titles are already a cosmetic unlock category |
| Level system + `avatarLevelRequirements` + `backgroundLevelRequirements` | Earn by playing, spend coins to unlock early |
| Avatar tab (profile pictures, borders, emblems) | The right cosmetics, just need real assets and buy logic |
| User Card tab ("coming soon") | Card backgrounds already exist in Phase 7 — wire this up |
| In-Game tab (currently random physical products 🎾🎒) | Remove physical goods; replace with in-game cosmetics |

**The physical product store (Beach Volleyball, Hiking Backpack, etc.) should be scrapped.** It makes no sense for a digital app and would require e-commerce infrastructure. The shop tabs should be purely digital cosmetics.

---

## Proposed Monetization Model

### The Core Loop: Earn Coins → Spend on Cosmetics

```
Play games → earn Stars
Watch rewarded ad → earn Stars
Buy Star pack (IAP) → earn Stars
                  ↓
           Spend Stars on:
  avatars / backgrounds / titles / borders / emblems / in-game themes
```

This is the Duolingo/Clash Royale model — free players earn everything slowly through play, impatient players can shortcut with real money, but no one is locked out.

---

## Revenue Stream 1: Rewarded Ads (Primary — low friction)

**How it works:** A prominent "Watch a video → earn 50 ⭐" button available at natural moments.

**Trigger points (user-initiated only, never forced):**
- On the shop screen: "Need more Stars? Watch a short video."
- After completing a game: optional banner "Earn 30 ⭐ for your next purchase."
- On a locked item preview: "Unlock faster — watch a video."

**What to avoid:**
- Never play an ad automatically
- Never interrupt a game
- Never show more than one rewarded ad prompt per session without user interaction

**Revenue estimate:** Rewarded video ads earn ~$16–20 eCPM on iOS (Tier 1 markets). At 30% of active users watching one ad per session, this scales well without damaging retention.

**Implementation:** Google AdMob rewarded ads, or Unity Ads as backup. Flutter plugin: `google_mobile_ads`.

---

## Revenue Stream 2: Star Packs — In-App Purchases (Secondary)

One-time IAP coin packs. No subscription. No auto-renewal.

| Pack | Stars | Price | Notes |
|---|---|---|---|
| Starter | 200 ⭐ | €1.99 | Impulse tier — roughly one cosmetic item |
| Popular | 600 ⭐ | €4.99 | Best-value label; 3x stars for 2.5x price |
| Mega | 1500 ⭐ | €9.99 | For committed fans; one-time big purchase |

**Pricing philosophy:**
- Individual cosmetics should cost 100–500 ⭐ so the €1.99 pack buys something real
- Free play earns ~20–40 ⭐ per game played, so progression without spending is visible but meaningful
- No "nearly enough" manipulation — packs should map cleanly to full item costs

**Implementation:** `in_app_purchase` Flutter package (wraps App Store / Play Store billing).

---

## Revenue Stream 3: Optional Supporter Badge (One-Time Purchase)

A single €2.99 or €3.99 "Support the Devs" one-time IAP that grants:
- A permanent **"Supporter"** title shown on the user card
- A small supporter badge/icon on the profile
- A cosmetic boost: e.g., 300 free Stars on purchase

**Why this works:**
- Fans of small indie apps often want to pay "just to say thanks"
- No gameplay benefit, purely recognition
- Seen in apps like Reeder, Overcast — users celebrate it
- No subscription anxiety. Pay once, done.

**This is the "I want to support the creators" option explicitly offered.**

---

## Revenue Stream 4: Cosmetic Bundles (Seasonal / Themed)

Themed packs sold together at a slight discount. Examples:
- **Summer Pack**: tropical avatar + beach gradient background + "Beach Champion" title — 350 ⭐ (vs. 450 ⭐ separately)
- **Halloween Pack**: spooky avatar + dark background + "Ghost Shooter" title — 400 ⭐

These don't expire (no FOMO) — they're just available and can be bought when ready.

---

## Shop Screen Redesign

Replace the current 3 tabs (Avatar / User Card / In Game) with a cleaner structure:

### Tab 1: Avatars
- Profile Pictures (animal avatars, already in system)
- Avatar Borders (frames around the avatar)
- Emblems / Medals (displayed below the avatar on UserCard)

### Tab 2: User Card
- Card Backgrounds (Phase 7 already implemented; wire the shop)
- Titles (already modeled on `User`)
- Card Accent Colors (future)

### Tab 3: In-Game
- Cup skin themes (e.g., golden cups, neon cups)
- Table overlay theme (e.g., green felt, dark wood)
- Ball skin (visual only, no physics change)

> Note: In-game cosmetics are display-only and affect only the local client. No network sync needed.

### Persistent Bottom Bar on Shop
Show current Star balance + "Get Stars" button (opens rewarded ad or IAP picker).

---

## What Stays Free — Always

These must never be gated:
- Core game functionality (setting up and playing beer pong)
- All statistics and history
- Friends system and social feed
- Achievements tracking
- Tournament creation and participation
- Base avatar (at least 3 free avatars), base background (bg_default)
- Level progression

---

## Items Already Unlockable via Level (Keep as Is)

The level-gated avatar/background system is excellent and should stay. Leveling up is free — just play. The shop is for players who want to unlock something before hitting the required level, or want exclusive cosmetics not on the level track.

This creates a natural segmentation:
- **Casual players**: unlock everything for free by playing
- **Impatient players**: spend a small amount to skip the grind
- **Superfans**: buy the Supporter badge and bundled packs

---

## Implementation Priority

1. **Wire the Star economy** — add `stars: int` to `User`, persist to Firestore, display in shop header
2. **Implement rewarded ads** — AdMob integration, "Watch ad → earn Stars" in shop
3. **Implement IAP star packs** — `in_app_purchase` package, 3 tiers
4. **Wire avatar shop** — connect existing `avatarKeys` to purchasable items with star prices
5. **Wire background shop** — same for `backgroundKeys`
6. **Add Supporter IAP** — one-time purchase, grants Supporter title
7. **Redesign In-Game tab** — replace physical products with cup/table themes
8. **Seasonal bundles** — later, once the economy is tuned

---

## Anti-Dark-Pattern Checklist

Before shipping, confirm:
- [ ] No ad plays without user tapping "Watch"
- [ ] No star pack shows a "best value" label using misleading math
- [ ] Cancellation / refund path exists (App Store / Play Store handle this, but don't hide it)
- [ ] All prices displayed in local currency, no obfuscation
- [ ] Free players can unlock all functional content through play
- [ ] No countdown timers on non-expiring items
- [ ] No "you almost have enough!" messaging designed to frustrate
- [ ] Supporter IAP has no recurring billing

---

## Monetization Stack

| Tool | Purpose |
|---|---|
| `google_mobile_ads` (Flutter) | Rewarded ad delivery (AdMob) |
| `in_app_purchase` (Flutter) | Star packs + Supporter IAP |
| Firestore `users.stars` field | Star balance, server-authoritative |
| Firebase Cloud Functions | Validate IAP receipts server-side before granting Stars |

> **Important:** Never grant Stars purely client-side. Always verify purchase receipts via Cloud Functions before updating the Firestore balance. Otherwise the currency is trivially exploitable.
