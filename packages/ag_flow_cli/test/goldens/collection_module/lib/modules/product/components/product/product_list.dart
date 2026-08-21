import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/modules/product/components/product/product_item.dart';

/// Renders the Product collection's success content.
/// Generated as a starting point — customize freely.
class ProductList extends StatelessWidget {
  const ProductList({super.key, required this.controller});

  final AgListController<dynamic, int> controller;

  @override
  Widget build(BuildContext context) {
    return AgListBuilder<dynamic, int>(
      controller: controller,
      itemBuilder: (context, item, index) => ProductItem(item: item),
    );
  }
}
