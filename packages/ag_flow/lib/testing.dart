/// Test helpers for apps built on AG Flow: a fake [ApiProvider] and a
/// reset for AG's static registries.
///
/// Import it from tests only:
///
/// ```dart
/// import 'package:ag_flow/testing.dart';
/// ```
library;

import 'package:ag_flow/src/network/api_provider.dart';

export 'src/testing/ag_fake_api_provider.dart';
export 'src/testing/reset_ag_flow.dart';
