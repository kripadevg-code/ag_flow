import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/modules/product/controllers/products_controller.dart';
import 'package:sample_app/modules/product/repos/products_repo.dart';
import 'package:sample_app/modules/product/services/products_service.dart';

class ProductsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => ProductsService(AgLocator.find()));
    lazyPut(() => ProductsRepo(AgLocator.find()));
    lazyPut(() => ProductsController(AgLocator.find()));
  }
}
