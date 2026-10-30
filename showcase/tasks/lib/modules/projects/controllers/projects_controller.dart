import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/repos/projects_repo.dart';

/// Paginated projects list controller.
///
/// Loading and refresh come from [AgBaseController], paging from
/// [AgLoadMore]. jsonplaceholder doesn't persist writes, so a refresh
/// would undo them; each write reflects the mutation in the shown list
/// instead, as [TasksController] does.
class ProjectsController extends AgBaseController<List<Project>> with AgLoadMore<Project> {
  ProjectsController(this._repo);

  final ProjectsRepo _repo;

  static ProjectsController get find => AgLocator.find<ProjectsController>();

  @override
  Future<List<Project>> list({int page = 1}) => _repo.list(page: page);

  @override
  bool isLastPage(List<Project> items) => _repo.isLastPage(items);

  Future<void> create(Project item) async {
    final created = await _repo.create(item);
    emit(AgPageState.success([created, ...?state.dataOrNull]));
  }

  Future<void> destroy(int id) async {
    await _repo.destroy(id);
    final shown = state.dataOrNull ?? const <Project>[];
    emit(AgPageState.success(shown.where((p) => p.id != id).toList()));
  }
}
