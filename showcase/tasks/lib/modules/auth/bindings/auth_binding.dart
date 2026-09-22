import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/auth/controllers/auth_controller.dart';

class AuthBinding extends AgBinding {
  @override
  void dependencies() {
    // AuthService is already permanent in InitialBinding — the controller
    // just reads from it, so the binding only registers the controller.
    lazyPut(() => AuthController());
  }
}
