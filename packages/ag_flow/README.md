# ag_flow

The runtime half of [AG Flow](../../README.md): a layered Flutter framework
for large apps, in the spirit of Django REST Framework. Every feature module
has the same shape — Page → Controller → Repo → Service → ApiProvider — and
the Service declares which backend actions it supports, one mixin each.

No third-party state-management dependency. Routing is your app's own
go_router; the network layer is an interface you can swap.

**Read the [developer guide](doc/guide.md)** for the full walkthrough.

## Install

```bash
flutter pub add ag_flow go_router
dart pub add --dev ag_flow_cli
dart run ag_flow_cli:ag init
dart run ag_flow_cli:ag g m product
```

```dart
void main() {
  InitialBinding().dependencies();
  runApp(MaterialApp.router(routerConfig: AppPages.router));
}
```

## A module

`ag g m product` generates the middle layers as plain code you own:

```dart
class ProductsService extends AgBaseService
    with AgPagedService<Product, int>, AgCreateMixin<Product> {
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
}

class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service);

  final ProductsService _service;

  Future<AgListPage<Product, int>> getPage(int pageKey) =>
      _service.getPage(pageKey);
  Future<Product> add(Product item) => _service.add(item);
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
}
```

and the page, which renders loading / error / empty / success for you:

```dart
class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Product, int>(
      controller: controller,
      itemBuilder: (context, product, index) => ProductItem(item: product),
    );
  }
}
```

## Service actions, one mixin each

| Action | Mixin | You implement |
|---|---|---|
| List | `AgListMixin<T>` | `getAll` |
| Create | `AgCreateMixin<T>` | `add` |
| Retrieve | `AgRetrieveMixin<T, ID>` | `getById` |
| Update | `AgUpdateMixin<T, ID>` | `update` |
| Delete | `AgDestroyMixin<ID>` | `delete` |

- **Each mixin is a typed contract.** It fixes the method and its types;
  the Service writes the body with `fetchList` / `fetchItem` / `send`, so
  an unusual backend never fights a built-in default.
- **Only the Service has mixins.** One plain Repo and one plain Controller
  per module, with ordinary methods.
- **Any lookup type.** `ID` can be an id, a slug, or a record for a
  composite key — the Service places it in the URL.
- **Optional paging helper.** `AgPagedService` implements `getPage` from a
  declared value: `AgPageNumberStrategy`, `AgOffsetStrategy`,
  `AgCursorStrategy`, `AgSinglePageStrategy`; responses unwrap with
  `AgEnvelope.raw`, `.key('data')`, `.path([...])`.

## Built for large apps

- **Caching and offline live in the Repo.** Change a Repo method's body;
  nothing above it changes.
- **Swappable network.** `ApiProvider` is a one-method interface;
  `DioApiProvider` is the default. Plug in http, GraphQL, an offline queue,
  or a test fake without touching a Service.
- **Your router.** `AgRoutePage` scopes a module's binding to its go_router
  route — registered when the route is created, released when it is gone,
  reference-counted across stacked instances. `AgGuard.check` runs guards
  from `redirect:`, and `AgShellScope` gives a `ShellRoute` its own binding.
- **Enforced, not suggested.** `ag analyze` catches layer violations,
  missing wiring and hard-coded routes; `ag init` puts it in CI.
- **Feature-specific methods** (search, filters) sit beside the standard
  ones and pass down the same layers.

See the [showcase apps](../../showcase) for complete, running examples.
