import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/components/details/product_details_appbar.dart';
import 'package:ag_showcase_store/modules/product/components/details/product_details_empty.dart';
import 'package:ag_showcase_store/modules/product/components/details/product_details_error.dart';
import 'package:ag_showcase_store/modules/product/components/details/product_details_loading.dart';
import 'package:ag_showcase_store/modules/product/controllers/product_details_controller.dart';
import 'package:flutter/material.dart';

class ProductDetailsPage extends AgBasePage<ProductDetailsController> {
  const ProductDetailsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      ProductDetailsAppBar(onEdit: () => _showEditDialog(context));

  @override
  WidgetBuilder? get loadingBuilder =>
      (context) => const ProductDetailsLoading();

  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)?
  get errorBuilder =>
      (context, error, stackTrace, retry) =>
          ProductDetailsError(error: error, onRetry: retry);

  @override
  WidgetBuilder? get emptyBuilder =>
      (context) => const ProductDetailsEmpty();

  @override
  Widget buildSuccess(BuildContext context) {
    final data = controller.state.dataOrNull!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.network(
              data.image,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported_outlined, size: 96),
            ),
          ),
          const SizedBox(height: 16),
          Text(data.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '\$${data.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${data.ratingRate} (${data.ratingCount} ratings)'),
              const SizedBox(width: 12),
              Chip(label: Text(data.category)),
            ],
          ),
          const SizedBox(height: 16),
          Text(data.description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final data = controller.state.dataOrNull;
    if (data == null) return;

    final titleController = TextEditingController(text: data.title);
    final priceController = TextEditingController(text: '${data.price}');
    final descriptionController = TextEditingController(text: data.description);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                controller.update(
                  data.copyWith(
                    title: titleController.text,
                    price: double.tryParse(priceController.text),
                    description: descriptionController.text,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
