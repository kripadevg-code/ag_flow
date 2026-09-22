import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/modules/profile/controllers/profile_controller.dart';

class ProfileBinding extends AgBinding {
  @override
  void dependencies() {
    // ProfileController only reads from AuthService (permanent singleton)
    // — no network service needed.
    lazyPut(ProfileController.new);
  }
}
