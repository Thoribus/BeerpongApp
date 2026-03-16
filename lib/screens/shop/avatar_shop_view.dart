import 'package:beerpongapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarShopScreen extends StatelessWidget {
  AvatarShopScreen({super.key});

  final List<ShopItem> profilePictures = [
    ShopItem('assets/avatars/avatar_catpants.svg', 100),
    ShopItem('assets/avatars/avatar_catpants.svg', 200),
    ShopItem('assets/avatars/avatar_catpants.svg', 150),
  ];

  final List<ShopItem> avatarBorders = [
    ShopItem('assets/borders/avatar_border.svg', 300),
    ShopItem('assets/borders/avatar_border.svg', 250),
    ShopItem('assets/borders/avatar_border.svg', 200),
  ];

  final List<ShopItem> emblems = [
    ShopItem('assets/emblems/podium.svg', 180),
    ShopItem('assets/emblems/podium.svg', 220),
    ShopItem('assets/emblems/podium.svg', 260),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: Container(
        color: c.background,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ListView(
          children: [
            _buildCategory(context, 'Profile Pictures', profilePictures),
            _buildCategory(context, 'Avatar Borders', avatarBorders),
            _buildCategory(context, 'Emblems & Medals', emblems),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(
      BuildContext context, String title, List<ShopItem> items) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: c.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.6),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildShopItem(context, items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, ShopItem item) {
    final c = AppColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // TODO: Handle purchase logic
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  item.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopItem {
  final String assetPath;
  final int price;

  ShopItem(this.assetPath, this.price);
}
