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
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  static final List<AgRoute> pages = [];
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
class InitialBinding extends AgBinding {
  @override
  void dependencies() {
    put<ApiProvider>(
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

/// The architecture standard every developer and AI agent working in a
/// generated project follows. Written to the project root so a coding
/// agent picks it up automatically — `AGENTS.md` is the cross-tool
/// convention, and `CLAUDE.md` points at it rather than duplicating it.
///
/// This is the whole point of `ag init` writing more than code: an agent
/// that knows the standard uses `ag g m` instead of inventing a module
/// layout, which is both more consistent and dramatically cheaper.
const _agentsSkeleton = '''
# AG Flow — architecture standard

This project is built on **AG Flow**. Its architecture is fixed and the
generator owns the boilerplate. Follow this document exactly; `ag analyze`
enforces it and CI fails on any violation.

## Generate, don't hand-write

```bash
ag g m <path>                            # collection module
ag g m <path> --from-json=sample.json    # ... typed from a real API response
ag g m <parent>/<child>                  # detail module
ag analyze                               # verify the project still conforms
```

One command writes the page, controller, repo, service, binding and
components, **and** registers the route, argument class and navigation
method. Hand-writing that is slower, costs far more tokens, and fails
`ag analyze`. Paste a real API response into `--from-json` and the model is
generated and threaded through every layer, so nothing is typed `dynamic`.

## The layer contract

```
Page → Controller → Repo → Service → ApiProvider
```

Each layer talks only to the next. Never skip one, never reach backwards.

| Layer | Base class | Responsibility |
|---|---|---|
| Page | `AgBasePage<C>` | Rendering only. No business logic, no Repo/Service access. |
| Controller | `AgBaseController` / `AgListController` / `AgDetailController` | Page state. Calls **only** its Repo. |
| Repo | `AgBaseRepo` | Calls **only** its Service. |
| Service | `AgBaseService` | **Declarative.** Declares endpoints, `AgPageStrategy`, `AgEnvelope`. |
| Network | `ApiProvider` | The only thing that touches HTTP. |

A Service contains **no request plumbing** — no query-param building, no
manual decoding, no `hasMore` arithmetic. Everything that differs between
backends is a value it declares. Use `AgCrudService` / `AgPagedService`, or
`fetchList`/`fetchItem` for feature-specific reads.

## Folder structure

```
lib/
  core/                 arguments, endpoints, routes, bindings   (ag init owns)
  modules/
    <module>/
      bindings/ components/ controllers/ models/ pages/ repos/ services/
```

Layer folders are **flat per root module**. A child module's files live in
the root module's folders (`modules/product/controllers/product_details_controller.dart`).
Never nest a module inside another module's folder. Never add new top-level
folders.

## State

Use `AgPageState` — `initial` / `loading` / `success` / `empty` / `error`.
Never ad-hoc `isLoading` / `errorMessage` fields. `emit()` is the only write
path. For lists, implement `fetchPage` and let `AgPaginationMixin` own
load-more; pagination state is deliberately separate from page state.

## Routing

Routes live in `core/routes/` and the CLI maintains them. Navigate via
`RouteManagement.goToXPage(...)`. A detail route carries its id in the path
(`/product/details/:id`) so the page is deep-linkable.

## You MUST NOT

- hand-write a module's layer files instead of running `ag g m`
- put request plumbing (query params, decoding, paging maths) in a Service
- call a Service from a Controller, or a Repo from a Page
- import `dio` or `package:http` anywhere in feature code
- add `isLoading` / `hasError` booleans to a controller
- call `AgNavigator.toNamed('/literal')` outside `route_management.dart`
- create folders outside the structure above
- hand-edit `core/routes/*` for a generated module

## Before you finish

```bash
ag analyze && dart format . && flutter analyze && flutter test
```

CI runs the same checks. Non-conforming code does not merge.
''';

const _claudeSkeleton = '''
# Project instructions

This project follows the **AG Flow** architecture standard.

**Read [AGENTS.md](AGENTS.md) and follow it exactly.** It defines the layer
contract, the folder structure, the generator commands to use instead of
writing files by hand, and the things you must not do. `ag analyze` enforces
it and CI fails on any violation.
''';

/// The gate. Instructions are advisory; a red build is not.
const _ciWorkflowSkeleton = '''
name: ag

on:
  push:
  pull_request:

jobs:
  standards:
    name: Architecture + analysis + tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get

      # The architecture gate. Fails (exit 70) on any structural
      # violation: a missing layer file, a module wired by hand, a
      # dependency pointing the wrong way, a hard-coded route string.
      # Requires ag_flow_cli in dev_dependencies.
      - name: ag analyze
        run: dart run ag_flow_cli:ag analyze

      - name: Formatting
        run: dart format --output=none --set-exit-if-changed lib test

      - name: Static analysis
        run: flutter analyze --fatal-infos

      - name: Tests
        run: flutter test
''';

/// Opt-in local gate, so a violation is caught before CI.
/// Version-controlled under `.githooks/` — `.git/hooks` is not.
const _preCommitHookSkeleton = r'''
#!/bin/sh
# AG Flow architecture gate.
#
# Enable once per clone:
#   git config core.hooksPath .githooks
#
# Skip a single commit if you genuinely need to: git commit --no-verify
set -e

if ! command -v dart >/dev/null 2>&1; then
  echo "AG: dart not on PATH - skipping architecture check."
  exit 0
fi

# The project's own dev_dependency wins over anything on PATH: it is
# version-matched to this project, whereas a global `ag` may be a
# different version - or, since the name is short, a different tool
# entirely.
if dart run ag_flow_cli:ag --version >/dev/null 2>&1; then
  AG_CMD="dart run ag_flow_cli:ag"
elif command -v ag >/dev/null 2>&1; then
  AG_CMD="ag"
else
  # A missing tool is not an architecture violation - say so plainly
  # rather than blocking a commit with a misleading message. CI is the
  # authoritative gate; this hook is the fast local feedback loop.
  echo "AG: ag_flow_cli not available - skipping architecture check."
  echo "    Enable it by adding ag_flow_cli to dev_dependencies."
  exit 0
fi

echo "AG: checking architecture..."
if ! $AG_CMD analyze; then
  echo ""
  echo "AG: architecture violation - commit blocked."
  echo "    See AGENTS.md for the standard, or run 'ag analyze' for detail."
  exit 1
fi
''';

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
      _planAtRoot('AGENTS.md', _agentsSkeleton),
      _planAtRoot('CLAUDE.md', _claudeSkeleton),
      _planAtRoot(
        p.join('.github', 'workflows', 'ag.yaml'),
        _ciWorkflowSkeleton,
      ),
      _planAtRoot(
        p.join('.githooks', 'pre-commit'),
        _preCommitHookSkeleton,
        executable: true,
      ),
    ];
  }

  /// Plans a file at the *project root* rather than under `lib/` — the
  /// agent-facing standard, the CI workflow and the git hook all belong
  /// there, not in the Dart source tree.
  FileOp _planAtRoot(
    String relativePath,
    String content, {
    bool executable = false,
  }) {
    final path = p.join(project.root.path, relativePath);
    if (File(path).existsSync()) return FileOp.skipExisting(path: path);
    return FileOp.create(path: path, content: content, executable: executable);
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
