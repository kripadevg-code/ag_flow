import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:flutter/material.dart';

/// A reusable item widget for the Product collection: a card with the
/// product's thumbnail, title, price, rating, a delete action, and a tap
/// target that navigates to the product's details.
class ProductItem extends StatelessWidget {
  const ProductItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Product item;

  /// Navigates to this product's details page.
  final VoidCallback onTap;

  /// Deletes this product.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            item.image,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported_outlined),
          ),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text('\$${item.price.toStringAsFixed(2)}'),
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text('${item.ratingRate} (${item.ratingCount})'),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ),
    );
  }
}
