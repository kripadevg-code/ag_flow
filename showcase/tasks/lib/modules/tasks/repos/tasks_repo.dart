import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

/// Tasks repo — the boundary between controllers and services.
///
/// Controllers only call methods on the Repo; they never call a Service
/// directly. This boundary makes the controller testable without a real
/// HTTP client.
class TasksRepo extends AgBaseRepo {
  const TasksRepo(this._service);

  final TasksService _service;

  Future<AgListPage<Task, int>> getPage(int offset) => _service.getPage(offset);

  Future<Task> add(Task item) => _service.add(item);

  Future<Task> update(int id, Task item) => _service.update(id, item);

  Future<void> delete(int id) => _service.delete(id);
}
