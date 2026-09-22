import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/services/projects_service.dart';

class ProjectDetailsRepo extends AgBaseRepo {
  const ProjectDetailsRepo(this._service);
  final ProjectsService _service;

  Future<Project> getByArgument(ProjectDetailsPageArgument arg) =>
      _service.getById(arg.projectId);
  Future<Project> update(ProjectDetailsPageArgument arg, Project item) =>
      _service.update(arg.projectId, item);
  Future<void> delete(ProjectDetailsPageArgument arg) =>
      _service.delete(arg.projectId);
}
