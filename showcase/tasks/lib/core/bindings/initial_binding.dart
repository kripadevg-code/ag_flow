import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/auth/auth_service.dart';
import 'package:ag_showcase_tasks/modules/tasks/stores/tasks_store.dart';

/// App-wide singletons — registered once before the first frame and
/// never torn down.
///
/// Three permanent singletons live here:
///   1. [ApiProvider]  — the single Dio wrapper every Service uses.
///   2. [AuthService]  — reactive login-state holder read by every guard.
///   3. [TasksStore]   — the offline copy of tasks the tasks Repos fall back to.
///
/// Everything else (controllers, repos, services) is registered per-route
/// by its own [AgBinding] so it is created only when the route is entered
/// and disposed when it is left.
class InitialBinding extends AgBinding {
  @override
  void dependencies() {
    put<ApiProvider>(
      ApiProvider(baseUrl: 'https://jsonplaceholder.typicode.com'),
      permanent: true,
    );

    // AuthService must be permanent so guards can resolve it before any
    // route has pushed its own binding.
    put<AuthService>(AuthService(), permanent: true);

    // The offline copy of tasks must outlive the tasks routes, or leaving
    // the tab would throw it away.
    put<TasksStore>(TasksStore(), permanent: true);
  }
}
