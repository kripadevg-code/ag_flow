import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/endpoints.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';

class ProjectsService extends AgBaseService
    with AgCrudService<Project, int>, AgPagedService<Project, int> {
  ProjectsService(super.apiProvider);

  static ProjectsService get instance => AgLocator.find<ProjectsService>();

  @override
  AgEndpoint get collectionEndpoint => ProjectEndpoints.projects;

  @override
  AgEndpoint get resourceEndpoint => ProjectEndpoints.projectById;

  @override
  AgPageStrategy<int> get pageStrategy => const AgPageNumberStrategy(
    pageParam: '_page',
    sizeParam: '_limit',
    pageSize: 10,
  );

  @override
  Project fromJson(Map<String, dynamic> json) => Project.fromJson(json);

  @override
  Map<String, dynamic> toJson(Project item) => item.toJson();
}
