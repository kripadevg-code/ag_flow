import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/endpoints.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';

/// Tasks service — pure declaration.
///
/// The five [AgCrudService] methods (getAll, getById, add, update, delete)
/// and [AgPagedService.getPage] are provided entirely by the two mixins.
/// This class declares five values: two endpoints, one page strategy, and
/// two codec hooks. There is no request, decoding, or pagination logic.
///
/// This is the AG service pattern for a resource that has both a paginated
/// list and full CRUD. A resource that only needs read gets [AgCrudService]
/// alone. A resource with no pagination gets [AgCrudService] alone too.
class TasksService extends AgBaseService
    with AgCrudService<Task, int>, AgPagedService<Task, int> {
  TasksService(super.apiProvider);

  static TasksService get instance => AgLocator.find<TasksService>();

  @override
  AgEndpoint get collectionEndpoint => TaskEndpoints.tasks;

  @override
  AgEndpoint get resourceEndpoint => TaskEndpoints.taskById;

  // jsonplaceholder paginates with ?_start=N&_limit=N (offset strategy)
  @override
  AgPageStrategy<int> get pageStrategy => const AgOffsetStrategy(
    offsetParam: '_start',
    limitParam: '_limit',
    pageSize: 20,
  );

  @override
  Task fromJson(Map<String, dynamic> json) => Task.fromJson(json);

  @override
  Map<String, dynamic> toJson(Task item) => item.toJson();
}
