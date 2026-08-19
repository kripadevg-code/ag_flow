import 'package:ag_flow/src/arguments/ag_arguments.dart';
import 'package:ag_flow/src/controller/ag_base_controller.dart';

/// Base class for detail modules: an [AgBaseController] that also resolves
/// its typed navigation argument [A].
///
/// [arguments] is resolved lazily (on first access, matching the point in
/// the lifecycle where `Get.arguments` is guaranteed to already be set)
/// and safely — a missing or mistyped navigation argument throws a named
/// [AgArgumentError] instead of an unhandled cast failure.
///
/// A single type parameter list (`T`, `A`) here is what lets `AgBasePage`
/// stay a one-type-parameter class for both collection and detail
/// modules — see `AgBasePage`.
abstract class AgDetailController<T, A extends Object>
    extends AgBaseController<T> {
  AgDetailController({super.autoLoadOnInit});

  /// The navigation argument this controller's page was opened with.
  late final A arguments = AgArguments.resolve<A>();
}
