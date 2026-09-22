/// Marks a controller or service class for static-accessor generation.
///
/// Place this annotation on any class that extends [AgBaseController],
/// [AgListController], [AgDetailController], [AgBaseService], or
/// [AgStateService].
/// The `ag_flow_generator` build-runner package will generate a
/// companion `part` file that mixes in a static getter so the class
/// can be resolved from [AgLocator] without any generic syntax.
///
/// **Controllers** — get a `find` static getter:
///
/// ```dart
/// part 'login_controller.g.dart';
///
/// @AgInject()
/// class LoginController extends AgBaseController<User> {
///   LoginController(this._repo);
///   final LoginRepo _repo;
///   // ...
/// }
/// ```
///
/// Resolving it anywhere in the app:
///
/// ```dart
/// final controller = LoginController.find;
/// ```
///
/// **Services** — get an `instance` static getter:
///
/// ```dart
/// part 'auth_service.g.dart';
///
/// @AgInject()
/// class AuthService extends AgBaseService {
///   AuthService(super.apiProvider);
///   // ...
/// }
/// ```
///
/// Resolving it anywhere in the app:
///
/// ```dart
/// final service = AuthService.instance;
/// ```
///
/// The correct getter name (`find` vs `instance`) is determined
/// automatically by `ag_flow_generator` based on which ag_flow base
/// class the annotated class extends — you never have to specify it.
///
/// See `ag_flow_generator` for setup instructions (`build_runner` and
/// `pubspec.yaml` wiring).
class AgInject {
  const AgInject();
}
