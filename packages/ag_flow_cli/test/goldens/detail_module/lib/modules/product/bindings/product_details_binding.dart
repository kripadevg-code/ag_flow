import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/modules/product/controllers/product_details_controller.dart';
import 'package:sample_app/modules/product/repos/product_details_repo.dart';
import 'package:sample_app/modules/product/services/product_details_service.dart';

class ProductDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut(() => ProductDetailsService(Get.find()))
      ..lazyPut(() => ProductDetailsRepo(Get.find()))
      ..lazyPut(() => ProductDetailsController(Get.find()));
  }
}
