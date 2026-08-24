import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/controllers/post_details_controller.dart';
import 'package:ag_showcase_blog/modules/post/repos/post_details_repo.dart';
import 'package:ag_showcase_blog/modules/post/services/post_details_service.dart';

class PostDetailsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => PostDetailsService(AgLocator.find()));
    lazyPut(() => PostDetailsRepo(AgLocator.find()));
    lazyPut(() => PostDetailsController(AgLocator.find()));
  }
}
