import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/components/details/product_details_view.dart';
import 'package:ag_flow_example/modules/product/controllers/product_details_controller.dart';
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
    return AppBar(title: const Text('Product details'));
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
