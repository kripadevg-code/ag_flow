import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';
import 'package:ag_showcase_tasks/modules/tasks/stores/tasks_store.dart';

/// Task details repo: reads and updates the task the details page shows.
///
/// It sits over the module's shared [TasksService], which already has
/// `retrieve`/`update`, so no separate details Service is needed. Like
/// `TasksRepo`, it falls back to the [TasksStore] on a network error.
class TaskDetailsRepo extends AgBaseRepo {
  const TaskDetailsRepo(this._service, this._store);

  final TasksService _service;
  final TasksStore _store;

  Future<Task> retrieve(int id) async {
    try {
      final item = await guard(() => _service.retrieve(id));
      _store.save(item);
      return item;
    } on AgRepoException catch (e) {
      final saved = e.kind == AgRepoErrorKind.network ? _store.read(id) : null;
      if (saved == null) rethrow;
      return saved;
    }
  }

  Future<Task> update(int id, Task item) async {
    final updated = await guard(() => _service.update(id, item));
    _store.save(updated);
    return updated;
  }
}
