import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{root_segment}}/components/{{component_namespace}}/{{component_file_base}}_item.dart';
import 'package:flutter/material.dart';

/// Renders the {{component_class_prefix}} collection's success content.
/// Generated as a starting point — customize freely.
class {{component_class_prefix}}List extends StatelessWidget {
  const {{component_class_prefix}}List({super.key, required this.controller});

  final AgListController<dynamic, int> controller;

  @override
  Widget build(BuildContext context) {
    return AgListBuilder<dynamic, int>(
      controller: controller,
      itemBuilder: (context, item, index) =>
          {{component_class_prefix}}Item(item: item),
    );
  }
}
