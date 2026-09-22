# AG Flow

[![pub.dev](https://img.shields.io/pub/v/ag_flow.svg)](https://pub.dev/packages/ag_flow)
[![CI](https://github.com/kripadevg-code/ag_flow/actions/workflows/ci.yaml/badge.svg)](https://github.com/kripadevg-code/ag_flow/actions/workflows/ci.yaml)
[![Generator Integration](https://github.com/kripadevg-code/ag_flow/actions/workflows/generator-integration.yaml/badge.svg)](https://github.com/kripadevg-code/ag_flow/actions/workflows/generator-integration.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**An opinionated Flutter framework and CLI — zero third-party state-management dependency — that turns "write a new feature module" into a single command.**

State and DI are AG's own primitives. Routing is AG's clean API over
[`go_router`](https://pub.dev/packages/go_router) — the Flutter team's own
package — so every route is a real URL and every detail page is deep-linkable
without go_router ever appearing in your pubspec or your generated code.

AG Flow standardises the shape of every feature module
(page → controller → repo → service → binding), the routing and
navigation-argument wiring, and page-state handling
(loading / error / empty / refresh / retry) so you spend time on business
logic and UI instead of rebuilding the same infrastructure for every screen.

Built for developers who want structure without ceremony.
Open-source, free to use, adopt, and adapt.

![ag init, ag g m, and ag analyze generating and validating a module end-to-end](docs/demo.gif)

---

## Why AG Flow

- **One command per module.** `ag g m product` generates a fully-wired
  page / controller / repo / service / binding / component set — routing,
  DI, and navigation arguments included — in one shot.
  `ag g m product/details` nests to any depth from there.
- **A structure you can enforce, not just suggest.** `ag analyze` checks a
  real project against the architecture — missing layer files, routes with no
  navigation wiring, a Page reaching straight past its Controller into a
  Service, a detail route whose argument is generated but never read — the
  same rules the generator itself follows, so drift gets caught instead of
  accumulating.
- **Independent overrides, not all-or-nothing templates.** Override only the
  error state, or only the loading state — every other AG default stays
  exactly as generated.
- **One networking chokepoint.** Every generated Service goes through a
  single, centrally-configured `ApiProvider` — no per-feature Dio instances,
  no hand-rolled URLs, no scattered auth/retry/logging logic.
- **Regeneration never clobbers your work.** Re-running `ag g m` on an
  existing module is a no-op; a hand-customised navigation method survives
  regeneration byte-for-byte, forever.
- **Deep links out of the box.** Routes are real URL paths, so every detail
  page opens correctly from a push notification, a shared link, or a
  browser reload — not only from an in-app tap.

---

## Packages

This is a [Melos](https://melos.invertase.dev/) monorepo built on native
Dart pub workspaces.

| Package | pub.dev | Purpose |
|---|---|---|
| [`ag_flow`](packages/ag_flow) | [![pub.dev](https://img.shields.io/pub/v/ag_flow.svg)](https://pub.dev/packages/ag_flow) | Runtime framework: `AgBasePage`, `AgBaseController`, `AgListBuilder`, `AgBaseRepo`, `AgBaseService`, `ApiProvider`, routing, DI, and everything every generated module is built from. |
| [`ag_flow_cli`](packages/ag_flow_cli) | [![pub.dev](https://img.shields.io/pub/v/ag_flow_cli.svg)](https://pub.dev/packages/ag_flow_cli) | The `ag` CLI. `ag init` bootstraps `lib/core/`; `ag g m <module>` generates a complete module and wires it in idempotently; `ag analyze` validates the whole project against AG's structural rules. |
| [`ag_flow_generator`](packages/ag_flow_generator) | [![pub.dev](https://img.shields.io/pub/v/ag_flow_generator.svg)](https://pub.dev/packages/ag_flow_generator) | Optional `build_runner` companion — auto-generates static `find` / `instance` accessors on controllers and services from the `@AgInject()` annotation. |

---

## Installing

Add `ag_flow` to your app's `pubspec.yaml`:

```yaml
dependencies:
  ag_flow: ^0.1.0
```

Activate the CLI globally (one-time per machine):

```bash
dart pub global activate ag_flow_cli
```

Or add it as a dev dependency and run it via `dart run`:

```yaml
dev_dependencies:
  ag_flow_cli: ^0.1.0
```

### Optional: auto-generated accessors

If you want `LoginController.find` and `AuthService.instance` without
writing a one-liner per class, add the generator:

```yaml
dev_dependencies:
  ag_flow_generator: ^0.1.0
  build_runner: ^2.4.0
```

Then annotate your classes and run `build_runner`:

```dart
@AgInject()
class LoginController extends AgBaseController<User> with _$LoginControllerAgInject {
  // LoginController.find is generated — never write it by hand.
}
```

```bash
dart run build_runner build
```

---

## Quickstart

```bash
# 1 — Bootstrap lib/core/ once per project
ag init

# 2 — Generate a paginated list + detail module pair
ag g m product
ag g m product/details

# 3 — Validate the project structure
ag analyze

# 4 — Build as normal
flutter run
```

Every generated file is plain Dart — no reflection, no codegen required at
runtime. `ag analyze` re-validates any time the project grows.

---

## Architecture at a glance

```
AgApp (root)
  └─ AgRoute (named URL path)
       └─ AgBinding (DI scope, route-lifetime)
            └─ AgBasePage / AgListBuilder (UI, state rendering)
                 └─ AgBaseController (page state machine)
                      └─ AgBaseRepo (data access boundary)
                           └─ AgBaseService / AgCrudService / AgPagedService
                                └─ ApiProvider (single Dio instance)
```

Each layer has exactly one job. Nothing skips a layer — the generator
enforces this and `ag analyze` catches it if you drift.

### Page state — three overrides, all optional

```dart
class ProductsPage extends AgBasePage<ProductsController> {
  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Product, int>(
      controller: controller,
      itemBuilder: (context, item, index) => ProductItem(item: item),
    );
  }

  // Only override what you need — AG provides defaults for the rest.
  @override
  WidgetBuilder? get loadingBuilder => (context) => const MyLoadingSpinner();
}
```

### Service — declare values, not code

```dart
class ProductsService extends AgBaseService
    with AgCrudService<Product, int>, AgPagedService<Product, int> {
  ProductsService(super.apiProvider);

  @override AgEndpoint get collectionEndpoint => ProductEndpoints.products;
  @override AgEndpoint get resourceEndpoint   => ProductEndpoints.productById;
  @override AgPageStrategy<int> get pageStrategy =>
      const AgPageNumberStrategy(pageParam: 'page', sizeParam: 'limit', pageSize: 20);
  @override Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);
  @override Map<String, dynamic> toJson(Product item)   => item.toJson();
}
```

### Guards — route-level access control

```dart
class AuthGuard extends AgGuard {
  const AuthGuard();

  @override
  String? redirect(String path) {
    final authService = AuthService.instance;
    return authService.isLoggedIn ? null : AppRoutes.login;
  }
}

// In AppPages:
AgRoute(
  path: AppRoutes.home,
  page: HomePage.new,
  guards: [const AuthGuard()],
)
```

---

## Showcase apps

Three real, running apps in this repo — each built entirely with the CLI,
against a live public API, showing a different slice of the framework:

| App | What it demonstrates |
|---|---|
| [`showcase/blog`](showcase/blog) | Paginated collection, detail with edit/delete, nested comments module — `AgPagedService`, `AgCrudService`, `AgListBuilder`, path-parameter deep links |
| [`showcase/store`](showcase/store) | Category-filtered products, full CRUD, `AgRetryPolicy` — `AgCrudService` wired to collection + resource endpoints |
| [`showcase/tasks`](showcase/tasks) | Auth guard, shell route with bottom nav, `AgStateService`, `AgShellRoute`, optimistic list mutations — a complete architecture reference for a company-grade app |

---

## Working in this repo

```bash
dart pub global activate melos   # once per machine
melos bootstrap                  # resolves the whole workspace
melos run format-check
melos run analyze
melos run check-bundles-fresh
melos run test
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full contributor workflow
including how to cut a release.
