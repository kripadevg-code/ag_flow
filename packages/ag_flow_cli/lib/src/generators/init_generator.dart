import 'dart:io';

import 'package:ag_flow_cli/src/io/file_op.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

const _argumentsSkeleton = '''
// The single application-level file for every navigation argument class
// (see requirments/routes.md §3). `ag g m` maintains this automatically
// for detail/child modules — there must never be more than one of this
// file in the application.
''';

const _endpointsSkeleton = '''
// The single application-level file for reusable API endpoint
// definitions, grouped by backend domain — not by frontend module
// hierarchy (see requirments/ag_endpoint_rules.md §2, §5). Not maintained
// automatically by `ag g m` — add your own endpoint classes here, e.g.:
//
// abstract class ProductEndpoints {
//   static const products = AgEndpoint('/products');
//   static const productById = AgEndpoint('/products/{id}');
// }
''';

const _appRoutesSkeleton = '''
abstract class AppRoutes {
  static const String initial = _Routes.initial;
}

abstract class _Routes {
  static const String initial = '/';
}
''';

const _appPagesSkeleton = '''
import 'package:ag_flow/ag_flow.dart';

import 'app_routes.dart';

abstract class AppPages {
  static const Transition defaultTransition = Transition.rightToLeft;

  static final List<GetPage<dynamic>> pages = [];
}
''';

const _routeManagementSkeleton = '''
import 'package:ag_flow/ag_flow.dart';

import 'app_routes.dart';

abstract class RouteManagement {}
''';

const _initialBindingSkeleton = '''
import 'package:ag_flow/ag_flow.dart';

/// Registers the single, shared [ApiProvider] used by every Service in
/// the app (see requirments/ag_endpoint_rules.md §22).
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiProvider>(
      // TODO: set your API's real base URL.
      ApiProvider(baseUrl: 'https://example.com'),
      permanent: true,
    );
  }
}
''';

/// Bootstraps a project for AG: creates the `core/` skeleton (see
/// requirments/routes.md §2) if it doesn't already exist.
///
/// Idempotent by construction — each file is only ever created if
/// missing; an existing file (including one a developer has already
/// started customizing) is never overwritten.
class InitGenerator {
  const InitGenerator({required this.project});

  final Project project;

  static final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  List<FileOp> plan() {
    return [
      _planOne(
        p.join('core', 'arguments', 'arguments.dart'),
        _argumentsSkeleton,
        format: false,
      ),
      _planOne(
        p.join('core', 'endpoints.dart'),
        _endpointsSkeleton,
        format: false,
      ),
      _planOne(p.join('core', 'routes', 'app_routes.dart'), _appRoutesSkeleton),
      _planOne(p.join('core', 'routes', 'app_pages.dart'), _appPagesSkeleton),
      _planOne(
        p.join('core', 'routes', 'route_management.dart'),
        _routeManagementSkeleton,
      ),
      _planOne(
        p.join('core', 'bindings', 'initial_binding.dart'),
        _initialBindingSkeleton,
      ),
    ];
  }

  FileOp _planOne(String relativePath, String content, {bool format = true}) {
    final path = p.join(project.libDir.path, relativePath);
    if (File(path).existsSync()) return FileOp.skipExisting(path: path);
    return FileOp.create(
      path: path,
      content: format ? _formatter.format(content) : content,
    );
  }
}
