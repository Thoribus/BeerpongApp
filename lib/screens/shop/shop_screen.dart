import 'package:beerpongapp/services/ad_rate_limiter.dart';
import 'package:beerpongapp/services/ad_service.dart';
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
      tabs: const ['Avatar', 'User Card', 'In Game'],
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
              'Sign in to earn Stars',
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
                  label: const Text('Get Stars'),
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

  void _showGetStarsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _GetStarsSheet(),
    );
  }
}

/// Bottom sheet — rewarded video ads + IAP packs (packs wired in Phase 12).
class _GetStarsSheet extends StatefulWidget {
  const _GetStarsSheet();

  @override
  State<_GetStarsSheet> createState() => _GetStarsSheetState();
}

class _GetStarsSheetState extends State<_GetStarsSheet> {
  int _remaining = AdRateLimiter.dailyLimit;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    _loadRemaining();
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
          const SnackBar(
            content: Text('No ad available right now. Try again later.'),
          ),
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
            const SnackBar(content: Text('You earned 50 ⭐!')),
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
              'Get Stars',
              style: TextStyle(
                color: c.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Earn ⭐ stars to spend in the shop.',
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
            // ── IAP packs (Phase 12) ────────────────────────────────────────
            const _SheetRow(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              title: 'Starter Pack  ·  €1.99',
              subtitle: '200 ⭐',
              badgeLabel: 'Coming soon',
            ),
            const SizedBox(height: 12),
            const _SheetRow(
              icon: Icons.star_rounded,
              iconColor: Colors.orange,
              title: 'Popular Pack  ·  €4.99',
              subtitle: '600 ⭐  ·  Best value',
              badgeLabel: 'Coming soon',
            ),
            const SizedBox(height: 12),
            const _SheetRow(
              icon: Icons.star_rounded,
              iconColor: Colors.deepOrange,
              title: 'Mega Pack  ·  €9.99',
              subtitle: '1 500 ⭐',
              badgeLabel: 'Coming soon',
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Earn stars for free by playing games!',
                style: TextStyle(color: c.subtle, fontSize: 12),
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
                    'Watch a short video',
                    style: TextStyle(
                      color: c.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    remaining > 0
                        ? '+50 ⭐  ·  $remaining of ${AdRateLimiter.dailyLimit} watches remaining today'
                        : 'Daily limit reached — come back tomorrow',
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
