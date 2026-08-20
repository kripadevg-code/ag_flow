import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/product/components/details/product_details_view.dart';
import 'package:ag_flow_example/product/controllers/product_details_controller.dart';
import 'package:flutter/material.dart';

/// The detail page for a single product.
///
/// Independently overrides only [loadingBuilder] — Error and Empty stay AG
/// defaults, a different override combination from [ProductsPage],
/// demonstrating requirments/ag_framework.md §15 a second way.
class ProductDetailsPage extends AgBasePage<ProductDetailsController> {
  const ProductDetailsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return AppBar(
      title: const Text('Product details'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
          onPressed: () => _showEditDialog(context),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final current = controller.state.dataOrNull;
    if (current == null) return;

    final nameController = TextEditingController(text: current.name);
    final descriptionController = TextEditingController(
      text: current.description,
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave ?? false) {
      await controller.updateProduct(
        nameController.text,
        descriptionController.text,
      );
    }
  }

  @override
  WidgetBuilder? get loadingBuilder =>
      (context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Fetching product…'),
            ],
          ),
        ),
      );

  @override
  Widget buildSuccess(BuildContext context) {
    return ProductDetailsView(product: controller.state.dataOrNull!);
  }
}
