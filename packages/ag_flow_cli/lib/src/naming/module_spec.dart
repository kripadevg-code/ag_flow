import 'package:ag_flow_cli/src/naming/case_convert.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:ag_flow_cli/src/naming/pluralizer.dart';
import 'package:meta/meta.dart';

/// Every name/path AG derives from a [ModulePath] — the CLI's single
/// source of truth for a module's route, route constant, class names, file
/// names, and component namespace.
///
/// Naming scheme (confirmed decision, see the build plan): class names are
/// **fully cumulative** — `product/details/reviews/comments` produces the
/// class prefix `ProductDetailsReviewsComments` (every non-root segment
/// concatenated), which is collision-safe: two branches sharing a leaf
/// segment name (`product/pricing/details` vs `product/shipping/details`)
/// can never collide in the shared flat `controllers/` folder the way a
/// root+leaf-only scheme could. Route paths/constants are always fully
/// cumulative regardless of depth. The component namespace is always the
/// bare last segment, never prefixed or cumulative.
///
/// A root module's five architectural-layer files/classes (page,
/// controller, repo, service, binding) are additionally **pluralized**
/// (`product` -> `Products`/`products_controller.dart`) — but its
/// components are not (requirments/ag_framework.md §5 shows
/// `components/product/product_card.dart`, not `products_card.dart`).
/// That's why this class exposes two distinct prefixes/file-bases rather
/// than one: [classPrefix]/[layerFileBase] for the five layers, and
/// [componentClassPrefix]/[fileBase] for components (and folder paths).
@immutable
class ModuleSpec {
  const ModuleSpec._({
    required this.modulePath,
    required this.routePath,
    required this.routeConstant,
    required this.classPrefix,
    required this.componentClassPrefix,
    required this.fileBase,
  });

  /// Derives a [ModuleSpec] from [modulePath]. [pluralizer] controls how a
  /// root module's layer class prefix is pluralized (`product` ->
  /// `Products`); only consulted when [ModulePath.isRoot] is true.
  factory ModuleSpec.from(
    ModulePath modulePath, {
    Pluralizer pluralizer = defaultPluralizer,
  }) {
    final segments = modulePath.segments;

    final routePath = '/${segments.join('/')}';
    final routeConstant =
        camelCase(segments.first) + segments.skip(1).map(pascalCase).join();
    final componentClassPrefix = segments.map(pascalCase).join();
    final classPrefix = modulePath.isRoot
        ? pluralizer(componentClassPrefix)
        : componentClassPrefix;
    final fileBase = segments.join('_');

    return ModuleSpec._(
      modulePath: modulePath,
      routePath: routePath,
      routeConstant: routeConstant,
      classPrefix: classPrefix,
      componentClassPrefix: componentClassPrefix,
      fileBase: fileBase,
    );
  }

  /// The module path this spec was derived from.
  final ModulePath modulePath;

  /// The route path, e.g. `/product/details/reviews`.
  final String routePath;

  /// The route constant name, e.g. `productDetailsReviews`.
  final String routeConstant;

  /// The cumulative class-name prefix used by the five architectural-layer
  /// classes (page/controller/repo/service/binding) — pluralized for a
  /// root module (`Products`), plain cumulative otherwise
  /// (`ProductDetailsReviews`).
  final String classPrefix;

  /// The cumulative class-name prefix used by components — **never**
  /// pluralized, even for a root module (`Product`, not `Products`).
  final String componentClassPrefix;

  /// The raw, never-pluralized snake_case join of every path segment
  /// (`product`, `product_details_reviews`). Used for component file
  /// names and for locating this module's root folder.
  final String fileBase;

  /// The snake_case file-name base for the five architectural-layer
  /// files — [classPrefix] converted back to snake_case, so it carries
  /// the same root-module pluralization (`products`, not `product`).
  String get layerFileBase => snakeCase(classPrefix);

  /// Whether this module is a detail/child module (anything below the
  /// root) rather than a root/collection module.
  bool get isDetail => !modulePath.isRoot;

  /// The bare last path segment — never prefixed or cumulative — used as
  /// this module's own component namespace directory name.
  String get componentNamespace => modulePath.lastSegment;

  String get pageClass => '${classPrefix}Page';
  String get controllerClass => '${classPrefix}Controller';
  String get repoClass => '${classPrefix}Repo';
  String get serviceClass => '${classPrefix}Service';
  String get bindingClass => '${classPrefix}Binding';

  /// Only meaningful for detail modules — see [isDetail].
  String get argumentClass => '${classPrefix}PageArgument';

  String get navMethod => 'goTo${classPrefix}Page';

  String get pageFile => '${layerFileBase}_page.dart';
  String get controllerFile => '${layerFileBase}_controller.dart';
  String get repoFile => '${layerFileBase}_repo.dart';
  String get serviceFile => '${layerFileBase}_service.dart';
  String get bindingFile => '${layerFileBase}_binding.dart';
}
