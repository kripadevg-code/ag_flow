import 'package:flutter/material.dart';

/// A reusable item widget for the {{component_class_prefix}} collection.
/// Generated as a starting point — customize freely.
class {{component_class_prefix}}Item extends StatelessWidget {
  const {{component_class_prefix}}Item({required this.item, super.key});

  /// The item to render. Replace `dynamic` with your real model type.
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    // TODO: replace with the real item UI.
    return ListTile(title: Text(item.toString()));
  }
}
