import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/core/auth/auth_service.dart';
import 'package:ag_showcase_tasks/core/bindings/initial_binding.dart';
import 'package:ag_showcase_tasks/core/routes/app_pages.dart';
import 'package:ag_showcase_tasks/core/routes/app_routes.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';
import 'package:ag_showcase_tasks/main.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/project_details_controller.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/project_tasks_controller.dart';
import 'package:ag_showcase_tasks/modules/projects/controllers/projects_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/task_details_controller.dart';
import 'package:ag_showcase_tasks/modules/tasks/controllers/tasks_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves every request from memory — no network — with objects carrying
/// every field this app's models read, and records `METHOD path`.
class FakeApi implements ApiProvider {
  final List<String> calls = [];

  static Map<String, dynamic> item(int id) => {
    'id': id,
    'userId': 1,
    'postId': 1,
    'title': 'Item $id',
    'body': 'body',
    'name': 'name',
    'email': 'a@b.c',
    'completed': false,
    'category': 'tools',
    'description': 'd',
    'image': '',
    'price': 10,
    'rating': {'rate': 4, 'count': 1},
  };

  @override
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
    AgCancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final path = request.resolvePath();
    calls.add('${request.method.name} $path');
    final Object? json;
    if (request.method == AgHttpMethod.delete) {
      json = <String, dynamic>{};
    } else if (path.endsWith('/categories')) {
      json = ['tools', 'toys'];
    } else if (request.method == AgHttpMethod.post) {
      json = item(99); // a newly created resource gets a new id
    } else if (request.method != AgHttpMethod.get ||
        RegExp(r'/\d+$').hasMatch(path)) {
      json = item(1);
    } else {
      json = [for (var i = 1; i <= 3; i++) item(i)];
    }
    return AgResponse<D>(
      statusCode: 200,
      data: decode != null ? decode(json) : json as D,
      headers: const {},
      duration: Duration.zero,
    );
  }
}

void main() {
  testWidgets('guards, shell tabs, optimistic writes and details — offline', (
    tester,
  ) async {
    final api = FakeApi();
    InitialBinding().dependencies();
    AgLocator.put<ApiProvider>(api, permanent: true);

    await tester.pumpWidget(const TasksShowcaseApp());
    await tester.pumpAndSettle();

    // AuthGuard: a logged-out user can't reach a tab.
    RouteManagement.goToTasksPage();
    await tester.pumpAndSettle();
    expect(AppPages.router.state.uri.path, AppRoutes.login);
    expect(AgLocator.find<TasksController>, throwsStateError);

    final login = AuthService.instance.login(email: 'a@b.c', password: 'x');
    await tester.pump(const Duration(milliseconds: 700));
    await login;

    // GuestGuard: a logged-in user is sent away from /login.
    RouteManagement.goToLoginPage();
    await tester.pumpAndSettle();
    expect(AppPages.router.state.uri.path, isNot(AppRoutes.login));

    RouteManagement.goToTasksPage();
    await tester.pumpAndSettle();
    final tasks = AgLocator.find<TasksController>();
    expect(tasks.state.dataOrNull!, hasLength(3));
    await tasks.toggleCompleted(tasks.state.dataOrNull!.first);
    expect(tasks.state.dataOrNull!.first.completed, isTrue);

    RouteManagement.goToTaskDetailsPage(
      const TaskDetailsPageArgument(taskId: 1),
    );
    await tester.pumpAndSettle();
    final task = AgLocator.find<TaskDetailsController>();
    expect(task.lookupId, 1);
    await task.toggleCompleted();

    RouteManagement.goToProjectsPage();
    await tester.pumpAndSettle();
    expect(
      AgLocator.find<ProjectsController>().state.dataOrNull!,
      hasLength(3),
    );

    RouteManagement.goToProjectTasksPage(
      const ProjectTasksPageArgument(projectId: 1),
    );
    await tester.pumpAndSettle();
    // The demo filters todos to userId == projectId % 10 + 1 (2 here);
    // every fake todo has userId 1, so the page correctly shows "empty".
    expect(
      AgLocator.find<ProjectTasksController>().state,
      isA<AgPageEmpty<dynamic>>(),
    );
    RouteManagement.back<void>();
    await tester.pumpAndSettle();

    RouteManagement.goToProjectDetailsPage(
      const ProjectDetailsPageArgument(projectId: 2),
    );
    await tester.pumpAndSettle();
    await AgLocator.find<ProjectDetailsController>().destroy();
    await tester.pumpAndSettle();
    expect(
      AgLocator.find<ProjectDetailsController>,
      throwsStateError,
      reason: 'delete pops the page, which releases its binding',
    );

    expect(
      api.calls,
      containsAll(<String>['PUT /todos/1', 'GET /posts/2', 'DELETE /posts/2']),
    );
  });
}
