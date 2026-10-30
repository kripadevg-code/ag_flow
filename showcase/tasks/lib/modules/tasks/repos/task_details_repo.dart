import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

/// Task details repo: reads and updates the task the details page shows.
///
/// It sits over the module's shared [TasksService], which already has
/// `retrieve`/`update`, so no separate details Service is needed.
class TaskDetailsRepo extends AgBaseRepo {
  const TaskDetailsRepo(this._service);

  final TasksService _service;

  Future<Task> retrieve(int id) => guard(() => _service.retrieve(id));

  Future<Task> update(int id, Task item) =>
      guard(() => _service.update(id, item));
}
