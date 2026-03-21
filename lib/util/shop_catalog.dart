import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/level_system.dart';

// ── Category ────────────────────────────────────────────────────────────────

enum ShopItemCategory {
  avatar,
  background,
  title,
  border,
  emblem,
  inGame;

  String get displayName => switch (this) {
        avatar     => 'Avatars',
        background => 'Backgrounds',
        title      => 'Titles',
        border     => 'Borders',
        emblem     => 'Emblems',
        inGame     => 'In-Game',
      };
}

// ── Item model ───────────────────────────────────────────────────────────────

class ShopItem {
  /// Unique stable identifier used as the key in [User.purchasedItems].
  final String id;

  /// Human-readable name shown in the shop UI.
  final String name;

  final ShopItemCategory category;

  /// Cost in stars. All items in the catalog are purchasable with stars.
  final int starPrice;

  /// Path to the preview SVG/PNG asset, or null for items without a visual
  /// preview (e.g. titles shown as styled text).
  final String? assetPath;

  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.starPrice,
    this.assetPath,
  });
}

// ── Catalog ──────────────────────────────────────────────────────────────────

/// Static catalogue of all shop-exclusive purchasable items.
///
/// Level-gated avatars and backgrounds are NOT listed here — they are earned
/// for free by reaching the required level and are tracked via [AppConstants].
/// This catalog covers items that can only be obtained by spending stars.
abstract final class ShopCatalog {
  static const List<ShopItem> allItems = [
    // ── Titles ────────────────────────────────────────────────────────────
    ShopItem(
      id: 'title_pong_god',
      name: 'Pong God',
      category: ShopItemCategory.title,
      starPrice: 500,
    ),
    ShopItem(
      id: 'title_untouchable',
      name: 'The Untouchable',
      category: ShopItemCategory.title,
      starPrice: 400,
    ),
    ShopItem(
      id: 'title_foam_legend',
      name: 'Foam Legend',
      category: ShopItemCategory.title,
      starPrice: 350,
    ),
    ShopItem(
      id: 'title_beer_baron',
      name: 'Beer Baron',
      category: ShopItemCategory.title,
      starPrice: 300,
    ),
    ShopItem(
      id: 'title_cup_commander',
      name: 'Cup Commander',
      category: ShopItemCategory.title,
      starPrice: 250,
    ),
    ShopItem(
      id: 'title_night_shifter',
      name: 'Night Shifter',
      category: ShopItemCategory.title,
      starPrice: 200,
    ),

    // ── Borders ───────────────────────────────────────────────────────────
    ShopItem(
      id: 'border_gold',
      name: 'Gold Frame',
      category: ShopItemCategory.border,
      starPrice: 350,
      assetPath: 'assets/borders/avatar_border.svg',
    ),
    ShopItem(
      id: 'border_neon',
      name: 'Neon Glow',
      category: ShopItemCategory.border,
      starPrice: 250,
      assetPath: 'assets/borders/avatar_border.svg',
    ),
    ShopItem(
      id: 'border_fire',
      name: 'Fire Ring',
      category: ShopItemCategory.border,
      starPrice: 300,
      assetPath: 'assets/borders/avatar_border.svg',
    ),

    // ── Emblems ───────────────────────────────────────────────────────────
    ShopItem(
      id: 'emblem_podium',
      name: 'Podium',
      category: ShopItemCategory.emblem,
      starPrice: 180,
      assetPath: 'assets/emblems/podium.svg',
    ),
    ShopItem(
      id: 'emblem_trophy',
      name: 'Trophy',
      category: ShopItemCategory.emblem,
      starPrice: 220,
      assetPath: 'assets/emblems/podium.svg',
    ),
    ShopItem(
      id: 'emblem_skull',
      name: 'Death Cup',
      category: ShopItemCategory.emblem,
      starPrice: 260,
      assetPath: 'assets/emblems/podium.svg',
    ),

    // ── In-game cosmetics ─────────────────────────────────────────────────
    ShopItem(
      id: 'ingame_gold_cups',
      name: 'Gold Cups',
      category: ShopItemCategory.inGame,
      starPrice: 200,
    ),
    ShopItem(
      id: 'ingame_neon_cups',
      name: 'Neon Cups',
      category: ShopItemCategory.inGame,
      starPrice: 200,
    ),
    ShopItem(
      id: 'ingame_dark_table',
      name: 'Dark Table',
      category: ShopItemCategory.inGame,
      starPrice: 150,
    ),
    ShopItem(
      id: 'ingame_beach_table',
      name: 'Beach Table',
      category: ShopItemCategory.inGame,
      starPrice: 150,
    ),
  ];

  // ── Queries ───────────────────────────────────────────────────────────────

  /// All items in [category].
  static List<ShopItem> byCategory(ShopItemCategory category) =>
      allItems.where((i) => i.category == category).toList();

  /// Star price of [itemId], or null if the item is not in the catalog.
  static int? priceOf(String itemId) =>
      allItems.where((i) => i.id == itemId).firstOrNull?.starPrice;

  /// Find a single item by ID, or null if not found.
  static ShopItem? findById(String itemId) =>
      allItems.where((i) => i.id == itemId).firstOrNull;

  // ── Ownership ─────────────────────────────────────────────────────────────

  /// Returns true if [user] owns [itemId] — either purchased in the shop or
  /// unlocked by reaching the required level.
  ///
  /// Level-gated avatars and backgrounds are owned once the user's level meets
  /// the requirement in [AppConstants]. Shop-exclusive items (titles, borders,
  /// emblems, in-game) are owned once they appear in [user.purchasedItems].
  static bool ownsItem(User user, String itemId) {
    if (user.purchasedItems.contains(itemId)) return true;

    final level = LevelSystem.levelFromXp(user.xp);

    final avatarReq = AppConstants.avatarLevelRequirements[itemId];
    if (avatarReq != null) return level >= avatarReq;

    final bgReq = AppConstants.backgroundLevelRequirements[itemId];
    if (bgReq != null) return level >= bgReq;

    return false;
  }

  /// Returns true if [user] has enough stars to buy [itemId].
  static bool canAfford(User user, String itemId) {
    final price = priceOf(itemId);
    return price != null && user.stars >= price;
  }
}
