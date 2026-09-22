import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/project_details_controller.dart';
import 'package:ag_showcase_tasks/modules/projects/repos/project_details_repo.dart';
import 'package:ag_showcase_tasks/modules/projects/services/projects_service.dart';

class ProjectDetailsBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => ProjectsService(AgLocator.find()));
    lazyPut(() => ProjectDetailsRepo(AgLocator.find()));
    lazyPut(() => ProjectDetailsController(AgLocator.find()));
  }
}
