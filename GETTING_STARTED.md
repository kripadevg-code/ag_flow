# Getting started with AG Flow

This is a hands-on walkthrough for a developer who has never touched AG
before. It assumes nothing except that you can run `flutter create` and
you've been given access to this repo. By the end you'll have generated,
customized, and understood every layer of a real feature module.

For the *why* (the pitch, the architecture diagram, the package list),
see the root [README.md](README.md). For the exact rules AG enforces,
see [requirments/](requirments/). This doc is the *how*.

## 1. What you're actually installing

Two packages:

- **`ag_flow`** — a runtime library. Your app depends on it like any
  other package. It gives you base classes (`AgBasePage`,
  `AgBaseController`, `AgBaseRepo`, `AgBaseService`, `ApiProvider`, ...)
  that every generated module is built from.
- **`ag_flow_cli`** — a command-line tool (`ag`). You run it from your
  terminal; it writes `.dart` files into your project. It never ships
  inside your app — it's a dev-time tool only.

Neither package is on pub.dev yet — add them as git dependencies pinned to
a tag:

```yaml
# your app's pubspec.yaml
dependencies:
  ag_flow:
    git:
      url: https://github.com/kripadevg-code/ag_flow.git
      path: packages/ag_flow
      ref: ag_flow-v0.1.0
```

Activate the CLI globally so `ag` is on your `$PATH`:

```bash
dart pub global activate --source git https://github.com/kripadevg-code/ag_flow.git \
  --git-path packages/ag_flow_cli --git-ref ag_flow_cli-v0.1.0
```

## 2. Bootstrap your project: `ag init`

Run this once, from your Flutter app's root (next to its `pubspec.yaml`):

```bash
ag init
```

This creates six files under `lib/core/` — the shared scaffolding every
generated module plugs into:

```
lib/core/
├── arguments/arguments.dart        # every navigation-argument class, in one file
├── endpoints.dart                  # your API endpoints (you write these by hand)
├── routes/
│   ├── app_routes.dart             # route path constants
│   ├── app_pages.dart              # AgRoute registrations
│   └── route_management.dart       # goToXPage() navigation methods
└── bindings/initial_binding.dart   # registers the one shared ApiProvider
```

Two things worth knowing immediately:

- **It's idempotent.** Run `ag init` again any time — files that already
  exist are left alone, even if you've hand-edited them. It never
  overwrites.
- **`endpoints.dart` is the one file `ag` never touches automatically.**
  Every other file above gets auto-updated by `ag g m`. Endpoints are
  grouped by *backend domain* (e.g. one class per REST resource), not by
  frontend module, so there's no reliable mapping from "a module got
  generated" to "here's the endpoint it needs" — you write these by hand.
  `ag init` leaves you a comment showing the shape:

  ```dart
  abstract class ProductEndpoints {
    static const products = AgEndpoint('/products');
    static const productById = AgEndpoint('/products/{id}');
  }
  ```

Before running your app, set a real base URL in
`lib/core/bindings/initial_binding.dart` (it defaults to a placeholder),
and wire `AgApp` in your `main.dart`:

```dart
import 'package:ag_flow/ag_flow.dart';
import 'package:your_app/core/bindings/initial_binding.dart';
import 'package:your_app/core/routes/app_pages.dart';
import 'package:your_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AgApp(
      initialRoute: AppRoutes.initial,   // or your first real module's route
      initialBinding: InitialBinding(),
      routes: AppPages.pages,
    );
  }
}
```

## 3. Your first module: `ag g m product`

A "module" is a feature — a list screen, a detail screen, anything that
needs its own page. Generate one:

```bash
ag g m product
```

Output:

```
create  lib/modules/product/repos/products_repo.dart
create  lib/modules/product/components/product/product_appbar.dart
create  lib/modules/product/components/product/product_loading.dart
create  lib/modules/product/components/product/product_error.dart
create  lib/modules/product/components/product/product_empty.dart
create  lib/modules/product/components/product/product_item.dart
create  lib/modules/product/bindings/products_binding.dart
create  lib/modules/product/controllers/products_controller.dart
create  lib/modules/product/pages/products_page.dart
create  lib/modules/product/services/products_service.dart
update  lib/core/routes/app_routes.dart
update  lib/core/routes/app_pages.dart
update  lib/core/routes/route_management.dart

Generated 14 file(s) for product.
```

