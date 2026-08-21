import 'package:flutter/material.dart';

/// The loading state for the Product page.
/// Generated as a starting point — customize freely, or delete this file
/// and its use in the page to fall back to AG's default loading widget.
class ProductLoading extends StatelessWidget {
  const ProductLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
