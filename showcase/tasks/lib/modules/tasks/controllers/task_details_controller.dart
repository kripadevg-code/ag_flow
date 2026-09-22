import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/task_details_repo.dart';

/// Detail controller for a single task.
///
/// Extends [AgDetailController] — it resolves the navigation argument from
/// the route's path parameters automatically so the page opens correctly
/// from a deep link, a push notification, or an in-app tap.
class TaskDetailsController
    extends AgDetailController<Task, TaskDetailsPageArgument> {
  TaskDetailsController(this._repo);

  static TaskDetailsController get find =>
      AgLocator.find<TaskDetailsController>();

  final TaskDetailsRepo _repo;

  @override
  TaskDetailsPageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => TaskDetailsPageArgument.fromPathParameters(pathParameters);

  @override
  Future<Task> fetch() => _repo.getByArgument(arguments);

  Future<void> toggleCompleted() async {
    final current = state.dataOrNull;
    if (current == null) return;
    final toggled = current.copyWith(completed: !current.completed);
    emit(AgPageState.success(toggled));
    try {
      final saved = await _repo.update(arguments, toggled);
      emit(AgPageState.success(saved));
    } catch (_) {
      emit(AgPageState.success(current)); // roll back
    }
  }
}
