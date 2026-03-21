import 'package:beerpongapp/repositories/user_repository.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/shop_catalog.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// ── Card ─────────────────────────────────────────────────────────────────────

/// A square card representing a single shop item.
///
/// Visual states:
/// - **Owned**: green checkmark overlay, no price chip.
/// - **Affordable**: orange ⭐ price chip, fully tappable → purchase flow.
/// - **Not affordable**: grey ⭐ price chip, tappable → "need more stars" info.
class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.item,
  });

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = context.watch<UserProvider>().user;

    final owned = user != null && ShopCatalog.ownsItem(user, item.id);
    final affordable = user != null && ShopCatalog.canAfford(user, item.id);

    return GestureDetector(
      onTap: owned ? null : () => _onTap(context, affordable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: owned
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : c.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: owned
                ? Colors.green.shade600
                : c.subtle.withValues(alpha: 0.2),
            width: owned ? 1.5 : 1,
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
            // ── Content ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _ItemPreview(item: item, owned: owned)),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: TextStyle(
                      color: owned ? Colors.green.shade300 : c.onBackground,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (!owned) _PriceChip(price: item.starPrice, affordable: affordable),
                ],
              ),
            ),

            // ── Owned overlay ─────────────────────────────────────────────
            if (owned)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, bool affordable) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _PurchaseDialog(item: item, affordable: affordable),
    );
  }
}

// ── Price chip ────────────────────────────────────────────────────────────────

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
          Icon(Icons.star_rounded, color: color, size: 13),
          const SizedBox(width: 3),
          Text(
            '$price',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item preview ──────────────────────────────────────────────────────────────

class _ItemPreview extends StatelessWidget {
  const _ItemPreview({required this.item, required this.owned});
  final ShopItem item;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    if (item.assetPath != null) {
      final opacity = owned ? 0.6 : 1.0;
      return Opacity(
        opacity: opacity,
        child: item.assetPath!.endsWith('.svg')
            ? SvgPicture.asset(item.assetPath!, fit: BoxFit.contain)
            : Image.asset(item.assetPath!, fit: BoxFit.contain),
      );
    }

    // No asset — show a category icon
    return Icon(
      _iconFor(item.category),
      size: 42,
      color: owned
          ? Colors.green.shade400
          : _categoryColor(item.category),
    );
  }

  static IconData _iconFor(ShopItemCategory cat) => switch (cat) {
        ShopItemCategory.title  => Icons.military_tech_rounded,
        ShopItemCategory.inGame => Icons.sports_esports_rounded,
        ShopItemCategory.avatar => Icons.face_rounded,
        ShopItemCategory.background => Icons.palette_rounded,
        ShopItemCategory.border => Icons.crop_square_rounded,
        ShopItemCategory.emblem => Icons.workspace_premium_rounded,
      };

  static Color _categoryColor(ShopItemCategory cat) => switch (cat) {
        ShopItemCategory.title  => Colors.purple.shade300,
        ShopItemCategory.inGame => Colors.teal.shade300,
        ShopItemCategory.avatar => Colors.blue.shade300,
        ShopItemCategory.background => Colors.orange.shade300,
        ShopItemCategory.border => Colors.cyan.shade300,
        ShopItemCategory.emblem => Colors.amber.shade400,
      };
}

// ── Grid ──────────────────────────────────────────────────────────────────────

/// Displays a section header + grid of [ShopItemCard]s for [items].
class ShopItemGrid extends StatelessWidget {
  const ShopItemGrid({
    super.key,
    required this.sectionTitle,
    required this.items,
  });

  final String sectionTitle;
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            sectionTitle,
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
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => ShopItemCard(item: items[i]),
        ),
      ],
    );
  }
}

// ── Purchase dialog ───────────────────────────────────────────────────────────

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog({required this.item, required this.affordable});
  final ShopItem item;
  final bool affordable;

  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
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
            // Preview
            SizedBox(
              height: 80,
              child: _ItemPreview(item: widget.item, owned: false),
            ),
            const SizedBox(height: 16),

            // Name
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
              // Balance row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your balance',
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
                  Text('Cost',
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

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _executePurchase,
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
                      : Text('Buy for ⭐ ${widget.item.starPrice}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              // Not enough stars
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
                        'You need $needed more ⭐ to buy this.',
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Get Stars sheet opened from parent context via a
                    // separate tap on the header button
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Get More Stars',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: c.subtle)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executePurchase() async {
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

      // Dismiss dialog BEFORE notifyListeners (avoids GoRouter context crash)
      Navigator.of(context).pop();

      // Re-read from Firestore to sync stars + purchasedItems locally
      await provider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.item.name} purchased! ⭐'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on InsufficientStarsException {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough stars!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
}
