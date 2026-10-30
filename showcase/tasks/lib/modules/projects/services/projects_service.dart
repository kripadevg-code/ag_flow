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
  Future<List<Project>> list({int page = 1}) async {
    final response = await send<List<Project>>(
      AgRequest(
        endpoint: ProjectEndpoints.projects,
        queryParams: pagination.query(page),
      ),
      decode: (json) => [
        for (final item in json! as List<Object?>)
          Project.fromJson(item! as Map<String, dynamic>),
      ],
    );
    return response.data;
  }

  @override
  Future<Project> create(Project item) async {
    final response = await send<Project>(
      AgRequest(
        endpoint: ProjectEndpoints.projects,
        method: AgHttpMethod.post,
        body: item.toJson(),
      ),
      decode: (json) => Project.fromJson(json! as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<Project> retrieve(int id) async {
    final response = await send<Project>(
      AgRequest(endpoint: ProjectEndpoints.projectById, pathParams: {'id': id}),
      decode: (json) => Project.fromJson(json! as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<Project> update(int id, Project item) async {
    final response = await send<Project>(
      AgRequest(
        endpoint: ProjectEndpoints.projectById,
        method: AgHttpMethod.put,
        pathParams: {'id': id},
        body: item.toJson(),
      ),
      decode: (json) => Project.fromJson(json! as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<void> destroy(int id) async {
    await send<void>(
      AgRequest(
        endpoint: ProjectEndpoints.projectById,
        method: AgHttpMethod.delete,
        pathParams: {'id': id},
      ),
    );
  }
}
