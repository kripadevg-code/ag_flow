# AG Flow — developer guide

AG Flow gives every feature in a Flutter app the same shape, the way Django
REST Framework gives every endpoint in a Django app the same shape. Every
module is Page → Controller → Repo → Service → ApiProvider, the Service
declares which actions its backend supports with one mixin each, and the
rest is ordinary Dart you own. Two modules written by two different teams
read the same, so a large codebase stays navigable.

- [1. Install](#1-install)
- [2. Bootstrap a project](#2-bootstrap-a-project)
- [3. Generate a module](#3-generate-a-module)
- [4. The layers](#4-the-layers)
- [5. Service actions: one mixin each](#5-service-actions-one-mixin-each)
- [6. Pages and state](#6-pages-and-state)
- [7. Lists and pagination](#7-lists-and-pagination)
- [8. Detail modules and lookups](#8-detail-modules-and-lookups)
- [9. Routing (your go_router)](#9-routing-your-go_router)
- [10. Networking](#10-networking)
- [11. Errors, caching and offline](#11-errors-caching-and-offline)
- [12. Custom actions and escape hatches](#12-custom-actions-and-escape-hatches)
- [13. Large apps: structure and enforcement](#13-large-apps-structure-and-enforcement)
- [14. Testing](#14-testing)
- [15. Migrating from 0.3](#15-migrating-from-03)

---

## 1. Install

```bash
flutter pub add ag_flow go_router
dart pub add --dev ag_flow_cli
```

`go_router` is *your* dependency, not AG's — your app owns its router and
upgrades it on its own schedule. AG adds one page class to it and nothing
else.

## 2. Bootstrap a project

```bash
dart run ag_flow_cli:ag init
```

This creates `lib/core/` — the only shared, app-level code:

```
lib/core/
  arguments/arguments.dart          navigation arguments (one file, CLI-maintained)
  endpoints.dart                    API endpoints, grouped by backend domain
  bindings/initial_binding.dart     app-wide singletons, e.g. the ApiProvider
  routes/app_routes.dart            route path constants
  routes/app_pages.dart             your GoRouter and its routes
  routes/route_management.dart      every navigation call in the app
```

plus `AGENTS.md` (the architecture standard, read automatically by coding
agents), a CI workflow, and an opt-in pre-commit hook that run `ag analyze`.

Then wire `main.dart`:

```dart
void main() {
  InitialBinding().dependencies();
  runApp(MaterialApp.router(routerConfig: AppPages.router));
}
```

Set your API's base URL in `initial_binding.dart` and you are ready.

## 3. Generate a module

(`ag` below is `dart run ag_flow_cli:ag`, or just `ag` after
`dart pub global activate ag_flow_cli`.)

```bash
ag g m product                                  # a collection (list) module
ag g m product/details                          # a detail module under it
ag g m order --from-json=order_sample.json      # typed from a real API response
ag g m invoice --methods=add                    # read + create only
ag g m report --methods=none                    # read-only
```

One command writes the page, controller, repo, service, binding and the
page's components, **and** registers the route, the navigation method and
(for a detail module) the argument class. With `--from-json`, the model is
inferred from a real response and threaded through every layer, so nothing
is typed `dynamic`.

Each module is self-contained, like an Angular feature module:

```
lib/modules/product/
  bindings/      products_binding.dart, product_details_binding.dart
  components/    product/ (app bar, item, loading, error, empty) ...
  controllers/   products_controller.dart, product_details_controller.dart
  models/        product.dart
  pages/         products_page.dart, product_details_page.dart
  repos/         products_repo.dart, product_details_repo.dart
  services/      products_service.dart, product_details_service.dart
```

Folders are flat per root module: `product/details` lives in `product`'s
folders, never in a nested folder of its own.

## 4. The layers

```
Page → Controller → Repo → Service → ApiProvider
```

| Layer | Owns | Never |
|---|---|---|
| **Page** | Rendering | Business logic, Repo or Service access |
| **Controller** | Page state, user actions | Talking to a Service or the network |
| **Repo** | Where data comes from: network, cache, offline | Building requests |
| **Service** | What the API looks like: endpoints, paging, decoding | Caching, state |
| **ApiProvider** | Sending requests | Knowing about features |

Each layer talks only to the one directly below it. `ag analyze` enforces
this, including through type hierarchies (a Page holding a type that
*extends* a Repo is caught too).

A generated collection module's three middle layers
(`ag g m product --paginate --methods=create,destroy`):

```dart
class ProductsService extends AgBaseService
    with AgListMixin<Product>, AgCreateMixin<Product>, AgDestroyMixin<int> {
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

  @override
  Future<void> destroy(int id) => delete(
    ProductEndpoints.productById,
    pathParams: {'id': id},
  );
}

class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service);

  final ProductsService _service;

  Future<List<Product>> list({int page = 1}) => _service.list(page: page);
  bool isLastPage(List<Product> items) => _service.pagination.isLastPage(items);
  Future<Product> create(Product item) => _service.create(item);
  Future<void> destroy(int id) => _service.destroy(id);
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

  Future<void> destroy(int id) async {
    await _repo.destroy(id);
    await refresh();
  }
}
```

Every one of these bodies is yours: the generator writes them as a starting
point and never touches them again. One Repo and one Controller per module,
with plain methods that use the same five names as the Service — there is
nothing extra to learn above the Service.

## 5. Service actions: one mixin each

Only the Service has action mixins. Each is a **typed contract**: it fixes
the method's name and types, and your Service writes the body. Backends
differ too much — odd URLs, wrapped bodies, non-standard verbs — for one
built-in body to suit them all, so AG never guesses.

| Action | Mixin | Method you implement |
|---|---|---|
| List | `AgListMixin<T>` | `Future<List<T>> list()` — a paged Service writes `list({int page = 1})` |
| Create | `AgCreateMixin<T>` | `Future<T> create(T item)` |
| Retrieve | `AgRetrieveMixin<T, ID>` | `Future<T> retrieve(ID id)` |
| Update | `AgUpdateMixin<T, ID>` | `Future<T> update(ID id, T item)` |
| Destroy | `AgDestroyMixin<ID>` | `Future<void> destroy(ID id)` |

A Service mixes in exactly the actions its backend supports, so it never
exposes a method that can only fail. Forgetting a body is a compile error.
The Repo and Controller use the same names, so `list` / `create` /
`retrieve` / `update` / `destroy` mean the same thing at every layer.

Write each body as one call named after its HTTP verb — `get`, `post`,
`put`, `patch` or `delete` on `AgBaseService`:

| Argument | Meaning |
|---|---|
| endpoint (first) | an `AgEndpoint` from `core/endpoints.dart` |
| `pathParams` | fills `{tokens}` in the endpoint's path |
| `queryParams` | the query string |
| `body` | the JSON body (`post` / `put` / `patch` / `delete`) |
| `headers` | per-request headers |
| `decode` | turns the JSON body into your type |

Each sends through `ApiProvider` and returns only the decoded data. A
wrapped response is unwrapped inside `decode`
(`(json) => ... (json! as Map)['data'] ...`). When you need the whole
`AgResponse` — status code, headers — or form data, build an `AgRequest`
and call `send<D>(request, decode: ...)` instead.

Decoding stays in the Service, so the Repo and everything above it only
ever see typed objects. `decode` may return a Future: for a very large
body, build the objects off the UI thread with Flutter's `compute`:

```dart
Future<List<Product>> list() => get(
  ProductEndpoints.products,
  decode: (json) => compute(Product.listFromJson, json),
);
```

dio already parses large JSON text in a background isolate, so this is
only worth it when building the objects is itself slow.

## 6. Pages and state

A controller's state is one sealed `AgPageState<T>`: `initial`, `loading`,
`success`, `empty`, `error`. Never `isLoading` / `errorMessage` fields.
`AgBasePage` renders each state, and you override only what you need:

```dart
class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => ProductAppBar();

  @override
  WidgetBuilder? get emptyBuilder => (context) => const ProductEmpty();

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListView<Product>(
      controller: controller,
      itemBuilder: (context, product, index) => ProductItem(item: product),
    );
  }
}
```

The generator gives each slot (app bar, loading, error, empty) its own
component file. Delete one and its reference to fall back to AG's default.

Controllers load automatically when their binding registers them, refresh
with `refresh()`, and are disposed when their route is gone. A response
that arrives after its page was closed, or after a newer request started,
is dropped — never shown.

## 7. Lists and pagination

Every controller extends `AgBaseController<T>` and loads with its Repo's
action name: `with AgList<Product>` and `list()` for a list page,
`with AgRetrieve<Product>` and `retrieve()` for a details page. A controller
that loads nothing (a form) mixes in neither. Paging is opt-in.

How the backend pages is a value the Service declares:

| Backend | `pagination` |
|---|---|
| `?page=2&limit=20` | `AgPageNumberPagination(pageParam: 'page', sizeParam: 'limit')` |
| `?offset=40&limit=20` | `AgLimitOffsetPagination(offsetParam: 'offset', limitParam: 'limit')` |
| anything else | your own `AgPagination` subclass: implement `query(page)` |
| everything in one response | nothing — leave `pagination` null and write `list()` with no page |

`pageSize` defaults to 20. `isLastPage(items)` defaults to "fewer items than
`pageSize`"; override it when the backend says so another way.

The paged controller mixes in `AgLoadMore<T>` instead of `AgList<T>` and
implements `list({int page = 1})` and `isLastPage`. `AgLoadMore` loads
page 1 for you and adds `loadMore()`, `hasMore`, `isLoadingMore` and
`loadMoreError`. `AgListView<T>` loads the next page as the user scrolls,
shows a retry slot when a page fails, and keeps load-more state apart from
page state, so a failed page never blanks a list that's already showing.
`AgListView` also works on a controller without `AgLoadMore` — it then
just shows the list.

A filter, search term or sort order is state the controller keeps, loaded
through `refresh()`, so a pull-to-refresh keeps it and a newer request
always wins over an older one:

```dart
String? _category;

@override
Future<List<Product>> list() {
  final category = _category;
  return category == null ? _repo.list() : _repo.listByCategory(category);
}

Future<void> filterByCategory(String? category) {
  _category = category;
  return refresh();
}
```

## 8. Detail modules and lookups

A detail route carries what it needs in its URL (`/product/details/:id`),
so it opens from a deep link, a notification or a browser reload — not only
from an in-app push. The controller reads its argument from
`AgRouteData.pathParameters` and turns it into a **lookup**, the way a DRF
view declares `lookup_field`:

```dart
class ProductDetailsController extends AgBaseController<Product>
    with AgRetrieve<Product> {
  ProductDetailsController(this._repo)
    : argument = ProductDetailsPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final ProductDetailsRepo _repo;
  final ProductDetailsPageArgument argument;

  int get lookupId => int.parse(argument.id);

  @override
  Future<Product> retrieve() => _repo.retrieve(lookupId);

  Future<void> update(Product item) async {
    emit(AgPageState.success(await _repo.update(lookupId, item)));
  }

  Future<void> destroy() => _repo.destroy(lookupId);
}
```

A lookup is not limited to an id. `ID` is any type — a slug, a UUID, or a
record — and the Service, which writes its own `retrieve`, places it in the
URL however the backend wants:

```dart
// A composite key:   /orgs/{org}/projects/{id}
@override
Future<Project> retrieve(({String org, int id}) key) => get(
  ProjectEndpoints.byOrg,
  pathParams: {'org': key.org, 'id': key.id},
  decode: (json) => Project.fromJson(json! as Map<String, dynamic>),
);
```

If the push already handed over the whole object in `extra`, still return
its id from `lookupId` (so update and destroy address it), and override
`retrieve()` to skip the request — falling back to it on a deep link, where
only the id is in the URL:

```dart
@override
Future<Product> retrieve() async =>
    AgRouteData.extra as Product? ?? await _repo.retrieve(lookupId);
```

## 9. Routing (your go_router)

Routing is plain go_router, owned by your app. AG contributes one class,
`AgRoutePage`, which registers a module's binding when its route is created
and releases it once the route is gone. `ag g m` writes each route for you:

```dart
GoRoute(
  path: AppRoutes.productDetails,
  name: AppRoutes.productDetails,
  pageBuilder: (context, state) => AgRoutePage<void>(
    key: state.pageKey,
    pathParameters: state.pathParameters,
    extra: state.extra,
    binding: ProductDetailsBinding(),
    transition: AppPages.defaultTransition,
    child: const ProductDetailsPage(),
  ),
),
```

Everything else is ordinary go_router. Restructure freely — `ag g m` finds a
route by its path wherever it sits and never adds it twice.

**Navigate only through `RouteManagement`.** Screens call
`RouteManagement.goToProductDetailsPage(argument)`, never a literal path;
`ag analyze` flags `context.push('/x')`-style calls anywhere else.

```dart
// core/routes/route_management.dart (generated, then yours to extend)
static void goToProductDetailsPage(ProductDetailsPageArgument argument) {
  AppPages.router.pushNamed<void>(
    AppRoutes.productDetails,
    pathParameters: argument.toPathParameters(),
  );
}
```

To leave a page for another, use `pushReplacementNamed`, **not**
`replace`/`replaceNamed`: `replace` reuses the page key, so the new module's
binding never registers and the old one is never released.

**Guards** are `AgGuard`s, run from a route's `redirect`. They run in order
and the first redirect wins; a blocked route never builds, so its binding
never registers:

```dart
class AuthGuard extends AgGuard {
  const AuthGuard();

  @override
  String? redirect(String path) =>
      AuthService.instance.isLoggedIn ? null : AppRoutes.login;
}

GoRoute(
  path: AppRoutes.orders,
  redirect: (context, state) =>
      AgGuard.check(const [AuthGuard(), AdminGuard()], state.fullPath!),
  pageBuilder: ...,
)
```

**Persistent chrome** (a bottom bar, a rail) is a go_router `ShellRoute`.
Wrap it in `AgShellScope` to give the shell a binding that lives exactly as
long as the shell:

```dart
ShellRoute(
  builder: (context, state, child) => AgShellScope(
    binding: ShellBinding(),
    child: ShellPage(child: child),
  ),
  routes: [ /* GoRoutes */ ],
)
```

## 10. Networking

Declare endpoints once, grouped by backend domain:

```dart
abstract class ProductEndpoints {
  static const products = AgEndpoint(
    '/products',
    methods: {AgHttpMethod.get, AgHttpMethod.post},
  );
  static const productById = AgEndpoint(
    '/products/{id}',
    methods: {AgHttpMethod.get, AgHttpMethod.put, AgHttpMethod.delete},
  );
}
```

`ApiProvider` is the only thing that sends requests, and it is an
interface. The default is dio-backed:

```dart
put<ApiProvider>(
  ApiProvider(
    baseUrl: 'https://api.example.com',
    retryPolicy: const AgRetryPolicy(maxAttempts: 3),
    interceptors: [AuthInterceptor()],
  ),
  permanent: true,
);
```

To use something else — `package:http`, a GraphQL client, an offline
request queue, a fake for tests — implement its one method. Nothing above
it changes:

```dart
class HttpApiProvider implements ApiProvider {
  @override
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
    AgCancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    // request.method, request.resolvePath(), request.queryParams,
    // request.headers, request.body → your client → AgResponse
    // failures → throw AgApiException
  }
}
```

Every failure surfaces as `AgApiException`, whichever transport is
plugged in.

**Feature-specific reads** — a search, a filtered sub-collection — are one
more method on the Service, written with `get` like the actions:

```dart
Future<List<Product>> search(String term) => get(
  ProductEndpoints.search,
  queryParams: {'q': term},
  decode: (json) => [
    for (final item in json! as List<Object?>)
      Product.fromJson(item! as Map<String, dynamic>),
  ],
);
```

## 11. Errors, caching and offline

The Repo is the boundary between the app and its data sources. Two things
live there: turning transport errors into app errors, and deciding where
data comes from.

### Errors

Generated Repo methods wrap the Service call in `guard`:

```dart
Future<Product> retrieve(int id) => guard(() => _service.retrieve(id));
```

`guard` turns any error into an `AgRepoException` whose `kind` says what
went wrong — `network`, `timeout`, `cancelled`, `unauthorized` (401/403),
`notFound` (404), `rejected` (other 4xx), `server` (5xx), `badResponse`
(the body didn't decode into the model) or `unknown`. The original error
stays in `cause`. Controllers and pages react to `kind` and never see HTTP
details; `AgError` shows `AgRepoException.message` by default. To show your
own (localized) text, pass `message:` to `AgError` from the page's
`errorBuilder`:

```dart
@override
get errorBuilder => (context, error, stackTrace, retry) => AgError(
  error: error,
  onRetry: retry,
  message: error is AgRepoException &&
          error.kind == AgRepoErrorKind.network
      ? context.l10n.offline
      : null,
);
```

### Caching and offline

The Repo owns *where data comes from*, so that is where caching and offline
support go. Its methods are plain delegation, so change the body:

```dart
class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service, this._cache);

  final ProductsService _service;
  final ProductCache _cache;

  Future<List<Product>> list({int page = 1}) async {
    try {
      final items = await guard(() => _service.list(page: page));
      await _cache.save(page, items);
      return items;
    } on AgRepoException catch (e) {
      final cached = e.kind == AgRepoErrorKind.network
          ? await _cache.read(page)
          : null;
      if (cached == null) rethrow;
      return cached;
    }
  }
}
```

The Controller and Page above it don't change. For queued offline writes,
change `create`/`update`/`destroy` the same way, or plug an offline-aware
`ApiProvider` in underneath.

The tasks showcase does exactly this: `TasksRepo` and `TaskDetailsRepo`
save what they read to a `TasksStore` and read it back on a network error
(`showcase/tasks/lib/modules/tasks/`).

## 12. Custom actions and escape hatches

Feature-specific actions sit beside the standard ones, passed down the
same layers:

```dart
class ProductsController extends AgBaseController<List<Product>>
    with AgLoadMore<Product> {
  ...

  // ProductsRepo.search → ProductsService.search.
  Future<List<Product>> search(String term) => _repo.search(term);

  // Optimistic destroy: update the list now, then confirm with the backend.
  Future<void> destroy(int id) async {
    final shown = state.dataOrNull ?? const <Product>[];
    emit(AgPageState.success(shown.where((p) => p.id != id).toList()));
    await _repo.destroy(id);
  }
}
```

`emit` changes the displayed list without a reload — useful when the
backend doesn't persist writes immediately. The layering rules apply
to every module; how each method works is up to you.

## 13. Large apps: structure and enforcement

- **One module per feature**, generated, never hand-assembled. `ag g m`
  replaces about fourteen hand-written files and registers the routing.
- **Shared code lives in `lib/core/` only** — arguments, endpoints, routes,
  app-wide bindings.
- **`ag analyze` is the gate.** It checks missing layer files, missing
  route wiring, duplicate routes, nested module folders, hard-coded route
  strings, layer-direction violations and unused detail arguments. `ag init`
  wires it into CI and a pre-commit hook, so non-conforming code cannot
  merge.
- **`AGENTS.md`** states the standard for every developer and coding agent
  that opens the project, so new code follows the existing shape.
- **App-wide services** (auth, theme, cart) extend `AgStateService` — a
  `ChangeNotifier` registered once in `InitialBinding` — and are read
  anywhere via a static `instance` getter.

## 14. Testing

Every layer is constructor-injected, so each is testable on its own:

```dart
class FakeApiProvider implements ApiProvider { ... }   // returns fixtures

final controller = ProductsController(
  ProductsRepo(ProductsService(FakeApiProvider())),
);
await controller.loadInitial();
expect(controller.state.dataOrNull, hasLength(20));
```

Widget tests construct a controller directly and pass it to the page's
widgets — no locator setup needed. To exercise navigation, pump
`MaterialApp.router(routerConfig: AppPages.router)` and call
`RouteManagement` methods.

## 15. Migrating from 0.3

| 0.3 | Now |
|---|---|
| `with AgCrudService<T, ID>` | `extends AgBaseService with` only the action mixins the backend supports, each method implemented by the Service |
| Service `idOf` / `getByArgument` adapters | Controller `lookupId` |
| `getAll` / `add` / `getById` / `update` / `delete` | `list` / `create` / `retrieve` / `update` / `destroy`, at every layer |
| `fetchList` / `fetchItem` / `AgEnvelope` | `get` / `post` / `put` / `patch` / `delete` — unwrap inside `decode` |
| `AgPagedService` + `pageStrategy` | `pagination` (`AgPageNumberPagination` / `AgLimitOffsetPagination`) + your own `list({int page = 1})` |
| `extends AgListController<T, K>` + `fetchPage(key)` | `extends AgBaseController<List<T>> with AgLoadMore<T>` + `list({int page = 1})` and `isLastPage` |
| `fetch()` on a controller | `with AgList<T>` + `list()`, or `with AgRetrieve<T>` + `retrieve()` |
| `extends AgDetailController<T, A>` + `arguments` | `extends AgBaseController<T>`, argument read from `AgRouteData.pathParameters` in the constructor |
| `AgListBuilder<T, K>` | `AgListView<T>` |
| `updateItems(...)` | `emit(AgPageState.success(...))` |
| `pageQueryParams` | a filter field on the controller, loaded through `refresh()` |
| `AgApp(routes: AppPages.pages, ...)` | `MaterialApp.router(routerConfig: AppPages.router)` |
| `AgRoute(path:, page:, binding:, guards:)` | `GoRoute(..., redirect: AgGuard.check(...), pageBuilder: AgRoutePage(...))` |
| `AgShellRoute(binding:, ...)` | `ShellRoute(builder: ... AgShellScope(binding: ...))` |
| `AgNavigator.toNamed` / `offNamed` / `offAllNamed` | `AppPages.router.pushNamed` / `pushReplacementNamed` / `goNamed` |
| `AgNavigator.extra`, `.pathParameters` | `AgRouteData.extra`, `.pathParameters` |
| `initialBinding: InitialBinding()` | `InitialBinding().dependencies()` in `main()` |
| `ApiProvider(...)` | unchanged — now builds a `DioApiProvider` |

Re-running `ag g m` on an existing module never overwrites it. To adopt the
new shapes in an old module, generate it into a scratch project and copy
the Service, Repo and Controller across.
