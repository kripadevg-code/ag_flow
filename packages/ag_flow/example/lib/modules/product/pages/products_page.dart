import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/arguments/arguments.dart';
import 'package:ag_flow_example/core/routes/route_management.dart';
import 'package:ag_flow_example/modules/product/components/product/product_card.dart';
import 'package:ag_flow_example/modules/product/controllers/products_controller.dart';
import 'package:ag_flow_example/modules/product/models/product.dart';
import 'package:flutter/material.dart';

/// The collection page for products.
///
/// Independently overrides only [errorBuilder] — Loading and Empty stay AG
/// defaults, demonstrating requirments/ag_framework.md §15.
class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return AppBar(title: const Text('Products'));
  }

  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)?
  get errorBuilder =>
      (context, error, stackTrace, retry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load products.\n$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: retry, child: const Text('Try again')),
            ],
          ),
        ),
      );

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Product, int>(
      controller: controller,
      itemBuilder: (context, product, index) => ProductCard(
        product: product,
        onTap: () => RouteManagement.goToProductDetailsPage(
          ProductDetailsPageArgument(productId: product.id),
        ),
      ),
    );
  }
}