Everything you generate lives under one shared `lib/modules/` folder,
next to (never inside) `lib/core/`. Within it, files are organized *by
architectural layer*, not by feature — every module's controllers sit
together in `controllers/`, every module's pages in `pages/`, and so on.
This is deliberate (see [requirments/ag_framework.md](requirments/ag_framework.md)
§6): it's what makes the CLI's aggregator-file updates (routes, DI,
navigation) mechanical and safe.

You now have a fully wired, runnable screen — navigate to
`AppRoutes.product` (or call `RouteManagement.goToProductsPage()`, which
`ag g m` just generated for you) and you'll see it. It won't show real
data yet — that's next — but the loading spinner, the page-state
machine, and the routing are already live.

### What each generated file is for

**The five architectural layers** — every module has these:

| File | Extends | Job |
|---|---|---|
| `pages/products_page.dart` | `AgBasePage<ProductsController>` | UI wiring only — no business logic |
| `controllers/products_controller.dart` | `AgListController<dynamic, int>` | Page state, pagination, calls the Repo |
| `repos/products_repo.dart` | `AgBaseRepo` | Thin pass-through to the Service |
| `services/products_service.dart` | `AgBaseService` | The only layer allowed to touch the network |
| `bindings/products_binding.dart` | `AgBinding` | Registers Service → Repo → Controller with `AgLocator` |

The chain is strict: **Page → Controller → Repo → Service → ApiProvider**.
Nothing skips a layer — `ag analyze` (§8 below) enforces this for real,
not just by convention.

**The generated components** — five files under
`components/product/`, one per independently-overridable page slot:

| File | Wired into the page as |
|---|---|
| `product_appbar.dart` | `appBar(context)` |
| `product_loading.dart` | `loadingBuilder` |
| `product_error.dart` | `errorBuilder` |
| `product_empty.dart` | `emptyBuilder` |
| `product_item.dart` | one row inside the page's `AgListBuilder` |

Each is a tiny, fully-owned starting point — open `product_appbar.dart`
and you'll find a plain `AppBar` subclass with a placeholder title. Edit
it directly, or delete the file *and* its one-line reference in the page
to fall back to AG's own default for that slot. `product_item.dart` is
the one genuinely reusable widget (one row of the list); the other four
are the page's own loading/error/empty/appBar behavior, factored out so
you can change one without touching the page file at all.

The page's actual content (`buildSuccess`) is **not** split into its own
file — it's the page's own body, so it stays in `products_page.dart`:

```dart
@override
Widget buildSuccess(BuildContext context) {
  return AgListBuilder<dynamic, int>(
    controller: controller,
    itemBuilder: (context, item, index) => ProductItem(item: item),
  );
}
```

### Making it show real data

Two edits turn the placeholder into a working screen:

**1. Add an endpoint** (`lib/core/endpoints.dart`, by hand):

```dart
abstract class ProductEndpoints {
  static const products = AgEndpoint('/products');
}
```

**2. Implement the Service's read method**
(`services/products_service.dart` — replace the `UnimplementedError`):

```dart
Future<AgListPage<Product, int>> getPage(int pageKey) async {
  final response = await send<List<dynamic>>(
    AgRequest(
      endpoint: ProductEndpoints.products,
      method: AgHttpMethod.get,
      queryParams: {'page': '$pageKey'},
    ),
    decode: (json) => json as List<dynamic>,
  );
  final items = response.data.map((j) => Product.fromJson(j)).toList();
  return AgListPage(items: items, hasMore: items.isNotEmpty, nextPageKey: pageKey + 1);
}
```

Everywhere you see `dynamic` in generated code (`AgListController<dynamic,
int>`, `Future<dynamic> add(...)`), that's a placeholder for *your* model
type. Swap it for your real class once you have one — the generator can't
know it in advance, so it leaves the type open rather than guessing.

Update `Repo`/`Controller` to match (change `dynamic` → `Product` in
their signatures too) — they're thin pass-throughs, so the change is
usually one line each.

### CRUD stubs, and `--methods=`

By default every module's Service/Repo/Controller *also* get `add`/
`update`/`delete` stubs — not just the read method. This is deliberate:
a generator's whole point is to hand you more working boilerplate than
you'd write from scratch, not less. Every stub is a plain
`UnimplementedError` placeholder, exactly like the read method:

```bash
ag g m product                          # add, update, delete — all three (default)
ag g m product --methods=add,delete     # only these two
ag g m product --methods=none           # read-only
```

### Give the module its real type

By default every layer is typed `dynamic` — the generator doesn't know
your data, so it leaves a placeholder. You can skip all of that by
handing it a real API response:

```bash
curl https://api.example.com/products > product.json
ag g m product --from-json=product.json
```

