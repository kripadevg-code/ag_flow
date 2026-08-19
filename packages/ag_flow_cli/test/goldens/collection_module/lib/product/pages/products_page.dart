import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/product/controllers/products_controller.dart';

class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<dynamic, int>(
      controller: controller,
      itemBuilder: (context, item, index) {
        // TODO: replace with the real item widget.
        return ListTile(title: Text(item.toString()));
      },
    );
  }
}
