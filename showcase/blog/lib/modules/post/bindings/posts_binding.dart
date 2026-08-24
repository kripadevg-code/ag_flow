import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/modules/post/controllers/posts_controller.dart';
import 'package:ag_showcase_blog/modules/post/repos/posts_repo.dart';
import 'package:ag_showcase_blog/modules/post/services/posts_service.dart';

class PostsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => PostsService(AgLocator.find()));
    lazyPut(() => PostsRepo(AgLocator.find()));
    lazyPut(() => PostsController(AgLocator.find()));
  }
}
