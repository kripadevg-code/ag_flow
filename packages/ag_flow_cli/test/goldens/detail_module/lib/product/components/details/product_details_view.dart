import 'package:flutter/material.dart';

/// A reusable view widget for the ProductDetails detail.
/// Generated as a starting point — customize freely.
class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({super.key, required this.data});

  /// The fetched detail data. Replace `dynamic` with your real model type.
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    // TODO: replace with the real detail UI.
    return Center(child: Text(data.toString()));
  }
}
