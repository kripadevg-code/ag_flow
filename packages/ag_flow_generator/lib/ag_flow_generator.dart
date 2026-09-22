/// ag_flow_generator — build_runner code generator for the ag_flow framework.
///
/// Exports the [agInjectBuilder] factory that build.yaml references, and
/// re-exports [AgInjectGenerator] for use in custom build scripts.
library;

import 'package:ag_flow_generator/src/ag_inject_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

export 'package:ag_flow_generator/src/ag_inject_generator.dart';

/// The builder factory referenced by `build.yaml`.
///
/// Uses [SharedPartBuilder] — the standard source_gen pattern for
/// generators that emit `part of` output.  Multiple generators can share
/// one `.g.dart` file per source file this way (the same approach
/// `json_serializable`, `freezed`, and `injectable` all use).
Builder agInjectBuilder(BuilderOptions options) =>
    SharedPartBuilder([AgInjectGenerator()], 'ag_inject');
