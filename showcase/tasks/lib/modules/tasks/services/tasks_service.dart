import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/endpoints.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';

/// Tasks service.
///
/// The action mixins fix each method's name and types; the bodies below
/// are this Service's own, written against the backend with `get` / `post` / ....
/// [list] sends the declared [pagination]'s query for the page. A resource
/// that supports less mixes in only those actions.
class TasksService extends AgBaseService
    with
        AgListMixin<Task>,
        AgCreateMixin<Task>,
        AgRetrieveMixin<Task, int>,
        AgUpdateMixin<Task, int>,
        AgDestroyMixin<int> {
  TasksService(super.apiProvider);

  static TasksService get instance => AgLocator.find<TasksService>();

  // jsonplaceholder paginates with ?_start=N&_limit=N (limit/offset)
  @override
  AgPagination get pagination => const AgLimitOffsetPagination(
    offsetParam: '_start',
    limitParam: '_limit',
  );

  @override
  Future<List<Task>> list({int page = 1}) => get(
    TaskEndpoints.tasks,
    queryParams: pagination.query(page),
    decode: (json) => [
      for (final item in json! as List<Object?>) Task.fromJson(item! as Map<String, dynamic>),
    ],
  );

  @override
  Future<Task> create(Task item) => post(
    TaskEndpoints.tasks,
    body: item.toJson(),
    decode: (json) => Task.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<Task> retrieve(int id) => get(
    TaskEndpoints.taskById,
    pathParams: {'id': id},
    decode: (json) => Task.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<Task> update(int id, Task item) => put(
    TaskEndpoints.taskById,
    pathParams: {'id': id},
    body: item.toJson(),
    decode: (json) => Task.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<void> destroy(int id) => delete(TaskEndpoints.taskById, pathParams: {'id': id});
}
