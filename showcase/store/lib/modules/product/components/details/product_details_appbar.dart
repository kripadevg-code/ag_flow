import 'package:flutter/material.dart';

/// The app bar for the ProductDetails page — an edit action that opens a
/// dialog pre-filled with the current title/price/description.
class ProductDetailsAppBar extends AppBar {
  ProductDetailsAppBar({required VoidCallback onEdit, super.key})
    : super(
        title: const Text('Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
        ],
      );
}
