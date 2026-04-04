import 'package:beerpongapp/repositories/user_repository.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
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

    final cupItems = items.where((i) => i.id.contains('cups')).toList();
    final tableItems = items.where((i) => i.id.contains('table')).toList();

    return ListView(
      children: [
        _buildSection(context, context.loc.shopSectionCupSkins, cupItems, user.activeCupSkin,
            'activeCupSkin'),
        _buildSection(context, context.loc.shopSectionTableThemes, tableItems, user.activeTableTheme,
            'activeTableTheme'),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title,
      List<ShopItem> items, String? equippedId, String field) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: TextStyle(
              color: c.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _InGameItemCard(
            item: items[i],
            equippedId: equippedId,
            field: field,
          ),
        ),
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

// ── In-game item card ─────────────────────────────────────────────────────────

class _InGameItemCard extends StatelessWidget {
  const _InGameItemCard({
    required this.item,
    required this.equippedId,
    required this.field,
  });

  final ShopItem item;
  final String? equippedId;
  final String field;

  static const Map<String, Color> _skinColors = {
    'ingame_gold_cups': Colors.amber,
    'ingame_neon_cups': Colors.cyanAccent,
  };

  static const Map<String, List<Color>> _tableColors = {
    'ingame_dark_table': [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
    'ingame_beach_table': [Color(0xFFD4A855), Color(0xFF8B6E33)],
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final owned = ShopCatalog.ownsItem(user, item.id);
    final equipped = equippedId == item.id;
    final affordable = ShopCatalog.canAfford(user, item.id);

    return GestureDetector(
      onTap: owned ? null : () => _onBuyTap(context, affordable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: equipped
              ? Colors.amber.shade900.withValues(alpha: 0.3)
              : owned
                  ? Colors.green.shade900.withValues(alpha: 0.3)
                  : c.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped
                ? Colors.amber.shade600
                : owned
                    ? Colors.green.shade600
                    : c.subtle.withValues(alpha: 0.2),
            width: (equipped || owned) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _preview()),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: TextStyle(
                      color: equipped
                          ? Colors.amber.shade300
                          : owned
                              ? Colors.green.shade300
                              : c.onBackground,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (!owned)
                    _PriceChip(price: item.starPrice, affordable: affordable)
                  else
                    _EquipButton(
                      equipped: equipped,
                      field: field,
                      itemId: item.id,
                    ),
                ],
              ),
            ),
            if (equipped)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on_rounded,
                      color: Colors.white, size: 12),
                ),
              )
            else if (owned)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final skinColor = _skinColors[item.id];
    final tableColors = _tableColors[item.id];

    if (skinColor != null) {
      // Cup skin preview — three stacked circles
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skinColor,
                border: Border.all(color: Colors.white60, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: skinColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (tableColors != null) {
      // Table theme preview — gradient rectangle
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tableColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    return const Icon(Icons.sports_esports_rounded,
        size: 36, color: Colors.teal);
  }

  void _onBuyTap(BuildContext context, bool affordable) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _BuyDialog(item: item, affordable: affordable),
    );
  }
}

// ── Equip/Unequip button ──────────────────────────────────────────────────────

class _EquipButton extends StatefulWidget {
  const _EquipButton({
    required this.equipped,
    required this.field,
    required this.itemId,
  });

  final bool equipped;
  final String field;
  final String itemId;

  @override
  State<_EquipButton> createState() => _EquipButtonState();
}

class _EquipButtonState extends State<_EquipButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      await context.read<UserProvider>().equipItem(
            field: widget.field,
            itemId: widget.equipped ? null : widget.itemId,
          );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 26,
        width: 26,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
      );
    }
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.equipped
              ? Colors.red.shade900.withValues(alpha: 0.3)
              : Colors.amber.shade700,
          borderRadius: BorderRadius.circular(20),
          border: widget.equipped
              ? Border.all(color: Colors.red.shade400.withValues(alpha: 0.6))
              : null,
        ),
        child: Text(
          widget.equipped ? context.loc.shopUnequip : context.loc.shopEquip,
          style: TextStyle(
            color: widget.equipped ? Colors.red.shade300 : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Price chip (reused locally) ───────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.price, required this.affordable});
  final int price;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final color = affordable ? Colors.amber.shade700 : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            '$price',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Purchase dialog ───────────────────────────────────────────────────────────

class _BuyDialog extends StatefulWidget {
  const _BuyDialog({required this.item, required this.affordable});
  final ShopItem item;
  final bool affordable;

  @override
  State<_BuyDialog> createState() => _BuyDialogState();
}

class _BuyDialogState extends State<_BuyDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = context.watch<UserProvider>().user;
    final balance = user?.stars ?? 0;
    final needed = widget.item.starPrice - balance;

    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.item.name,
              style: TextStyle(
                color: c.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (widget.affordable) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.loc.shopYourBalance,
                      style: TextStyle(color: c.subtle, fontSize: 13)),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('$balance',
                        style: TextStyle(
                            color: c.onBackground,
                            fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.loc.shopCost,
                      style: TextStyle(color: c.subtle, fontSize: 13)),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('${widget.item.starPrice}',
                        style: TextStyle(
                            color: c.onBackground,
                            fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _buy,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.loc.shopBuyForStars(widget.item.starPrice),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.red.shade700.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.loc.shopNeedMoreStars(needed),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: Text(context.loc.btnCancel, style: TextStyle(color: c.subtle)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy() async {
    final provider = context.read<UserProvider>();
    final user = provider.user;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await FirestoreService.instance.spendStars(
        userId: user.id,
        amount: widget.item.starPrice,
        itemId: widget.item.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await provider.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.shopItemPurchased(widget.item.name)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on InsufficientStarsException {
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
}