That generates `lib/modules/product/models/product.dart` and threads
`Product` through the Service, Repo, Controller, Page and item component,
so the module compiles against your data immediately:

```dart
class ProductsService extends AgBaseService
    with AgCrudService<Product, int>, AgPagedService<Product, int> {
  @override
  Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);

  @override
  Map<String, dynamic> toJson(Product item) => item.toJson();
}
```

Paste the response as it actually comes back — a list, or an envelope
like `{"data": [...]}`, are both understood. Nested objects become nested
classes, `snake_case` keys become `camelCase` fields (keeping the real
JSON key for encoding), and a `null` in the sample becomes `Object?`
rather than a guess the next payload contradicts.

The generated model is a plain Dart class — no `build_runner`, no
annotations, no part file to keep in sync. It's yours from the moment it
lands, and regenerating the module won't overwrite it.

`ag g m product --model=Product` names the type without inferring
fields, when you'd rather write them yourself.

For a detail module, the id travels in the URL as a string, so `idOf` is
generated with the conversion already written:

```dart
int idOf(ProductDetailsPageArgument argument) => int.parse(argument.id);
```

Delete whichever stubs a module doesn't need — they're not a mixin, not
framework-owned, just ordinary generated code. All three are named the
same across Service, Repo, and Controller, so a change reads the same at
every layer.

`AgCrudService` (in `ag_flow`) is a ready-made mixin implementing this
exact shape (`add`/`getAll`/`getById`/`update`/`delete`) against two
endpoints — a collection endpoint (`/products`) and an item endpoint
(`/products/{id}`) — if your Service fits it:

```dart
class ProductsService extends AgBaseService with AgCrudService<Product, String> {
  ProductsService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => ProductEndpoints.products;
  @override
  AgEndpoint get resourceEndpoint => ProductEndpoints.productById;
  @override
  Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);
  @override
  Map<String, dynamic> toJson(Product item) => item.toJson();
}
```

It's opt-in, never mandatory — a paginated list (like `products_service
.dart` above) needs a `getPage` the mixin doesn't provide, so it's
written by hand instead. Nothing in AG forces one fixed CRUD shape.

### Reflecting a mutation without a full refresh

After `add`/`update`/`delete`, the generated Controller calls
`refresh()` — a full re-fetch of page 1. If your backend has any
write-then-read lag (a demo API, eventual consistency, a mock server),
that won't show the change immediately. `AgListController` has an
escape hatch for exactly this:

```dart
Future<void> add(Product item) async {
  final created = await _repo.add(item);
  updateItems((items) => [created, ...items]);   // reflect it directly, no refetch
}
```

## 4. A detail module: `ag g m product/details`

```bash
ag g m product/details
```

```
create  lib/modules/product/repos/product_details_repo.dart
create  lib/modules/product/components/details/product_details_appbar.dart
create  lib/modules/product/components/details/product_details_loading.dart
create  lib/modules/product/components/details/product_details_error.dart
create  lib/modules/product/components/details/product_details_empty.dart
create  lib/modules/product/bindings/product_details_binding.dart
create  lib/modules/product/controllers/product_details_controller.dart
create  lib/modules/product/pages/product_details_page.dart
create  lib/modules/product/services/product_details_service.dart
update  lib/core/arguments/arguments.dart
update  lib/core/routes/app_routes.dart
update  lib/core/routes/app_pages.dart
update  lib/core/routes/route_management.dart

Generated 13 file(s) for product/details.
```

Requires `product` to already exist — a "details" screen only makes
sense as a child of something. Try it on a module that doesn't exist and
`ag` refuses, with the exact command to fix it, before writing anything.

Two things a detail module has that a collection module doesn't:

**A real URL.** The detail route is registered with a path parameter, so
the page has an address:

```dart
static const String productDetails = '/product/details/:id';
```

**A navigation argument** that travels *in* that URL. `ag g m` added this
to `lib/core/arguments/arguments.dart`:

```dart
class ProductDetailsPageArgument {
  const ProductDetailsPageArgument({required this.id});

  factory ProductDetailsPageArgument.fromPathParameters(
    Map<String, String> pathParameters,
  ) { /* ... reads pathParameters['id'] ... */ }

  final String id;

