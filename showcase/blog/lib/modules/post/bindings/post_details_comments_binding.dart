import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/controllers/post_details_comments_controller.dart';
import 'package:ag_showcase_blog/modules/post/repos/post_details_comments_repo.dart';
import 'package:ag_showcase_blog/modules/post/services/post_details_comments_service.dart';

class PostDetailsCommentsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => PostDetailsCommentsService(AgLocator.find()));
    lazyPut(() => PostDetailsCommentsRepo(AgLocator.find()));
    lazyPut(() => PostDetailsCommentsController(AgLocator.find()));
  }
}
