import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/components/{{component_namespace}}/{{component_file_base}}_appbar.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/components/{{component_namespace}}/{{component_file_base}}_empty.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/components/{{component_namespace}}/{{component_file_base}}_error.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/components/{{component_namespace}}/{{component_file_base}}_list.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/components/{{component_namespace}}/{{component_file_base}}_loading.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/controllers/{{module_file_base}}_controller.dart';
import 'package:flutter/material.dart';

class {{module_class_prefix}}Page extends AgBasePage<{{module_class_prefix}}Controller> {
  const {{module_class_prefix}}Page({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) =>
      {{component_class_prefix}}AppBar();

  @override
  WidgetBuilder? get loadingBuilder =>
      (context) => const {{component_class_prefix}}Loading();

  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)?
  get errorBuilder =>
      (context, error, stackTrace, retry) =>
          {{component_class_prefix}}Error(error: error, onRetry: retry);

  @override
  WidgetBuilder? get emptyBuilder =>
      (context) => const {{component_class_prefix}}Empty();

  @override
  Widget buildSuccess(BuildContext context) {
    return {{component_class_prefix}}List(controller: controller);
  }
}
