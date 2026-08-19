import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/product/controllers/products_controller.dart';
import 'package:ag_flow_example/product/repos/products_repo.dart';
import 'package:ag_flow_example/product/services/products_service.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut(() => ProductsService(Get.find()))
      ..lazyPut(() => ProductsRepo(Get.find()))
      ..lazyPut(() => ProductsController(Get.find()));
  }
}