  Map<String, String> toPathParameters() => {'id': id};
}
```

Path parameters are always strings. If your module's id is an `int`, do
the conversion here — this class is the one place that knows the type:

```dart
factory ProductDetailsPageArgument.fromPathParameters(
  Map<String, String> pathParameters,
) => ProductDetailsPageArgument(productId: int.parse(pathParameters['id']!));
```

**A generated navigation method**, already wired to it:

```dart
static void goToProductDetailsPage(ProductDetailsPageArgument argument) {
  AgNavigator.toNamed<dynamic>(
    AppRoutes.productDetails,
    pathParameters: argument.toPathParameters(),
  );
}
```

Call it from anywhere — `RouteManagement.goToProductDetailsPage(
ProductDetailsPageArgument(id: product.id))` — and the argument arrives
at the controller already typed:

```dart
class ProductDetailsController extends AgDetailController<Product, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);
  final ProductDetailsRepo _repo;

  @override
  ProductDetailsPageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => ProductDetailsPageArgument.fromPathParameters(pathParameters);

  @override
  Future<Product> fetch() => _repo.getByArgument(arguments);
}
```

That `argumentsFromPath` override is what makes the page **deep-linkable**.
Because the id lives in the URL rather than in an in-memory payload,
`/product/details/42` opens the right product whether the user tapped a
list row, followed a push notification, scanned a QR code, or reloaded
the browser tab. An argument object passed in memory can't survive any of
those — there is nothing to pass when the app starts cold at that screen.

If you genuinely need to hand over something a URL can't express, pass it
as `extra:` and read it via `AgArguments.resolve<A>()` — but know that it
is null on a cold open, so it must never be the only way the page can
work.

There's no "empty" `_view.dart`/`_list.dart` split for the detail page's
actual content either — `buildSuccess` is inline, same as collection
modules, since there's nothing reusable to factor out of a single view:

```dart
@override
Widget buildSuccess(BuildContext context) {
  final data = controller.state.dataOrNull;
  return ProductDetailsView(product: data!);   // once you have a real view widget
}
```

### Nesting further

`ag g m product/details/reviews` works the same way, requiring
`product/details` to exist first. Class names are *fully cumulative*
(`ProductDetailsReviewsController`, not `ReviewsController`) — this is
what lets two different branches share a leaf name
(`product/pricing/details` and `product/shipping/details`) without
colliding in the shared, flat `controllers/` folder.

## 5. Regeneration is always safe

Run `ag g m product` again on a module that already exists:

```
Nothing to do — product already exists.
```

Every file, and every routes/pages/nav-method entry, is checked *by
name* before writing — never overwritten, never duplicated. If you've
hand-customized a navigation method (added a parameter, added a
`AgLocator.delete<...>()` side effect on the way out), it survives every future
regeneration byte-for-byte, no matter what else you generate afterward.

The one case that's a hard stop, not a silent no-op: if a route constant
already exists pointing at a *different* path than this module would
derive, `ag` reports a conflict and writes nothing, rather than guessing
which one you meant.

## 6. Keeping it honest: `ag analyze`

```bash
ag analyze
```

Checks your actual project against AG's rules and either prints
`No issues found.` or a list of concrete problems:

- a module missing one of its five layer files
- a route with no `AgRoute` entry, no nav method, or (for a detail route)
  no argument class
- two different route constants pointing at the same path
- a nested folder where one of the architectural folders must stay flat
- a hard-coded `AgNavigator.toNamed('/some/literal')` outside
  `route_management.dart` (always go through a generated `goToXPage(...)`
  instead)

Once your dependencies are resolved (`dart pub get` / `flutter pub get`
has been run), two more checks kick in automatically — these need a real
resolved type model, not just a syntax parse:

- **a Page reaching past its Controller** — straight into a Repo or
  Service, or any of `AgBaseRepo`/`AgBaseService`/`ApiProvider`/`Dio`
  directly
- **a detail controller that never reads its own `arguments`** — the
  navigation data that route exists to carry is going unused

Run it in CI. It's the same rules the generator itself follows, so drift
between "what the docs say" and "what the code actually does" gets
caught immediately instead of accumulating.

## 7. See it running

[`packages/ag_flow/example/`](packages/ag_flow/example) is a real,
generator-produced app in this repo — the exact output of `ag init` +
`ag g m product` + `ag g m product/details`, with only `lib/main.dart`
written by hand. If any of the above feels abstract, open it directly —
every file described in this guide exists there, unmodified from what
`ag` produced.

## Command reference

```bash
ag init                                 # once per project
ag g m <path>                           # generate a module ("g m" = "generate module")
ag g m <path> --plural=<word>           # override the default pluralizer for a root module
ag g m <path> --methods=add,update      # only these CRUD stubs (default: all; "none" for read-only)
ag g m <path> --dry-run                 # preview without writing anything
ag analyze                              # validate the current project
```
