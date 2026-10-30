import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/services/tasks_service.dart';
import 'package:ag_showcase_tasks/modules/tasks/stores/tasks_store.dart';

/// Tasks repo — the boundary between controllers and data sources.
///
/// Controllers only call methods on the Repo; they never call a Service
/// directly. This Repo works offline: every page it loads is saved to the
/// [TasksStore], and on a network error it returns the saved page instead.
/// Any other error (or a page never loaded) still reaches the controller.
class TasksRepo extends AgBaseRepo {
  const TasksRepo(this._service, this._store);

  final TasksService _service;
  final TasksStore _store;

  Future<List<Task>> list({int page = 1}) async {
    try {
      final items = await guard(() => _service.list(page: page));
      _store.savePage(page, items);
      return items;
    } on AgRepoException catch (e) {
      final saved = e.kind == AgRepoErrorKind.network ? _store.readPage(page) : null;
      if (saved == null) rethrow;
      return saved;
    }
  }

  bool isLastPage(List<Task> items) => _service.pagination.isLastPage(items);

  // Writes are not queued offline: a failed write still fails, so the
  // controller rolls it back. A successful one updates the store.

  Future<Task> create(Task item) async {
    final created = await guard(() => _service.create(item));
    _store.save(created);
    return created;
  }

  Future<Task> update(int id, Task item) async {
    final updated = await guard(() => _service.update(id, item));
    _store.save(updated);
    return updated;
  }

  Future<void> destroy(int id) async {
    await guard(() => _service.destroy(id));
    _store.remove(id);
  }
}
