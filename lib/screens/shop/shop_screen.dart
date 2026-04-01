import 'dart:async';

import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/services/ad_rate_limiter.dart';
import 'package:beerpongapp/services/ad_service.dart';
import 'package:beerpongapp/services/purchase_service.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'avatar_shop_view.dart';
import 'user_card_shop_view.dart';
import 'in_game_shop_view.dart';
import '../../widgets/app_tab_bar.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  ShopScreenState createState() => ShopScreenState();
}

class ShopScreenState extends State<ShopScreen> {
  final PageController _tabPageController = PageController();
  int _currentTabPage = 0;

  @override
  void dispose() {
    _tabPageController.dispose();
    super.dispose();
  }

  Widget _buildTabPageSelector() {
    return AppTabBar(
      tabs: [context.loc.shopTabAvatar, context.loc.shopTabUserCard, context.loc.shopTabInGame],
      selectedIndex: _currentTabPage,
      onTabSelected: (index) {
        if (_currentTabPage != index) {
          setState(() => _currentTabPage = index);
        }
      },
      pageController: _tabPageController,
      backgroundColor: Colors.grey.shade800,
    );
  }

  Widget _buildPageView() {
    return Expanded(
      child: PageView(
        controller: _tabPageController,
        onPageChanged: (index) {
          setState(() {
            _currentTabPage = index;
          });
        },
        children: const [
          AvatarShopScreen(),
          UserCardShopView(),
          InGameShopView(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _ShopHeader(),
          _buildTabPageSelector(),
          _buildPageView(),
        ],
      ),
    );
  }
}

/// Persistent header showing the signed-in user's star balance and a
/// "Get Stars" button. Collapses to a sign-in prompt when no user is logged in.
class _ShopHeader extends StatelessWidget {
  const _ShopHeader();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = context.watch<UserProvider>().user;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(
          bottom: BorderSide(color: c.subtle.withValues(alpha: 0.2)),
        ),
      ),
      child: user == null
          ? Text(
              context.loc.shopSignInEarnStars,
              style: TextStyle(color: c.subtle, fontSize: 13),
              textAlign: TextAlign.center,
            )
          : Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 6),
                Text(
                  '${user.stars}',
                  style: TextStyle(
                    color: c.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showGetStarsSheet(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.loc.shopGetStars),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showGetStarsSheet(BuildContext context) =>
      GetStarsSheet.show(context);
}

/// Bottom sheet — rewarded video ads + IAP packs (packs wired in Phase 12).
class GetStarsSheet extends StatefulWidget {
  const GetStarsSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => const GetStarsSheet(),
      );

  @override
  State<GetStarsSheet> createState() => _GetStarsSheetState();
}

