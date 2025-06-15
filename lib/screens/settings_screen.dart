import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final List<Product> products = [
    Product(
      name: 'Beach Volleyball',
      description: 'Durable outdoor ball, ideal for beach games.',
      price: 24.99,
      imagePath: 'assets/volleyball.svg',
    ),
    Product(
      name: 'Hiking Backpack',
      description: 'Lightweight with 30L capacity and waterproof design.',
      price: 59.99,
      imagePath: 'assets/backpack.svg',
    ),
    Product(
      name: 'Tennis Racket',
      description: 'Carbon-fiber frame with high tension strings.',
      price: 89.00,
      imagePath: 'assets/racket.svg',
    ),
    Product(
      name: 'Running Shoes',
      description: 'Breathable shoes for trail and road runs.',
      price: 74.50,
      imagePath: 'assets/shoes.svg',
    ),
  ];

  final Color grey = Colors.grey;
  final Color orange = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: grey,
        child: ListView.builder(
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
                boxShadow: [
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
                    'assets/otter_canvas.svg',
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Add buy functionality or link
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
        ),
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
