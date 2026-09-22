import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/repos/project_details_repo.dart';

class ProjectDetailsController
    extends AgDetailController<Project, ProjectDetailsPageArgument> {
  ProjectDetailsController(this._repo);

  static ProjectDetailsController get find =>
      AgLocator.find<ProjectDetailsController>();

  final ProjectDetailsRepo _repo;

  @override
  ProjectDetailsPageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => ProjectDetailsPageArgument.fromPathParameters(pathParameters);

  @override
  Future<Project> fetch() => _repo.getByArgument(arguments);

  Future<void> update(Project item) async {
    final saved = await _repo.update(arguments, item);
    emit(AgPageState.success(saved));
  }

  Future<void> delete() async {
    await _repo.delete(arguments);
    AgNavigator.back<void>();
  }
}
