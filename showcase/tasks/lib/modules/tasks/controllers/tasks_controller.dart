import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/tasks_repo.dart';

/// Paginated tasks list controller.
///
/// Loading and refresh come from [AgBaseController], paging from
/// [AgLoadMore]. This app's backend (jsonplaceholder) doesn't persist
/// writes, and a refresh would also jump the list back to the top, so each
/// write reflects the mutation directly in the shown list.
class TasksController extends AgBaseController<List<Task>>
    with AgLoadMore<Task> {
  TasksController(this._repo);

  final TasksRepo _repo;

  static TasksController get find => AgLocator.find<TasksController>();

  @override
  Future<List<Task>> list({int page = 1}) => _repo.list(page: page);

  @override
  bool isLastPage(List<Task> items) => _repo.isLastPage(items);

  /// Creates the task, then prepends what the backend returned —
  /// jsonplaceholder echoes back a fixed id and doesn't persist, so a
  /// refresh would never show it.
  Future<void> create(Task item) async {
    final created = await _repo.create(item);
    _show([created, ..._shown]);
  }

  /// Replaces the task optimistically: the list shows [item] immediately
  /// and rolls back to the previous value if the backend rejects it.
  Future<void> update(int id, Task item) async {
    final previous = _shown.where((t) => t.id == id).firstOrNull;
    if (previous == null) return;
    _replace(id, item);
    try {
      await _repo.update(id, item);
    } on Object {
      _replace(id, previous); // roll back
    }
  }

  /// Deletes the task, then removes it from the displayed list.
  Future<void> destroy(int id) async {
    await _repo.destroy(id);
    _show(_shown.where((t) => t.id != id).toList());
  }

  /// Toggles the completed flag — a feature-specific method expressed
  /// through the (optimistic) [update] action.
  Future<void> toggleCompleted(Task task) =>
      update(task.id, task.copyWith(completed: !task.completed));

  List<Task> get _shown => state.dataOrNull ?? const [];

  void _show(List<Task> items) => emit(AgPageState.success(items));

  void _replace(int id, Task task) => _show([
    for (final t in _shown)
      if (t.id == id) task else t,
  ]);
}
