import 'package:flutter/material.dart';

/// The loading state for the ProductDetails page.
/// Generated as a starting point — customize freely, or delete this file
/// and its use in the page to fall back to AG's default loading widget.
class ProductDetailsLoading extends StatelessWidget {
  const ProductDetailsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
