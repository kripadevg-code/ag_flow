import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/controllers/products_controller.dart';
import 'package:ag_flow_example/modules/product/repos/products_repo.dart';
import 'package:ag_flow_example/modules/product/services/products_service.dart';

class ProductsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => ProductsService(AgLocator.find()));
    lazyPut(() => ProductsRepo(AgLocator.find()));
    lazyPut(() => ProductsController(AgLocator.find()));
  }
}
