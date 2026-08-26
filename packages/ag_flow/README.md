# ag_flow

The runtime half of [AG Flow](../../README.md) — an opinionated Flutter
framework with no third-party state-management dependency. `ag_flow` gives
every feature module the same page/controller/repo/service layering,
page-state handling, pagination, and networking primitives, so the
[`ag_flow_cli`](../ag_flow_cli) generator (and hand-written modules) build
on a single, consistent contract.

## Install

```yaml
dependencies:
  ag_flow:
    git:
      url: https://github.com/kripadevg-code/ag_flow.git
      path: packages/ag_flow
      ref: ag_flow-v0.1.0
```

## Architecture

```
Page → Controller → Repo → Service → ApiProvider
```

Each layer has one job, and only talks to the layer directly below it —
see [ag_framework.md](../../requirments/ag_framework.md) for the full,
binding spec this package implements.

## Quick start — a collection module

```dart
class ProductsController extends AgListController<Product, int> {
  ProductsController(this._repo) : super(initialPageKey: 0);
  final ProductsRepo _repo;

  @override
  Future<AgListPage<Product, int>> fetchPage(int pageKey) => _repo.getPage(pageKey);
}

class ProductsPage extends AgBasePage<ProductsController> {
  const ProductsPage({super.key});

  // Independently overridable — leaving loadingBuilder/emptyBuilder null
  // keeps the AG defaults; only Error is customized here.
  @override
  Widget Function(BuildContext, Object, StackTrace?, VoidCallback)? get errorBuilder =>
      (context, error, stackTrace, retry) => MyCustomError(error: error, onRetry: retry);

  @override
  Widget buildSuccess(BuildContext context) {
    return AgListBuilder<Product, int>(
      controller: controller,
      itemBuilder: (context, product, index) => ProductCard(product: product),
    );
  }
}
```

## Quick start — a detail module

```dart
class ProductDetailsController extends AgDetailController<Product, ProductDetailsArguments> {
  ProductDetailsController(this._repo);
  final ProductDetailsRepo _repo;

  @override
  Future<Product> fetch() => _repo.getById(arguments.productId);
}

class ProductDetailsPage extends AgBasePage<ProductDetailsController> {
  const ProductDetailsPage({super.key});

  @override
  Widget buildSuccess(BuildContext context) => ProductDetailsView(product: controller.state.dataOrNull!);
}
```

`AgBasePage` has a single type parameter regardless of whether the module
is a collection or a detail page — the controller's own generics (`T`, and
for detail controllers `A`) already carry everything `AgBasePage` needs, so
there's no separate "detail" page base class and no argument type to state
twice.

## Networking

```dart
abstract class ProductEndpoints {
  static const products = AgEndpoint('/products', methods: {AgHttpMethod.get, AgHttpMethod.post});
  static const productById = AgEndpoint('/products/{id}', methods: {AgHttpMethod.get, AgHttpMethod.put, AgHttpMethod.delete});
}

class ProductService extends AgBaseService with AgCrudService<Product, String> {
  ProductService(super.apiProvider);

  // Two distinct endpoints, not one shared between them: getAll/add have
  // no id to supply, and getById/update/delete need one — a single
  // {id}-shaped endpoint can't serve both correctly.
  @override
  AgEndpoint get collectionEndpoint => ProductEndpoints.products;
  @override
  AgEndpoint get resourceEndpoint => ProductEndpoints.productById;
  @override
  Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);
  @override
  Map<String, dynamic> toJson(Product item) => item.toJson();

  // Feature-specific methods sit alongside the free add/getAll/getById/update/delete.
  Future<List<Product>> search(String query) => /* ... */;
}
```

**`AgCrudService` is opt-in, not mandatory.** AG never requires a fixed
CRUD method set — a Service that doesn't fit `add`/`getAll`/`getById`/
`update`/`delete` (e.g. a paginated collection, which needs a `getPage`
that mixin doesn't provide) just skips the mixin and writes exactly the
methods the feature needs, named however reads best. Repo/Controller
follow the same rule — a Controller is free to expose `addProduct`/
`deleteProduct`-style methods instead of a fixed shape, and
`AgPaginationMixin.updateItems` is available as an `emit()`-style escape
hatch for reflecting a mutation in the currently-displayed list without a
full `refresh()` — useful when the mutation itself already returned the
data, or against a backend that doesn't actually persist writes, where a
`refresh()` would never show what was just created.

See [example/](example) for a runnable app — entirely produced by
`ag_flow_cli` (`ag init` + `ag g m`), not hand-wired — demonstrating a
collection and a detail module wired end-to-end.
