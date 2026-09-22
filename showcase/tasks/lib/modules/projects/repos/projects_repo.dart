import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/services/projects_service.dart';

class ProjectsRepo extends AgBaseRepo {
  const ProjectsRepo(this._service);
  final ProjectsService _service;

  Future<AgListPage<Project, int>> getPage(int page) =>
      _service.getPage(page);
  Future<Project> add(Project item) => _service.add(item);
  Future<void> delete(int id) => _service.delete(id);
}
