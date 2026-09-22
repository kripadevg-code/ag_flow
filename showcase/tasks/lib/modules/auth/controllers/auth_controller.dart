import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/auth/auth_service.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';

/// Handles the async work for login and registration flows.
///
/// Extends [AgBaseController] with a nullable String payload used to
/// carry error messages — null means no error. The page reacts to state
/// changes via the normal AgPage/AgBuilder mechanism.
class AuthController extends AgBaseController<void> {
  static AuthController get find => AgLocator.find<AuthController>();

  @override
  // Auth screens load instantly — no initial fetch needed.
  bool get autoLoadOnInit => false;

  // Suppress the default AgBasePage scaffold — auth pages own their layout.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  @override
  Future<void> fetch() async {}

  Future<void> login({required String email, required String password}) async {
    _errorMessage = null;
    emit(AgPageState.loading());
    try {
      await AuthService.instance.login(email: email, password: password);
      RouteManagement.goToTasksPage();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AgPageState.success(null));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    emit(AgPageState.loading());
    try {
      await AuthService.instance.register(
        name: name,
        email: email,
        password: password,
      );
      RouteManagement.goToTasksPage();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AgPageState.success(null));
    }
  }
}
