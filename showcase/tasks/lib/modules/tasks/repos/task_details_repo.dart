import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

class TaskDetailsRepo extends AgBaseRepo {
  const TaskDetailsRepo(this._service);

  final TasksService _service;

  Future<Task> getByArgument(TaskDetailsPageArgument arg) =>
      _service.getById(arg.taskId);

  Future<Task> update(TaskDetailsPageArgument arg, Task item) =>
      _service.update(arg.taskId, item);
}