class _GetStarsSheetState extends State<GetStarsSheet> {
  int _remaining = AdRateLimiter.dailyLimit;
  bool _isLoadingAd = false;
  StreamSubscription<PurchaseEvent>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    _loadRemaining();
    _purchaseSub = context.read<PurchaseService>().events.listen(_onPurchaseEvent);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _onPurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    if (event is PurchaseSuccess) {
      context.read<UserProvider>().refreshUser();
      if (event.productId == PurchaseService.supporterPackId) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.loc.shopSupporterTitle),
            content: Text(context.loc.shopSupporterBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(context.loc.shopSupporterBtn),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.shopStarsAwarded(event.starsAwarded))),
        );
      }
    } else if (event is PurchaseFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.shopPurchaseFailed(event.message))),
      );
    }
    // PurchaseCanceled — no feedback needed.
  }

  Future<void> _loadRemaining() async {
    final r = await AdRateLimiter.instance.remainingToday();
    if (mounted) setState(() => _remaining = r);
  }

  Future<void> _watchAd() async {
    if (_remaining <= 0 || _isLoadingAd) return;
    setState(() => _isLoadingAd = true);

    // Capture before any async gaps.
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.user?.id;

    // Preload if not ready yet.
    if (!AdService.instance.isReady) {
      await AdService.instance.preload();
      // Poll briefly — ad loads are async.
      for (var i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (AdService.instance.isReady) break;
      }
    }

    if (!AdService.instance.isReady) {
      if (mounted) {
        setState(() => _isLoadingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.shopNoAdAvailable)),
        );
      }
      return;
    }

    AdService.instance.showRewardedAd(
      onRewarded: () async {
        await AdRateLimiter.instance.recordWatch();
        if (userId != null) {
          await FirestoreService.instance
              .creditStars(userId: userId, amount: 50);
          await userProvider.refreshUser();
        }
        if (mounted) {
          setState(() {
            _remaining = (_remaining - 1).clamp(0, AdRateLimiter.dailyLimit);
            _isLoadingAd = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.loc.shopEarned50Stars)),
          );
        }
      },
      onFailed: () {
        if (mounted) setState(() => _isLoadingAd = false);
      },
    );
    // _isLoadingAd is reset inside the ad callbacks above, not here.
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.shopGetStars,
              style: TextStyle(
                color: c.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.loc.shopEarnStarsHint,
              style: TextStyle(color: c.subtle, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // ── Rewarded video ──────────────────────────────────────────────
            _WatchVideoRow(
              remaining: _remaining,
              isLoading: _isLoadingAd,
              onTap: _remaining > 0 ? _watchAd : null,
            ),
            const Divider(height: 24),
            // ── IAP packs ───────────────────────────────────────────────────
            Builder(builder: (context) {
              final ps = context.watch<PurchaseService>();
              final isSupporter =
                  context.watch<UserProvider>().user?.isSupporter ?? false;
              if (ps.isAvailable && ps.products.isNotEmpty) {
                return Column(
                  children: [
                    for (final product in ps.products) ...[
                      _IapPackRow(
                        product: product,
                        isPurchasing: ps.isPurchasing,
                        isAlreadyOwned: product.id ==
                                PurchaseService.supporterPackId &&
                            isSupporter,
                        onTap: () => ps.buy(product),
                      ),
                      if (product != ps.products.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              // Fallback when store is unavailable or products not yet loaded.
              return Column(
                children: [
                  _SheetRow(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    title: context.loc.shopStarterPackTitle,
                    subtitle: context.loc.shopStarterPackSubtitle,
                    badgeLabel: context.loc.shopComingSoon,
                  ),
                  const SizedBox(height: 12),
                  _SheetRow(
                    icon: Icons.star_rounded,
                    iconColor: Colors.orange,
                    title: context.loc.shopPopularPackTitle,
                    subtitle: context.loc.shopPopularPackSubtitle,
                    badgeLabel: context.loc.shopComingSoon,
                  ),
                  const SizedBox(height: 12),
                  _SheetRow(
                    icon: Icons.star_rounded,
                    iconColor: Colors.deepOrange,
                    title: context.loc.shopMegaPackTitle,
                    subtitle: context.loc.shopMegaPackSubtitle,
                    badgeLabel: context.loc.shopComingSoon,
                  ),
                  const SizedBox(height: 12),
                  _SheetRow(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    title: context.loc.shopSupporterPackFull,
                    subtitle: context.loc.shopSupporterPackFullSubtitle,
                    badgeLabel: isSupporter ? context.loc.shopSupporterBadge : context.loc.shopComingSoon,
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            Center(
              child: Text(
                context.loc.shopEarnFreeStars,
                style: TextStyle(color: c.subtle, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => context.read<PurchaseService>().restorePurchases(),
                child: Text(
                  context.loc.shopRestorePurchases,
                  style: TextStyle(color: c.subtle, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rewarded-video row with live remaining-count and loading spinner.
class _WatchVideoRow extends StatelessWidget {
  const _WatchVideoRow({
    required this.remaining,
    required this.isLoading,
    required this.onTap,
  });

  final int remaining;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final canWatch = remaining > 0 && !isLoading;
    return InkWell(
      onTap: canWatch ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              color: canWatch ? Colors.green : c.subtle,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.shopWatchVideo,
                    style: TextStyle(
                      color: c.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    remaining > 0
                        ? context.loc.shopWatchesRemaining(remaining, AdRateLimiter.dailyLimit)
                        : context.loc.shopDailyLimitReached,
                    style: TextStyle(color: c.subtle, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.subtle,
                ),
              )
            else if (remaining <= 0)
              Icon(Icons.check_circle_outline, color: c.subtle, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Live IAP pack row — shows the OS-localised price and a buy button.
class _IapPackRow extends StatelessWidget {
  const _IapPackRow({
    required this.product,
    required this.isPurchasing,
    required this.isAlreadyOwned,
    required this.onTap,
  });

  final dynamic product; // ProductDetails from in_app_purchase
  final bool isPurchasing;
  final bool isAlreadyOwned;
  final VoidCallback onTap;

  Color get _iconColor {
    final stars = PurchaseService.starsForProduct(product.id);
    if (stars >= 1500) return Colors.deepOrange;
    if (stars >= 600) return Colors.orange;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final stars = PurchaseService.starsForProduct(product.id);
    final isBestValue = product.id.contains('stars_600');

    return InkWell(
      onTap: isPurchasing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.star_rounded, color: _iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.title.replaceAll(RegExp(r'\(.*?\)'), '').trim()}  ·  ${product.price}',
                    style: TextStyle(
                      color: c.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    product.id == PurchaseService.supporterPackId
                        ? '$stars ⭐  ·  Supporter badge on your profile'
                        : '$stars ⭐${isBestValue ? '  ·  Best value' : ''}',
                    style: TextStyle(color: c.subtle, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isAlreadyOwned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Text(
                  context.loc.shopSupporterBadge,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isPurchasing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.subtle),
              )
            else
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                child: Text(context.loc.shopBuyBtn),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: c.onBackground, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(color: c.subtle, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c.subtle.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(color: c.subtle, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
