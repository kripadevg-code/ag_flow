import 'package:pluralize/pluralize.dart';

/// Pluralizes a root module's name for its class prefix (`product` ->
/// `Product` -> `Products`).
///
/// A plain function type rather than a one-method interface — this keeps
/// [defaultPluralizer] swappable (the underlying `pluralize` package is
/// small and slow-moving, and irregular plurals occasionally need a
/// project-specific override via `--plural=`) without the ceremony of a
/// single-method abstract class.
typedef Pluralizer = String Function(String word);

final Pluralize _pluralize = Pluralize();

/// The default [Pluralizer], backed by the `pluralize` package.
String defaultPluralizer(String word) => _pluralize.plural(word);
