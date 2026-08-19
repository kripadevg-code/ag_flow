import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{root_segment}}/controllers/{{module_file_base}}_controller.dart';
import 'package:flutter/material.dart';

class {{module_class_prefix}}Page extends AgBasePage<{{module_class_prefix}}Controller> {
  const {{module_class_prefix}}Page({super.key});

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
