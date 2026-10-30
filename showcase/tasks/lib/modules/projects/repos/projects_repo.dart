import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/services/projects_service.dart';

/// Projects repo — plain delegation to [ProjectsService].
class ProjectsRepo extends AgBaseRepo {
  const ProjectsRepo(this._service);

  final ProjectsService _service;

  Future<List<Project>> list({int page = 1}) => _service.list(page: page);

  bool isLastPage(List<Project> items) => _service.pagination.isLastPage(items);

  Future<Project> create(Project item) => _service.create(item);

  Future<void> destroy(int id) => _service.destroy(id);
}
