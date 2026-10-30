# AG Flow

[![pub.dev](https://img.shields.io/pub/v/ag_flow.svg)](https://pub.dev/packages/ag_flow)
[![CI](https://github.com/kripadevg-code/ag_flow/actions/workflows/ci.yaml/badge.svg)](https://github.com/kripadevg-code/ag_flow/actions/workflows/ci.yaml)
[![Generator Integration](https://github.com/kripadevg-code/ag_flow/actions/workflows/generator-integration.yaml/badge.svg)](https://github.com/kripadevg-code/ag_flow/actions/workflows/generator-integration.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**An opinionated Flutter framework and CLI for large apps — Django REST Framework's declarative style, brought to Flutter — that turns "write a new feature module" into a single command.**

Every module has the same shape, and its Service declares the backend
actions it supports with one typed mixin each (`AgCreateMixin`,
`AgDestroyMixin`, ...), the way DRF composes `CreateModelMixin` into a view. State and DI are AG's own
primitives, with no third-party state-management dependency. Routing is
your app's own [`go_router`](https://pub.dev/packages/go_router) — AG adds
one page class that scopes each module's dependencies to its route — and the
network layer is an interface you can swap.

**→ Start with the [developer guide](packages/ag_flow/doc/guide.md).**

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

- **Simple, like DRF.** A Service lists the actions its backend supports —
  `with AgCreateMixin<Product>, AgDestroyMixin<int>` — and implements each
  one, so an unusual backend never fights a built-in default. The Repo and
  Controller are plain classes, one of each per module.
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
- **One networking chokepoint, swappable.** Every Service goes through a
  single `ApiProvider` — dio-backed by default, or any client you plug in
  behind its one-method interface (http, GraphQL, an offline queue, a test
  fake). No per-feature Dio instances, no hand-rolled URLs.
- **Offline and caching have a home.** The Repo owns where data comes
  from: override a mixed-in method, call `super`, add your cache. Nothing
  above it changes.
- **Your router, not ours.** Routing is plain go_router in your app, at
  the version you choose; the CLI writes each route for you.
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
| [`ag_flow`](packages/ag_flow) | [![pub.dev](https://img.shields.io/pub/v/ag_flow.svg)](https://pub.dev/packages/ag_flow) | Runtime framework: `AgBasePage`, `AgBaseController`, `AgListView`, `AgBaseRepo`, `AgBaseService`, `ApiProvider`, routing, DI, and everything every generated module is built from. |
| [`ag_flow_cli`](packages/ag_flow_cli) | [![pub.dev](https://img.shields.io/pub/v/ag_flow_cli.svg)](https://pub.dev/packages/ag_flow_cli) | The `ag` CLI. `ag init` bootstraps `lib/core/`; `ag g m <module>` generates a complete module and wires it in idempotently; `ag analyze` validates the whole project against AG's structural rules. |
| [`ag_flow_generator`](packages/ag_flow_generator) | [![pub.dev](https://img.shields.io/pub/v/ag_flow_generator.svg)](https://pub.dev/packages/ag_flow_generator) | Optional `build_runner` companion — auto-generates static `find` / `instance` accessors on controllers and services from the `@AgInject()` annotation. |

---

## Installing

Add `ag_flow`, and `go_router` — your app owns its router:

```bash
flutter pub add ag_flow go_router
```

Activate the CLI globally (one-time per machine):

```bash
dart pub global activate ag_flow_cli
```

Or add it as a dev dependency and run it via `dart run`:

```bash
dart pub add --dev ag_flow_cli
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

with `main.dart` wired once:

```dart
void main() {
  InitialBinding().dependencies();
  runApp(MaterialApp.router(routerConfig: AppPages.router));
}
```

Every generated file is plain Dart — no reflection, no codegen required at
runtime. `ag analyze` re-validates any time the project grows.

---

## Architecture at a glance

```
GoRouter (your app's)
  └─ GoRoute → AgRoutePage (binds the module to the route's lifetime)
       └─ AgBasePage / AgListView          UI, state rendering
            └─ Controller                    page state, user actions
                 └─ Repo                     where data comes from (network, cache, offline)
                      └─ Service + action mixins   what the API looks like
                           └─ ApiProvider       the network (dio by default, swappable)
```

Each layer has exactly one job. Nothing skips a layer — the generator
enforces this and `ag analyze` catches it if you drift.

### Page state — three overrides, all optional

```dart
class ProductsPage extends AgBasePage<ProductsController> {
  @override
  Widget buildSuccess(BuildContext context) {
    return AgListView<Product>(
      controller: controller,
      itemBuilder: (context, item, index) => ProductItem(item: item),
    );
  }

  // Only override what you need — AG provides defaults for the rest.
  @override
  WidgetBuilder? get loadingBuilder => (context) => const MyLoadingSpinner();
}
```

### One mixin per Service action

The way Django REST Framework splits its views into `ListModelMixin`,
`CreateModelMixin`, and so on. Each mixin is a typed contract — it fixes
the method and its types — and the Service writes the body:

```dart
class ProductsService extends AgBaseService
    with AgListMixin<Product>, AgCreateMixin<Product> {
  ProductsService(super.apiProvider);

  @override
  AgPagination get pagination => const AgPageNumberPagination();

  @override
  Future<List<Product>> list({int page = 1}) => get(
    ProductEndpoints.products,
    queryParams: pagination.query(page),
    decode: (json) => [
      for (final item in json! as List<Object?>)
        Product.fromJson(item! as Map<String, dynamic>),
    ],
  );

  @override
  Future<Product> create(Product item) => post(
    ProductEndpoints.products,
    body: item.toJson(),
    decode: (json) => Product.fromJson(json! as Map<String, dynamic>),
  );
}

class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service);
  final ProductsService _service;

  Future<List<Product>> list({int page = 1}) => _service.list(page: page);
  bool isLastPage(List<Product> items) => _service.pagination.isLastPage(items);
  Future<Product> create(Product item) => _service.create(item);
}

class ProductsController extends AgBaseController<List<Product>>
    with AgLoadMore<Product> {
  ProductsController(this._repo);
  final ProductsRepo _repo;

  @override
  Future<List<Product>> list({int page = 1}) => _repo.list(page: page);
  @override
  bool isLastPage(List<Product> items) => _repo.isLastPage(items);

  Future<void> create(Product item) async {
    await _repo.create(item);
    await refresh();
  }
}
```

| Mixin | You implement | Repo and Controller method |
|---|---|---|
| `AgListMixin<T>` | `Future<List<T>> list()` (add `{int page = 1}` when paged) | `list` |
| `AgCreateMixin<T>` | `Future<T> create(T item)` | `create` |
| `AgRetrieveMixin<T, ID>` | `Future<T> retrieve(ID id)` | `retrieve` |
| `AgUpdateMixin<T, ID>` | `Future<T> update(ID id, T item)` | `update` |
| `AgDestroyMixin<ID>` | `Future<void> destroy(ID id)` | `destroy` |

Paging is opt-in: declare an `AgPagination` on the Service and add
`with AgLoadMore<T>` to the controller. `ID` can be an id, a slug, or a
record for a composite key. `ag g m` writes all of these bodies for you as
a starting point (`--paginate` for paging, `--methods=create,update,destroy`
to pick the writes).

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

// On a route in AppPages:
GoRoute(
  path: AppRoutes.home,
  redirect: (context, state) =>
      AgGuard.check(const [AuthGuard()], state.fullPath!),
  pageBuilder: ...,
)
```

---

## Showcase apps

Three real, running apps in this repo — each built entirely with the CLI,
against a live public API, showing a different slice of the framework:

| App | What it demonstrates |
|---|---|
| [`showcase/blog`](showcase/blog) | Paginated collection, detail with edit/delete, nested comments module — the same action names on every layer, `lookupId`, `AgLoadMore` + `AgListView`, path-parameter deep links |
| [`showcase/store`](showcase/store) | Category-filtered products, add/update/delete, `AgRetryPolicy` — an unpaged `list`, a filter kept in the controller and loaded through `refresh()`, feature-specific reads |
| [`showcase/tasks`](showcase/tasks) | Auth guard, go_router `ShellRoute` + `AgShellScope` with bottom nav, `AgStateService`, list writes shown with `emit(...)` — a complete architecture reference for a company-grade app |

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
