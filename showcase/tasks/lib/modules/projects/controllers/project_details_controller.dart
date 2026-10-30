import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/repos/project_details_repo.dart';

/// Detail controller for a single project: loads it, updates it, and
/// deletes it.
class ProjectDetailsController extends AgBaseController<Project> {
  ProjectDetailsController(this._repo)
    : argument = ProjectDetailsPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final ProjectDetailsRepo _repo;

  final ProjectDetailsPageArgument argument;

  static ProjectDetailsController get find =>
      AgLocator.find<ProjectDetailsController>();

  int get lookupId => argument.projectId;

  @override
  Future<Project> fetch() => _repo.retrieve(lookupId);

  Future<void> update(Project item) async {
    emit(AgPageState.success(await _repo.update(lookupId, item)));
  }

  /// Deletes the project, then leaves its now-empty page.
  Future<void> destroy() async {
    await _repo.destroy(lookupId);
    RouteManagement.back<void>();
  }
}
