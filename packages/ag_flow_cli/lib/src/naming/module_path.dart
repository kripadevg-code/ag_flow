import 'package:ag_flow_cli/src/naming/case_convert.dart';
import 'package:meta/meta.dart';

/// A parsed, validated module path such as `product/details/reviews`.
///
/// The module path is the source of truth for naming, hierarchy, and
/// component-namespace derivation (requirments/ag_framework.md §3).
@immutable
class ModulePath {
  const ModulePath._(this.segments);

  /// Parses and validates [rawPath]. Throws [FormatException] if any
  /// segment isn't valid lowercase snake_case (see
  /// requirments/ag_framework.md §10), or if there are no segments at all.
  factory ModulePath.parse(String rawPath) {
    final segments = rawPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      throw const FormatException('Module path must not be empty.');
    }
    for (final segment in segments) {
      if (!validModuleSegment.hasMatch(segment)) {
        throw FormatException(
          'Invalid module segment "$segment" — module names must be '
          'lowercase snake_case (letters, digits, underscores), starting '
          'with a letter.',
        );
      }
    }
    return ModulePath._(segments);
  }

  /// The path's segments, in order — e.g. `[product, details, reviews]`.
  final List<String> segments;

  /// 0 for a root module, 1 for its direct children, and so on.
  int get depth => segments.length - 1;

  /// Whether this is a root (collection-shaped) module.
  bool get isRoot => depth == 0;

  /// The first segment — every non-root module's classes are prefixed
  /// starting from this segment (the cumulative naming scheme).
  String get rootSegment => segments.first;

  /// The last segment — used bare (never prefixed) as the component
  /// namespace (requirments/ag_framework.md §7/§37).
  String get lastSegment => segments.last;

  /// This module's parent path, or null if this is a root module.
  ModulePath? get parent {
    if (isRoot) return null;
    return ModulePath._(segments.sublist(0, segments.length - 1));
  }

  /// The path as originally written, e.g. `product/details/reviews`.
  String get asString => segments.join('/');

  @override
  String toString() => asString;

  @override
  bool operator ==(Object other) =>
      other is ModulePath &&
      other.segments.length == segments.length &&
      other.asString == asString;

  @override
  int get hashCode => asString.hashCode;
}
