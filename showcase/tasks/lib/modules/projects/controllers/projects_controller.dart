import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/projects/models/project.dart';
import 'package:ag_showcase_tasks/modules/projects/repos/projects_repo.dart';

class ProjectsController extends AgListController<Project, int> {
  ProjectsController(this._repo) : super(initialPageKey: 1);

  static ProjectsController get find => AgLocator.find<ProjectsController>();

  final ProjectsRepo _repo;

  @override
  Future<AgListPage<Project, int>> fetchPage(int page) => _repo.getPage(page);

  Future<void> add(Project item) async {
    final created = await _repo.add(item);
    updateItems((items) => [created, ...items]);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    updateItems((items) => items.where((p) => p.id != id).toList());
  }
}
