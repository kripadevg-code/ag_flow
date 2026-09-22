import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/project_tasks_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/tasks_repo.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

class ProjectTasksBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => TasksService(AgLocator.find()));
    lazyPut(() => TasksRepo(AgLocator.find()));
    lazyPut(() => ProjectTasksController(AgLocator.find()));
  }
}
