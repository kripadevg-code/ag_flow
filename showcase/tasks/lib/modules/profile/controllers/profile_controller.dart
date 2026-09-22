import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/auth/auth_service.dart';
import 'package:ag_showcase_tasks/core/routes/route_management.dart';

/// Profile controller — reads from [AuthService] and handles sign-out.
///
/// Demonstrates [AgBaseController] used for a screen that has no async
/// data to load — just synchronous state from a permanent service.
class ProfileController extends AgBaseController<void> {
  static ProfileController get find => AgLocator.find<ProfileController>();

  @override
  bool get autoLoadOnInit => false;

  String get displayName => AuthService.instance.displayName;
  int get userId => AuthService.instance.userId;

  @override
  Future<void> fetch() async {}

  void signOut() {
    AuthService.instance.logout();
    RouteManagement.goToLoginPage();
  }
}
