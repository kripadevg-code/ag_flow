import 'package:flutter/material.dart';

/// The app bar for the Product page — a category filter menu alongside
/// the title. `null` means "All categories".
class ProductAppBar extends AppBar {
  ProductAppBar({
    required void Function(String? category) onCategorySelected,
    super.key,
  }) : super(
         title: const Text('Products'),
         actions: [
           PopupMenuButton<String?>(
             icon: const Icon(Icons.filter_list),
             tooltip: 'Filter by category',
             onSelected: onCategorySelected,
             itemBuilder: (context) => const [
               PopupMenuItem(value: null, child: Text('All')),
               PopupMenuItem(value: 'electronics', child: Text('Electronics')),
               PopupMenuItem(value: 'jewelery', child: Text('Jewelery')),
               PopupMenuItem(
                 value: "men's clothing",
                 child: Text("Men's clothing"),
               ),
               PopupMenuItem(
                 value: "women's clothing",
                 child: Text("Women's clothing"),
               ),
             ],
           ),
         ],
       );
}
