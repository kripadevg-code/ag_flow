import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/task_details_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/task_details_repo.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

class TaskDetailsBinding extends AgBinding {
  @override
  void dependencies() {
    // The details page reuses TasksService (it already has
    // getById/update). Each details route registers its own, released
    // when that route is disposed.
    lazyPut(() => TasksService(AgLocator.find()));
    lazyPut(() => TaskDetailsRepo(AgLocator.find(), AgLocator.find()));
    lazyPut(() => TaskDetailsController(AgLocator.find()));
  }
}
