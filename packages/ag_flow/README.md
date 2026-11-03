# ag_flow

The runtime half of [AG Flow](../../README.md): opinionated
clean architecture for Flutter, with no manual setup. Every feature module
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

and the page, which renders loading / error / empty / success for you:

```dart
class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListView<Product>(
      controller: controller,
      itemBuilder: (context, product, index) => ProductItem(item: product),
    );
  }
}
```

## Same action names at every layer

| Action | Service mixin | Method (Service, Repo and Controller) |
|---|---|---|
| List | `AgListMixin<T>` | `list` |
| Create | `AgCreateMixin<T>` | `create` |
| Retrieve | `AgRetrieveMixin<T, ID>` | `retrieve` |
| Update | `AgUpdateMixin<T, ID>` | `update` |
| Destroy | `AgDestroyMixin<ID>` | `destroy` |

- **Each mixin is a typed contract.** It fixes the method and its types;
  the Service writes the body as one `get` / `post` / `put` / `patch` /
  `delete` call, so an unusual backend never
  fights a built-in default.
- **Only the Service has mixins.** One plain Repo and one plain Controller
  per module, with ordinary methods of the same names.
- **Any lookup type.** `ID` can be an id, a slug, or a record for a
  composite key — the Service places it in the URL.
- **Paging is opt-in.** Declare an `AgPagination`
  (`AgPageNumberPagination`, `AgLimitOffsetPagination`, or your own
  subclass) and pass `pagination.query(page)` from `list({int page = 1})`.
  The controller adds `with AgLoadMore<T>` and `AgListView<T>` loads the
  next page as the user scrolls. A backend that returns everything at once
  skips all three.

## Built for large apps

- **Caching and offline live in the Repo.** Change a Repo method's body;
  nothing above it changes.
- **Swappable network.** `ApiProvider` is a one-method interface;
  `DioApiProvider` is the default. Plug in http, GraphQL, an offline queue,
  or a test fake without touching a Service.
- **Your router.** `AgRoutePage` scopes a module's binding to its go_router
  route — registered when the route is created, released when it is gone,
  with its own controller per live route. `AgGuard.check` runs guards
  from `redirect:`, and `AgShellScope` gives a `ShellRoute` its own binding.
- **Enforced, not suggested.** `ag analyze` catches layer violations,
  missing wiring and hard-coded routes; `ag init` puts it in CI.
- **Feature-specific methods** (search, filters) sit beside the standard
  ones and pass down the same layers.

See the [showcase apps](../../showcase) for complete, running examples.
