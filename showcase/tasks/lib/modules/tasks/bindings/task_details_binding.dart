import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/task_details_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/task_details_repo.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

class TaskDetailsBinding extends AgBinding {
  @override
  void dependencies() {
    // TasksService may already be live if the Tasks list is still on the
    // stack. AgLocator is reference-counted by AgApp's binding lifecycle,
    // so registering again here is safe — lazyPut is a no-op if the type
    // is already registered.
    lazyPut(() => TasksService(AgLocator.find()));
    lazyPut(() => TaskDetailsRepo(AgLocator.find()));
    lazyPut(() => TaskDetailsController(AgLocator.find()));
  }
}
