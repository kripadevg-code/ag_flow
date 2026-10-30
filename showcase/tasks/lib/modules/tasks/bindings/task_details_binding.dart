import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/task_details_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/task_details_repo.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

class TaskDetailsBinding extends AgBinding {
  @override
  void dependencies() {
    // The details page reuses TasksService (it already has
    // getById/update). Binding lifetimes are reference-counted per
    // binding type by AgRoutePage, so this registration is released when
    // the last details route is disposed.
    lazyPut(() => TasksService(AgLocator.find()));
    lazyPut(() => TaskDetailsRepo(AgLocator.find()));
    lazyPut(() => TaskDetailsController(AgLocator.find()));
  }
}
