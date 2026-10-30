import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/services/projects_service.dart';

/// Project details repo: reads, updates and deletes the project the
/// details page shows, over the module's shared [ProjectsService].
class ProjectDetailsRepo extends AgBaseRepo {
  const ProjectDetailsRepo(this._service);

  final ProjectsService _service;

  Future<Project> retrieve(int id) => _service.retrieve(id);

  Future<Project> update(int id, Project item) => _service.update(id, item);

  Future<void> destroy(int id) => _service.destroy(id);
}
