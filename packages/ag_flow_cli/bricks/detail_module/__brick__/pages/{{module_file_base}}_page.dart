import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{root_segment}}/controllers/{{module_file_base}}_controller.dart';
import 'package:flutter/material.dart';

class {{module_class_prefix}}Page extends AgBasePage<{{module_class_prefix}}Controller> {
  const {{module_class_prefix}}Page({super.key});

  @override
  Widget buildSuccess(BuildContext context) {
    final data = controller.state.dataOrNull;
    // TODO: replace with the real detail UI.
    return Center(child: Text(data.toString()));
  }
}
