import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Runs every test in this package under Flutter's leak tracker: a
/// `ChangeNotifier` (every controller) that is never disposed, or is disposed
/// but still referenced, fails the test that created it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withTrackedAll();
  await testMain();
}
