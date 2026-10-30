// This file exists to be called from tests, which is what the
// visible-for-testing members it calls are reserved for.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:ag_flow/src/di/ag_locator.dart';
import 'package:ag_flow/src/navigation/ag_binding.dart';
import 'package:ag_flow/src/navigation/ag_route_data.dart';

/// Clears everything AG Flow keeps between tests: every [AgLocator]
/// registration (disposing realized controllers), the live [AgBinding]
/// counts and the current [AgRouteData].
///
/// AG's registries are static, so without this one test's controllers
/// leak into the next. Call it from `setUp` (or `tearDown`):
///
/// ```dart
/// setUp(resetAgFlow);
/// ```
void resetAgFlow() {
  AgLocator.reset();
  AgBinding.resetLiveBindings();
  AgRouteData.reset();
}
