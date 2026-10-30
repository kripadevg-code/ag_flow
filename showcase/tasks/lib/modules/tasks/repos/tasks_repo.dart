import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';

/// Tasks repo — the boundary between controllers and services.
///
/// Controllers only call methods on the Repo; they never call a Service
/// directly. To add caching or offline support, change a method here.
class TasksRepo extends AgBaseRepo {
  const TasksRepo(this._service);

  final TasksService _service;

  Future<List<Task>> list({int page = 1}) => _service.list(page: page);

  bool isLastPage(List<Task> items) => _service.pagination.isLastPage(items);

  Future<Task> create(Task item) => _service.create(item);

  Future<Task> update(int id, Task item) => _service.update(id, item);

  Future<void> destroy(int id) => _service.destroy(id);
}
