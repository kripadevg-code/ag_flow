import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/tasks_repo.dart';

/// Paginated tasks list controller.
///
/// Uses [AgListController] for automatic load-more, refresh, and
/// pagination state. Mutations (toggle, delete, add) use
/// [AgListController.updateItems] — the optimistic mutation escape hatch —
/// rather than a full [refresh] so the list never jumps back to the top
/// and the backend round-trip for a non-persisting API is avoided.
class TasksController extends AgListController<Task, int> {
  TasksController(this._repo) : super(initialPageKey: 0);

  static TasksController get find => AgLocator.find<TasksController>();

  final TasksRepo _repo;

  @override
  Future<AgListPage<Task, int>> fetchPage(int pageKey) =>
      _repo.getPage(pageKey);

  /// Toggles the completed flag optimistically.
  Future<void> toggleCompleted(Task task) async {
    final toggled = task.copyWith(completed: !task.completed);
    // Reflect immediately in the UI — optimistic update.
    updateItems(
      (items) => [
        for (final t in items)
          if (t.id == task.id) toggled else t,
      ],
    );
    try {
      await _repo.update(task.id, toggled);
    } catch (_) {
      // Roll back on error.
      updateItems(
        (items) => [
          for (final t in items)
            if (t.id == toggled.id) task else t,
        ],
      );
    }
  }

  Future<void> add(Task item) async {
    final created = await _repo.add(item);
    // jsonplaceholder echoes back a fixed id and doesn't persist —
    // reflect directly so the user sees their new task immediately.
    updateItems((items) => [created, ...items]);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    updateItems((items) => items.where((t) => t.id != id).toList());
  }
}
