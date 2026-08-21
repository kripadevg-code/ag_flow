import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/modules/product/controllers/products_controller.dart';
import 'package:sample_app/modules/product/repos/products_repo.dart';
import 'package:sample_app/modules/product/services/products_service.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut(() => ProductsService(Get.find()))
      ..lazyPut(() => ProductsRepo(Get.find()))
      ..lazyPut(() => ProductsController(Get.find()));
  }
}
