import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/modules/product/components/product/product_appbar.dart';
import 'package:sample_app/modules/product/components/product/product_empty.dart';
import 'package:sample_app/modules/product/components/product/product_error.dart';
import 'package:sample_app/modules/product/components/product/product_list.dart';
import 'package:sample_app/modules/product/components/product/product_loading.dart';
import 'package:sample_app/modules/product/controllers/products_controller.dart';

class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => ProductAppBar();

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
  Widget buildSuccess(BuildContext context) {
    return ProductList(controller: controller);
  }
}
