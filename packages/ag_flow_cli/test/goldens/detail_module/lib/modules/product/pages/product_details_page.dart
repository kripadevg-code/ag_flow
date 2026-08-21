import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/modules/product/components/details/product_details_appbar.dart';
import 'package:sample_app/modules/product/components/details/product_details_empty.dart';
import 'package:sample_app/modules/product/components/details/product_details_error.dart';
import 'package:sample_app/modules/product/components/details/product_details_loading.dart';
import 'package:sample_app/modules/product/controllers/product_details_controller.dart';

class ProductDetailsPage extends AgBasePage<ProductDetailsController> {
  const ProductDetailsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => ProductDetailsAppBar();

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
    final data = controller.state.dataOrNull;
    // TODO: replace with the real detail UI.
    return Center(child: Text(data.toString()));
  }
}
