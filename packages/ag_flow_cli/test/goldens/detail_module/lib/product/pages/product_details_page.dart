import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/product/controllers/product_details_controller.dart';

class ProductDetailsPage extends AgBasePage<ProductDetailsController> {
  const ProductDetailsPage({super.key});

  @override
  Widget buildSuccess(BuildContext context) {
    final data = controller.state.dataOrNull;
    // TODO: replace with the real detail UI.
    return Center(child: Text(data.toString()));
  }
}
