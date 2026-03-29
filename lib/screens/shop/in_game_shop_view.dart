import 'package:beerpongapp/screens/shop/shop_item_card.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/shop_catalog.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// In-Game tab — shows purchasable in-game cosmetics (cup skins, table themes).
class InGameShopView extends StatelessWidget {
  const InGameShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final items = ShopCatalog.byCategory(ShopItemCategory.inGame);

    if (user == null) {
      return _buildSignInPrompt(context);
    }

    return ListView(
      children: [
        ShopItemGrid(sectionTitle: 'Cup Skins', items: items.where((i) => i.id.contains('cups')).toList()),
        ShopItemGrid(sectionTitle: 'Table Themes', items: items.where((i) => i.id.contains('table')).toList()),
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
          Text('Sign in to browse the shop',
              style: TextStyle(color: c.subtle, fontSize: 15)),
        ],
      ),
    );
  }
}
