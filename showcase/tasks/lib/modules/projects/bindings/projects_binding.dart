import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/projects_controller.dart';
import 'package:ag_showcase_tasks/modules/projects/repos/projects_repo.dart';
import 'package:ag_showcase_tasks/modules/projects/services/projects_service.dart';

class ProjectsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => ProjectsService(AgLocator.find()));
    lazyPut(() => ProjectsRepo(AgLocator.find()));
    lazyPut(() => ProjectsController(AgLocator.find()));
  }
}
