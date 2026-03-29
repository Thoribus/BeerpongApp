import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/util/shop_catalog.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/constants.dart';

User _user({int xp = 0, int stars = 0, List<String> purchasedItems = const []}) =>
    User(id: 'u1', username: 'Tester', xp: xp, stars: stars,
        purchasedItems: purchasedItems);

void main() {
  // ── Catalog integrity ──────────────────────────────────────────────────────

  group('ShopCatalog — catalog integrity', () {
    test('allItems is non-empty', () {
      expect(ShopCatalog.allItems, isNotEmpty);
    });

    test('no duplicate IDs in catalog', () {
      final ids = ShopCatalog.allItems.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate item IDs found in ShopCatalog');
    });

    test('every item has a positive star price', () {
      for (final item in ShopCatalog.allItems) {
        expect(item.starPrice, greaterThan(0),
            reason: '${item.id} has zero or negative star price');
      }
    });

    test('title, border, emblem, and inGame categories each have items', () {
      // avatar and background start empty — those are level-gated, not in the
      // shop catalog until shop-exclusive assets are added in a future phase.
      const populated = [
        ShopItemCategory.title,
        ShopItemCategory.border,
        ShopItemCategory.emblem,
        ShopItemCategory.inGame,
      ];
      for (final cat in populated) {
        expect(ShopCatalog.byCategory(cat), isNotEmpty,
            reason: 'No items found for category ${cat.name}');
      }
    });

    test('byCategory returns only items of that category', () {
      for (final cat in ShopItemCategory.values) {
        final items = ShopCatalog.byCategory(cat);
        expect(items.every((i) => i.category == cat), isTrue);
      }
    });

    test('catalog contains no level-gated avatar or background IDs', () {
      final catalogIds = ShopCatalog.allItems.map((i) => i.id).toSet();
      for (final key in AppConstants.avatarKeys) {
        expect(catalogIds.contains(key), isFalse,
            reason: 'Level-gated avatar "$key" should not be in ShopCatalog');
      }
      for (final key in AppConstants.backgroundKeys) {
        expect(catalogIds.contains(key), isFalse,
            reason: 'Level-gated background "$key" should not be in ShopCatalog');
      }
    });

    test('priceOf returns correct star price', () {
      expect(ShopCatalog.priceOf('title_pong_god'), 500);
      expect(ShopCatalog.priceOf('emblem_podium'), 180);
      expect(ShopCatalog.priceOf('border_gold'), 350);
    });

    test('priceOf returns null for unknown ID', () {
      expect(ShopCatalog.priceOf('nonexistent_item'), isNull);
    });

    test('findById returns correct item', () {
      final item = ShopCatalog.findById('title_beer_baron');
      expect(item, isNotNull);
      expect(item!.name, 'Beer Baron');
      expect(item.category, ShopItemCategory.title);
    });

    test('findById returns null for unknown ID', () {
      expect(ShopCatalog.findById('ghost_item'), isNull);
    });

    test('ShopItemCategory.displayName is non-empty for every value', () {
      for (final cat in ShopItemCategory.values) {
        expect(cat.displayName, isNotEmpty);
      }
    });
  });

  // ── ownsItem ───────────────────────────────────────────────────────────────

  group('ShopCatalog.ownsItem — shop purchases', () {
    test('returns false when purchasedItems is empty', () {
      expect(ShopCatalog.ownsItem(_user(), 'title_pong_god'), isFalse);
    });

    test('returns true when itemId is in purchasedItems', () {
      final u = _user(purchasedItems: ['title_pong_god', 'border_gold']);
      expect(ShopCatalog.ownsItem(u, 'title_pong_god'), isTrue);
      expect(ShopCatalog.ownsItem(u, 'border_gold'), isTrue);
    });

    test('returns false for a different item not yet purchased', () {
      final u = _user(purchasedItems: ['border_gold']);
      expect(ShopCatalog.ownsItem(u, 'title_pong_god'), isFalse);
    });
  });

  group('ShopCatalog.ownsItem — level-gated avatars', () {
    test('avatar_aggroracoon (level 1) owned at xp 0', () {
      // Level 1 requires 0 XP
      expect(ShopCatalog.ownsItem(_user(xp: 0), 'avatar_aggroracoon'), isTrue);
    });

    test('avatar_catpants (level 6) not owned at level 1', () {
      expect(ShopCatalog.ownsItem(_user(xp: 0), 'avatar_catpants'), isFalse);
    });

    test('avatar_catpants (level 6) owned when level >= 6', () {
      // Level 6 cumulative XP = (6-1)*(100 + 25*(6-2)) = 5*200 = 1000
      expect(ShopCatalog.ownsItem(_user(xp: 1000), 'avatar_catpants'), isTrue);
    });

    test('avatar_frogisland (level 26) not owned at level 10', () {
      // Level 10 XP = (9)*(100+25*8) = 9*300 = 2700
      expect(ShopCatalog.ownsItem(_user(xp: 2700), 'avatar_frogisland'), isFalse);
    });
  });

  group('ShopCatalog.ownsItem — level-gated backgrounds', () {
    test('bg_default (level 1) owned at xp 0', () {
      expect(ShopCatalog.ownsItem(_user(xp: 0), 'bg_default'), isTrue);
    });

    test('bg_blue (level 6) not owned at level 1', () {
      expect(ShopCatalog.ownsItem(_user(xp: 0), 'bg_blue'), isFalse);
    });

    test('bg_blue (level 6) owned when level >= 6', () {
      expect(ShopCatalog.ownsItem(_user(xp: 1000), 'bg_blue'), isTrue);
    });
  });

  group('ShopCatalog.ownsItem — unknown item', () {
    test('returns false for an item not in catalog or level gates', () {
      expect(ShopCatalog.ownsItem(_user(), 'totally_unknown_item'), isFalse);
    });
  });

  // ── canAfford ─────────────────────────────────────────────────────────────

  group('ShopCatalog.canAfford', () {
    test('returns false when stars < price', () {
      final u = _user(stars: 100);
      expect(ShopCatalog.canAfford(u, 'title_pong_god'), isFalse); // 500 ⭐
    });

    test('returns true when stars == price', () {
      final u = _user(stars: 500);
      expect(ShopCatalog.canAfford(u, 'title_pong_god'), isTrue);
    });

    test('returns true when stars > price', () {
      final u = _user(stars: 999);
      expect(ShopCatalog.canAfford(u, 'emblem_podium'), isTrue); // 180 ⭐
    });

    test('returns false for unknown item regardless of stars', () {
      final u = _user(stars: 99999);
      expect(ShopCatalog.canAfford(u, 'ghost_item'), isFalse);
    });
  });
}
