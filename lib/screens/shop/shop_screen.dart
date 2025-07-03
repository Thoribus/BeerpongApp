import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'avatar_shop_view.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  ShopScreenState createState() => ShopScreenState();
}

class ShopScreenState extends State<ShopScreen> {
  final PageController _tabPageController = PageController();
  int _currentTabPage = 0;

  final List<Product> products = [
    Product(
      name: 'Beach Volleyball',
      description: 'Durable outdoor ball, ideal for beach games.',
      price: 24.99,
      imagePath: 'assets/otter_canvas.svg',
    ),
    Product(
      name: 'Hiking Backpack',
      description: 'Lightweight with 30L capacity and waterproof design.',
      price: 59.99,
      imagePath: 'assets/otter_canvas.svg',
    ),
    Product(
      name: 'Tennis Racket',
      description: 'Carbon-fiber frame with high tension strings.',
      price: 89.00,
      imagePath: 'assets/otter_canvas.svg',
    ),
    Product(
      name: 'Running Shoes',
      description: 'Breathable shoes for trail and road runs.',
      price: 74.50,
      imagePath: 'assets/otter_canvas.svg',
    ),
  ];

  final Color grey = Colors.grey;
  final Color orange = Colors.orange;

  @override
  void dispose() {
    _tabPageController.dispose();
    super.dispose();
  }

  Widget _buildTabPageSelector() {
    final List<String> tabs = ["Avatar", "User Card", "In Game"];

    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _currentTabPage == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (_currentTabPage != index) {
                    setState(() {
                      _currentTabPage = index;
                    });
                    _tabPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                product.imagePath,
                width: 80,
                height: 80,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Add buy functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                          ),
                          child: const Text('BUY'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        children: [
          AvatarShopScreen(),
          const Center(child: Text('User Card Shop — coming soon')),
          _buildProductList(), // In Game Shop
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabPageSelector(),
          _buildPageView(),
        ],
      ),
    );
  }
}

class Product {
  final String name;
  final String description;
  final double price;
  final String imagePath;

  Product({
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
  });
}
