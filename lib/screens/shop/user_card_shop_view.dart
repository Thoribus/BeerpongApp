import 'package:beerpongapp/screens/shop/shop_item_card.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/util/shop_catalog.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// User Card tab — shows purchasable titles.
///
/// Card backgrounds are level-gated and managed in the profile screen.
/// Shop-exclusive backgrounds will appear here once added to [ShopCatalog].
class UserCardShopView extends StatelessWidget {
  const UserCardShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final titles = ShopCatalog.byCategory(ShopItemCategory.title);
    final backgrounds = ShopCatalog.byCategory(ShopItemCategory.background);

    if (user == null) {
      return _buildSignInPrompt(context);
    }

    return ListView(
      children: [
        ShopItemGrid(sectionTitle: context.loc.shopSectionTitles, items: titles),
        if (backgrounds.isNotEmpty)
          ShopItemGrid(sectionTitle: context.loc.shopSectionCardBackgrounds, items: backgrounds),
        _LevelBackgroundsNote(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
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

class _LevelBackgroundsNote extends StatelessWidget {
  const _LevelBackgroundsNote(this.context);
  // ignore: unused_field
  final BuildContext context;

  @override
  Widget build(BuildContext outerContext) {
    final c = AppColors.of(outerContext);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.subtle.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: c.subtle, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                outerContext.loc.shopCardBackgroundsNote,
                style: TextStyle(color: c.subtle, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
