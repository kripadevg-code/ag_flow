import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/controllers/product_details_controller.dart';
import 'package:ag_showcase_store/modules/product/repos/product_details_repo.dart';
import 'package:ag_showcase_store/modules/product/services/product_details_service.dart';

class ProductDetailsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => ProductDetailsService(AgLocator.find()));
    lazyPut(() => ProductDetailsRepo(AgLocator.find()));
    lazyPut(() => ProductDetailsController(AgLocator.find()));
  }
}
