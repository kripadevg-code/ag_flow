import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/arguments/arguments.dart';
import 'package:ag_showcase_store/core/routes/route_management.dart';
import 'package:ag_showcase_store/modules/product/components/product/product_appbar.dart';
import 'package:ag_showcase_store/modules/product/components/product/product_empty.dart';
import 'package:ag_showcase_store/modules/product/components/product/product_error.dart';
import 'package:ag_showcase_store/modules/product/components/product/product_item.dart';
import 'package:ag_showcase_store/modules/product/components/product/product_loading.dart';
import 'package:ag_showcase_store/modules/product/controllers/products_controller.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:flutter/material.dart';

class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => ProductAppBar(
    onCategorySelected: (category) => controller.filterByCategory(category),
  );

  @override
  WidgetBuilder? get loadingBuilder =>
      (context) => const ProductLoading();

  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)?
  get errorBuilder =>
      (context, error, stackTrace, retry) =>
          ProductError(error: error, onRetry: retry);

  @override
  WidgetBuilder? get emptyBuilder =>
      (context) => const ProductEmpty();

  @override
  Widget? floatingActionButton(BuildContext context) => FloatingActionButton(
    onPressed: () => _showAddProductDialog(context),
    tooltip: 'New product',
    child: const Icon(Icons.add),
  );

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Product, int>(
      controller: controller,
      itemBuilder: (context, item, index) => ProductItem(
        item: item,
        onTap: () => RouteManagement.goToProductDetailsPage(
          ProductDetailsPageArgument(productId: item.id),
        ),
        onDelete: () => controller.delete(item.id),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final imageController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New product'),
          content: SingleChildScrollView(
            child: Column(
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
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                controller.add(
                  Product(
                    id: 0,
                    title: titleController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    description: descriptionController.text,
                    category: categoryController.text,
                    image: imageController.text,
                    ratingRate: 0,
                    ratingCount: 0,
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
