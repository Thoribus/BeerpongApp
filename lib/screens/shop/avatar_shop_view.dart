import 'package:beerpongapp/screens/shop/shop_item_card.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/util/shop_catalog.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Avatar tab in the shop — shows purchasable borders and emblems.
///
/// Avatars themselves are level-gated (free through play) and are managed
/// in the profile screen. Shop-exclusive avatar assets will appear here
/// once added to [ShopCatalog].
class AvatarShopScreen extends StatelessWidget {
  const AvatarShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final borders = ShopCatalog.byCategory(ShopItemCategory.border);
    final emblems = ShopCatalog.byCategory(ShopItemCategory.emblem);
    final avatars = ShopCatalog.byCategory(ShopItemCategory.avatar);

    if (user == null) {
      return const _SignInPrompt();
    }

    return ListView(
      children: [
        if (avatars.isNotEmpty)
          ShopItemGrid(sectionTitle: context.loc.shopSectionProfilePictures, items: avatars),
        ShopItemGrid(sectionTitle: context.loc.shopSectionAvatarBorders, items: borders),
        ShopItemGrid(sectionTitle: context.loc.shopSectionEmblemsAndMedals, items: emblems),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: c.subtle, size: 48),
          const SizedBox(height: 12),
          Text(context.loc.shopSignInBrowse,
              style: TextStyle(color: c.subtle, fontSize: 15)),
        ],
      ),
    );
  }
}
