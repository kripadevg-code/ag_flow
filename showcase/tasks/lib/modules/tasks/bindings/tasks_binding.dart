import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/tasks_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/tasks_repo.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

// Service → Repo → Controller: each layer receives the layer below via
// AgLocator.find(). This is the standard AG binding pattern.
class TasksBinding extends AgBinding {
  @override
  void dependencies() {
    lazyPut(() => TasksService(AgLocator.find()));
    lazyPut(() => TasksRepo(AgLocator.find()));
    lazyPut(() => TasksController(AgLocator.find()));
  }
}
