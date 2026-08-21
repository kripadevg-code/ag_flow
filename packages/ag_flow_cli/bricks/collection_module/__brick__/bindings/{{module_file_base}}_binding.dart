import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/controllers/{{module_file_base}}_controller.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/repos/{{module_file_base}}_repo.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/services/{{module_file_base}}_service.dart';

class {{module_class_prefix}}Binding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut(() => {{module_class_prefix}}Service(Get.find()))
      ..lazyPut(() => {{module_class_prefix}}Repo(Get.find()))
      ..lazyPut(() => {{module_class_prefix}}Controller(Get.find()));
  }
}
