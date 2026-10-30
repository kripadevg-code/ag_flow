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
- [11. Caching and offline support](#11-caching-and-offline-support)
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
| **Service** | What the API looks like: endpoints, paging, envelopes | Caching, state |
| **ApiProvider** | Sending requests | Knowing about features |

Each layer talks only to the one directly below it. `ag analyze` enforces
this, including through type hierarchies (a Page holding a type that
*extends* a Repo is caught too).

A generated collection module's three middle layers:

```dart
class ProductsService extends AgBaseService
    with
        AgPagedService<Product, int>,
        AgCreateMixin<Product>,
        AgDestroyMixin<int> {
  ProductsService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => ProductEndpoints.products;
  @override
  AgPageStrategy<int> get pageStrategy => const AgPageNumberStrategy();
  @override
  Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);

  @override
  Future<Product> add(Product item) => fetchItem(
    AgRequest(
      endpoint: ProductEndpoints.products,
      method: AgHttpMethod.post,
      body: item.toJson(),
    ),
    fromJson,
  );

  @override
  Future<void> delete(int id) => send<void>(
    AgRequest(
      endpoint: ProductEndpoints.productById,
      method: AgHttpMethod.delete,
      pathParams: {'id': id},
    ),
  );
}

class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service);

  final ProductsService _service;

  Future<AgListPage<Product, int>> getPage(int pageKey) =>
      _service.getPage(pageKey);
  Future<Product> add(Product item) => _service.add(item);
  Future<void> delete(int id) => _service.delete(id);
}

class ProductsController extends AgListController<Product, int> {
  ProductsController(this._repo) : super(initialPageKey: 1);

  final ProductsRepo _repo;

  @override
  Future<AgListPage<Product, int>> fetchPage(int pageKey) =>
      _repo.getPage(pageKey);

  Future<void> add(Product item) async {
    await _repo.add(item);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await refresh();
  }
}
```

Every one of these bodies is yours: the generator writes them as a starting
point and never touches them again. One Repo and one Controller per module,
with plain methods — there is nothing extra to learn above the Service.

## 5. Service actions: one mixin each

Only the Service has action mixins. Each is a **typed contract**: it fixes
the method's name and types, and your Service writes the body. Backends
differ too much — odd URLs, wrapped bodies, non-standard verbs — for one
built-in body to suit them all, so AG never guesses.

| Action | Mixin | Method you implement |
|---|---|---|
| List | `AgListMixin<T>` | `Future<List<T>> getAll({Map<String, dynamic>? queryParams})` |
| Create | `AgCreateMixin<T>` | `Future<T> add(T item)` |
| Retrieve | `AgRetrieveMixin<T, ID>` | `Future<T> getById(ID id)` |
| Update | `AgUpdateMixin<T, ID>` | `Future<T> update(ID id, T item)` |
| Delete | `AgDestroyMixin<ID>` | `Future<void> delete(ID id)` |

A Service mixes in exactly the actions its backend supports, so it never
exposes a method that can only fail. Forgetting a body is a compile error.

Write the bodies with the three helpers on `AgBaseService`, which send
through `ApiProvider` and unwrap the response with the Service's
`envelope`:

| Helper | Returns |
|---|---|
| `fetchList(request, fromJson)` | `List<T>` |
| `fetchItem(request, fromJson)` | `T` |
| `send<D>(request, decode: ...)` | the raw `AgResponse<D>` |

`AgPagedService<T, K>` is the one mixin with a body: an optional helper
that implements `getPage` from a declared `pageStrategy` (see section 7).
Skip it and write `getPage` yourself if your backend pages some other way.

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
    return AgListBuilder<Product, int>(
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

The paging dialect is a value the Service declares:

| Backend | `pageStrategy` |
|---|---|
| `?page=2&limit=20` | `AgPageNumberStrategy(pageParam: 'page', sizeParam: 'limit')` |
| `?offset=40&limit=20` | `AgOffsetStrategy(offsetParam: 'offset', limitParam: 'limit')` |
| opaque `next` cursor | `AgCursorStrategy(...)` |
| everything in one response | `AgSinglePageStrategy()` |

Where the items sit in the body is another value, `envelope`:
`AgEnvelope.raw` (the body is the list), `AgEnvelope.key('data')`,
`AgEnvelope.path(['data', 'items'])`, or `AgEnvelope.custom(...)`.

Filters, search terms and sort orders go in `pageQueryParams`:

```dart
String? category;

@override
Map<String, dynamic> get pageQueryParams =>
    {if (category != null) 'category': category};
```

`AgListBuilder` loads the next page as the user scrolls, shows a retry slot
when a page fails, and keeps load-more state apart from page state, so a
failed page never blanks a list that's already showing.

## 8. Detail modules and lookups

A detail route carries what it needs in its URL (`/product/details/:id`),
so it opens from a deep link, a notification or a browser reload — not only
from an in-app push. The controller turns its argument into a **lookup**,
the way a DRF view declares `lookup_field`:

```dart
class ProductDetailsController
    extends AgDetailController<Product, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);

  final ProductDetailsRepo _repo;

  @override
  ProductDetailsPageArgument? argumentsFromPath(Map<String, String> p) =>
      ProductDetailsPageArgument.fromPathParameters(p);

  int get lookupId => int.parse(arguments.id);

  @override
  Future<Product> fetch() => _repo.getById(lookupId);

  Future<void> update(Product item) async {
    emit(AgPageState.success(await _repo.update(lookupId, item)));
  }

  Future<void> delete() => _repo.delete(lookupId);
}
```

A lookup is not limited to an id. `ID` is any type — a slug, a UUID, or a
record — and the Service, which writes its own `getById`, places it in the
URL however the backend wants:

```dart
// A composite key:   /orgs/{org}/projects/{id}
@override
Future<Project> getById(({String org, int id}) key) => fetchItem(
  AgRequest(
    endpoint: ProjectEndpoints.byOrg,
    pathParams: {'org': key.org, 'id': key.id},
  ),
  Project.fromJson,
);
```

If the argument already carries the whole object, still return its id from
`lookupId` (so update and delete address it), and override `fetch()` if you
want to skip the refetch — falling back to it on a deep link, where only
the id is in the URL:

```dart
@override
Future<Product> fetch() async =>
    arguments.product ?? await _repo.getById(lookupId);
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
line too, and decode through the same envelope:

```dart
Future<List<Product>> search(String term) => fetchList(
  AgRequest(endpoint: ProductEndpoints.search, queryParams: {'q': term}),
  fromJson,
);
```

## 11. Caching and offline support

The Repo owns *where data comes from*, so that is where caching and offline
support go. Its methods are plain delegation, so change the body:

```dart
class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service, this._cache);

  final ProductsService _service;
  final ProductCache _cache;

  Future<AgListPage<Product, int>> getPage(int pageKey) async {
    try {
      final page = await _service.getPage(pageKey);
      await _cache.save(pageKey, page.items);
      return page;
    } on AgApiException {
      final cached = await _cache.read(pageKey);
      if (cached == null) rethrow;
      return AgListPage(items: cached, hasMore: false);
    }
  }
}
```

The Controller and Page above it don't change. For queued offline writes,
change `add`/`update`/`delete` the same way, or plug an offline-aware
`ApiProvider` in underneath.

## 12. Custom actions and escape hatches

Feature-specific actions sit beside the standard ones, passed down the
same layers:

```dart
class ProductsController extends AgListController<Product, int> {
  ...

  // ProductsRepo.search → ProductsService.search (a one-line fetchList).
  Future<List<Product>> search(String term) => _repo.search(term);

  // Optimistic delete: update the list now, then confirm with the backend.
  Future<void> delete(int id) async {
    updateItems((items) => [...items.where((p) => p.id != id)]);
    await _repo.delete(id);
  }
}
```

`updateItems` changes the displayed list without a refetch — useful when
the backend doesn't persist writes immediately. The layering rules apply
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
expect(controller.pagination.items, hasLength(20));
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
