import 'package:flutter/material.dart';

/// A reusable view widget for the {{component_class_prefix}} detail.
/// Generated as a starting point — customize freely.
class {{component_class_prefix}}View extends StatelessWidget {
  const {{component_class_prefix}}View({super.key, required this.data});

  /// The fetched detail data. Replace `dynamic` with your real model type.
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    // TODO: replace with the real detail UI.
    return Center(child: Text(data.toString()));
  }
}
