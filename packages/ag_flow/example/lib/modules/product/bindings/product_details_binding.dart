import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/controllers/product_details_controller.dart';
import 'package:ag_flow_example/modules/product/repos/product_details_repo.dart';
import 'package:ag_flow_example/modules/product/services/product_details_service.dart';

class ProductDetailsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => ProductDetailsService(AgLocator.find()));
    lazyPut(() => ProductDetailsRepo(AgLocator.find()));
    lazyPut(() => ProductDetailsController(AgLocator.find()));
  }
}
