import 'package:flutter/material.dart';

/// A reusable item widget for the Product collection.
/// Generated as a starting point — customize freely.
class ProductItem extends StatelessWidget {
  const ProductItem({required this.item, super.key});

  /// The item to render. Replace `dynamic` with your real model type.
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    // TODO: replace with the real item UI.
    return ListTile(title: Text(item.toString()));
  }
}
