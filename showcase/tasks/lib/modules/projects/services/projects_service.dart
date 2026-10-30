import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/endpoints.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';

class ProjectsService extends AgBaseService
    with
        AgListMixin<Project>,
        AgCreateMixin<Project>,
        AgRetrieveMixin<Project, int>,
        AgUpdateMixin<Project, int>,
        AgDestroyMixin<int> {
  ProjectsService(super.apiProvider);

  static ProjectsService get instance => AgLocator.find<ProjectsService>();

  @override
  AgPagination get pagination => const AgPageNumberPagination(
    pageParam: '_page',
    sizeParam: '_limit',
    pageSize: 10,
  );

  @override
  Future<List<Project>> list({int page = 1}) => get(
    ProjectEndpoints.projects,
    queryParams: pagination.query(page),
    decode: (json) => [
      for (final item in json! as List<Object?>)
        Project.fromJson(item! as Map<String, dynamic>),
    ],
  );

  @override
  Future<Project> create(Project item) => post(
    ProjectEndpoints.projects,
    body: item.toJson(),
    decode: (json) => Project.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<Project> retrieve(int id) => get(
    ProjectEndpoints.projectById,
    pathParams: {'id': id},
    decode: (json) => Project.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<Project> update(int id, Project item) => put(
    ProjectEndpoints.projectById,
    pathParams: {'id': id},
    body: item.toJson(),
    decode: (json) => Project.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<void> destroy(int id) =>
      delete(ProjectEndpoints.projectById, pathParams: {'id': id});
}
