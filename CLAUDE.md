# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Melos monorepo (native Dart pub workspaces) implementing **AG Flow** — an opinionated Flutter
framework + CLI. DI and rebuilds are owned in-house — no third-party state-management
dependency. Routing is AG's own API over **go_router**, the Flutter team's own package
(`flutter/packages`): that reintroduces a dependency, but not the problem the previous one had, and it
buys real URLs, deep links, web history, and correct system-back behaviour that AG would
otherwise have to maintain itself. Two packages:

- [packages/ag_flow](packages/ag_flow) — the runtime framework (`AgBasePage`, `AgBaseController`, etc.). Complete for the classes listed below.
- [packages/ag_flow_cli](packages/ag_flow_cli) — the `ag` generator CLI. `ag init` bootstraps a bare
  project's `lib/core/` skeleton, `ag g m <module>` works end-to-end from there (fresh-file generation
  *and* idempotent updates to the shared aggregator files), and `ag analyze` validates a project against
  AG's structural rules — both syntax-only checks and, once the project's dependencies are resolved,
  resolved-element-model checks (dependency-direction violations, unused detail arguments — see below).

The binding specification is [requirments/](requirments/) (`ag_framework.md`, `routes.md`,
`ag_endpoint_rules.md`) — precise, numbered rulesets. When extending either package, treat these as
authoritative; when they're ambiguous or self-contradictory (this has happened — see "Naming scheme"
below), resolve it explicitly and say so rather than guessing silently.

There's a detailed build plan with a phased roadmap; ask where it's tracked if you need the full history
of decisions behind what's built vs. not yet built.

## Commands

**Toolchain gotcha**: this repo is pinned via `.fvmrc` to a specific Flutter/Dart SDK (`fvm use` already
configured it — check `.fvmrc` for the exact version). Plain `dart`/`flutter` on `$PATH` may resolve to a
*different* installed version than the pinned one, which silently breaks anything version-sensitive
(globally-activated package snapshots in particular — see `mason` note below). Prefix commands with the
pinned SDK's `bin/cache/dart-sdk/bin` and `bin` dirs, e.g.:

```bash
export PATH="$(pwd)/.fvm/flutter_sdk/bin/cache/dart-sdk/bin:$(pwd)/.fvm/flutter_sdk/bin:$PATH"
```

Then, from the repo root:

```bash
dart pub get                                    # resolve the whole workspace (one shared lockfile)
dart analyze . --fatal-infos                    # analyzer respects each package's analysis_options.yaml excludes
melos run test                                  # flutter test (ag_flow) + dart test (ag_flow_cli)
```

**Formatting has no exclude mechanism** (unlike `dart analyze`) — `ag_flow_cli/bricks/**` contains
`{{mustache}}` template files that aren't valid Dart, so never run `dart format` (or `melos run
format-check`, which already does this correctly) against `.` or a whole package directory. Use the
explicit source-root list in the root `pubspec.yaml`'s `melos.scripts.format-check`, or when formatting a
single file/dir, avoid `bricks/`.

**`dart doc` must not be run through the FVM symlink.** `.fvm/flutter_sdk` is a symlink to the real SDK,
and dartdoc resolves its own SDK root from the running executable's path — through the symlink that
resolution yields null and it crashes with `type 'Null' is not a subtype of type 'String'` in
`DartdocOptionContext.sdkDir`, for every package, before documenting anything. It is an environment trap,
not a code problem: invoke the real SDK path instead (`~/fvm/versions/<version>/bin/dart doc`). The same
crash is why `pana` reports 0/10 for "20% or more of the public API has dartdoc comments" — the check
never runs. Actual state, measured that way: **0 dartdoc warnings, 0 errors**. A doc reference split
across two lines (`[AgListController\n/// .loadMore]`) does not resolve — keep each `[reference]` on one
line, the same hazard as a backtick span breaking across lines.

Single-test-file runs:

```bash
dart test packages/ag_flow_cli/test/src/generators/module_generator_test.dart   # ag_flow_cli
flutter test packages/ag_flow/test/page/ag_page_test.dart                        # ag_flow
```

**Editing `ag_flow_cli`'s Mason bricks**: editing anything under `bricks/*/​__brick__/` has *no effect*
until re-bundled — `ag_flow_cli` loads the committed `lib/src/templates/generated/*_bundle.dart` files at
runtime, not the brick sources directly:

```bash
dart pub global activate mason_cli   # once per machine — needs the pinned-SDK PATH prefix above too
cd packages/ag_flow_cli
mason bundle bricks/collection_module -t dart -o lib/src/templates/generated/
mason bundle bricks/detail_module -t dart -o lib/src/templates/generated/
```

## `ag_flow` architecture (runtime)

```
Page → Controller → Repo → Service → ApiProvider
```

**No third-party state-management dependency.** AG owns its DI, rebuild, and routing primitives outright
— `get` was removed entirely (see "Owned primitives" below). Everything else here is unchanged by that.

- **`AgBasePage<C extends AgBaseController>`** — one type parameter for *both* collection and detail
  pages (a deliberate deviation from the spec's literal 2-type-arg diagram for detail pages — Dart can't
  have one class name support two different generic arities. `C`'s own generics already carry the
  argument type for detail controllers, so nothing is lost). `controller` resolves from `AgLocator`,
  registered by the module's `AgBinding` when its route was pushed.
- **`AgBaseController<T>`** — page state via sealed `AgPageState<T>` (`initial/loading/success/empty/
  error`), not ad-hoc booleans. `AgPageSuccess`/`AgPageError` use deep equality (`package:collection`) so
  `T` being a `List`/`Map` of value objects compares by content, not identity. Extends Flutter's own
  `ChangeNotifier`; `emit()` is the single write path and the only caller of `notifyListeners()`.
  **`emit()` no-ops once `isDisposed`** — an in-flight `fetch()` routinely outlives its route (a user
  backing out mid-load is ordinary, not an edge case), and notifying a disposed `ChangeNotifier` throws.
  Covered by `test/controller/ag_controller_disposal_test.dart`; don't remove that guard.
  **Overlapping loads are settled by a request token** (`startRequest`/`isCurrentRequest`/
  `currentRequestToken`, all `@protected`). Two loads overlap in completely ordinary use — tapping retry
  twice, pulling to refresh while the first load is still running — and responses are not guaranteed to
  come back in the order they were sent. Without the token the *slower* request wins and silently
  replaces fresh data with stale data (or blanks a loaded screen with an abandoned request's error).
  `_runFetch` starts a new token; `AgPaginationMixin.loadMore` deliberately *captures* the current token
  without starting one, because a load-more continues the current load rather than replacing it — which
  is exactly what makes a `refresh()` invalidate an in-flight page instead of letting it append stale
  rows onto the refreshed list.
- **`AgListController<ItemType, PageKeyType>`** (`AgPaginationMixin`) — pagination/load-more state,
  tracked separately from page-level state (a load-more failure never corrupts `AgPageSuccess`) via its
  own `AgNotifier` (`paginationListenable`), so a pagination-only change never re-triggers `AgPage`'s
  loading/error/empty/success switch. Two distinct notifiers rather than one controller multiplexing
  rebuild groups by string id (what `GetBuilder(id:)` did) — two objects can't collide the way a typo'd
  id string silently could. Implement `fetchPage(key)` as
  a pure function; the mixin is the sole writer of pagination state — except via `updateItems`, an
  `emit()`-style `@protected` escape hatch for reflecting a mutation (add/update/delete against the Repo)
  in the currently-displayed list without a full `refresh()`. Needed for any backend that doesn't actually
  persist writes (a demo/mock API, or one with eventual-consistency lag) — `refresh()` re-fetching page 1
  would never show an item that was just "created". `AgCrudService` is a mixin, never mandatory: a list
  controller needing a `getPage` the mixin doesn't provide is free to hand-write its whole Service/Repo/
  Controller stack instead — AG never forces a fixed CRUD method set, not just as a doc-comment claim.
- **`AgListBuilder`** — internally `CustomScrollView` + `SliverList`, not `ListView`, behind the same
  external API (constructor/parameters unchanged) — chosen so it composes inside a larger sliver-based
  scroll view later without a breaking change. Separator interleaving (`separatorBuilder`) mirrors
  `ListView.separated`'s own technique exactly: double the child count, even indices are items, odd
  indices are separators (verified against the Flutter SDK's own `ListView.separated` source, not
  reinvented). Both this and `AgPage` take the controller *instance* directly and listen to it via
  `AgBuilder` — never a DI lookup by type, which matters for testability: every widget test constructs a
  controller directly, with nothing registered in `AgLocator` at all. Neither widget owns the
  controller's lifecycle (an `AgBinding` does), so neither disposes it on its own unmount — both may be
  reading the same instance within one page. **Scroll-driven load-more has three guards that all matter**
  (`test/list/ag_list_builder_test.dart`): it ignores notifications with `depth != 0` (a nested
  scrollable — a horizontal carousel inside a row — bubbles *its own* metrics up, and a short inner list
  always reads as "near the bottom", which would page the outer list while the user scrolls something
  else entirely); it re-checks `hasNextPage`/`isLoadingMore` synchronously rather than leaning on
  `loadMore`'s own guard, because this runs on every scroll frame and an async call allocates a Future
  each time even when it returns immediately; and it refuses to fire while `loadMoreError != null`, so a
  backend that is already failing isn't retried once per scroll frame — recovery is the deliberate
  `retryLoadMore()` from the error slot.
- **`AgPage`'s refresh bar is slotted into an unconditional `Stack`** (`StackFit.passthrough`), not
  wrapped around the content only while refreshing. Moving the success content between "direct child"
  and "child of a Stack" changes the widget type at that slot, so Flutter re-inflates the whole subtree:
  a scrolled list lost its `ScrollPosition` and jumped back to the top on *every* refresh, and the
  content was laid out under loose constraints mid-refresh and tight ones otherwise. Holding the shape
  fixed keeps the element in place; `passthrough` keeps the constraints identical to being a direct
  child. Covered by `test/page/ag_page_test.dart`.
- **`AgDetailController<T, A>`** — adds `late final A arguments`, resolved via `AgArguments.resolve<A>()`
  (throws a named `AgArgumentError`, never a bare cast failure).
- **Services are declarative, and that's load-bearing.** A Service should contain *no* request
  plumbing — no query-param building, no decoding, no `hasMore` arithmetic. Everything that differs
  between backends is a **value it declares**, so every Service in every module reads the same way:
  - **`AgPageStrategy<K>`** — the paging dialect: `AgPageNumberStrategy` (`?page=1&limit=20`),
    `AgOffsetStrategy`, `AgCursorStrategy` (opaque token read from beside the payload), and
    `AgSinglePageStrategy` for a backend that returns everything at once. That last one is
    deliberately first-class rather than something each app hand-codes — it's what keeps a
    non-paginating backend on the identical Service shape as a paginating one.
  - **`AgEnvelope`** — where the payload sits in a response body: `raw` (the body is it),
    `AgEnvelope.key('data')`, `AgEnvelope.path([...])`, or `custom`. A mismatch throws
    `AgEnvelopeException` naming the fix, never an opaque cast failure inside a decode callback.
  - **`AgPagedService<T, K>`** implements `getPage` once, from those two values. Its absence was the
    original consistency hole: with no framework-owned paging, every paginated collection fell out of
    the declarative shape and hand-rolled its own plumbing, so no two modules looked alike. Composes
    with `AgCrudService` — both declare `collectionEndpoint`/`fromJson`, satisfied once by the class
    (verified: mixing both compiles with no override conflict).
  - **`AgBaseService.fetchList`/`fetchItem`/`decodeListPayload`/`decodeItemPayload`** cover the
    feature-specific reads no mixin can anticipate (`getByCategory`, `search`, ...), so even those
    stay one declarative line and decode through the same envelope. Without them, bespoke methods
    re-implement unwrapping by hand and modules drift apart exactly where the framework stops looking.
  - The two showcase apps are the proof: `showcase/blog` (jsonplaceholder, `?_page`/`_limit`, bare
    array) and `showcase/store` (fakestoreapi, no pagination at all) have byte-for-byte the same
    Service *shape*; the entire difference is which `AgPageStrategy` each names.
- **`AgBaseRepo`** / **`AgBaseService`** (`AgCrudService<T, ID>` opt-in mixin) — no `Impl` classes.
  `AgCrudService` needs *two* endpoints, not one: `collectionEndpoint` (no path parameter — `getAll`/`add`)
  and `resourceEndpoint` (one `{id}` parameter — `getById`/`update`/`delete`). A single shared endpoint
  can't serve both correctly: `AgPathResolver.resolve` only checks that every `{token}` *in the template*
  has a supplied value, never that a supplied value corresponds to a token that exists in it — so an
  `{id}`-shaped endpoint throws on every `getAll`/`add` call (missing `{id}`), while a collection-shaped
  endpoint silently drops the id on every `getById`/`update`/`delete` call instead of ever reaching the
  right URL.
- **`ApiProvider`** — wraps `dio` directly; dio types never leak past it (`AgRequest` in,
  `AgResponse`/`AgApiException` out, `AgCancelToken` — not dio's own `CancelToken` — for cancellation).
  `AgEndpoint` is immutable/`const`-friendly (which is *why* `AgHttpMethod` has no custom `==` — Dart
  forbids custom-equality types as `const` set elements, and `AgEndpoint.methods` needs to be a `const`
  default). `AgEndpoint.baseUrlOverride` is wired by concatenating it directly onto the resolved path and
  passing that as dio's `path` argument — dio treats a path starting with `http(s)` as absolute and
  ignores its own configured `baseUrl` entirely, so no per-call dio reconfiguration is needed. The logging
  interceptor includes the query string in every log line (`ag_endpoint_rules.md` §23) and masks
  configured body keys at every nesting depth, not just the top level (§24). `AgRequest`'s contract checks
  (unsupported method, body+form-data together) are real exceptions, not `assert` — those must still be
  caught in release builds.

### Owned primitives (`src/di/`, `src/state/`, `src/navigation/`)

Three concerns live here — DI, rebuild plumbing, routing. DI and rebuilds are AG's own; routing is AG's
own *API* over go_router. They are deliberately three separate primitives rather than one god object;
that split is the point, and it is what made swapping the routing engine a contained change rather than
a rewrite.

- **`AgLocator`** (DI) — `put`/`lazyPut`/`find`/`delete` over a `Map<Type, Object>` plus a
  `Map<Type, Object Function()>` of pending factories. No tags, no scoping, no `fenix` — AG never used
  them. **`delete` disposes a realized `ChangeNotifier` before dropping it**; without that, every popped
  route leaks its controller's listeners. **`put` disposes the instance it replaces** for the same
  reason — the moment the new one is stored, the old one is unreachable through the locator, so anything
  still listening to it leaks for the rest of the app run. `find` on an unregistered type throws a named `StateError`
  naming the type, never a null-deref. An instance implementing `AgInitializable` gets `onAgInit()` called
  the moment it's realized — that's how a controller auto-starts `loadInitial()` without `AgLocator`
  knowing anything about controllers.
- **`AgBuilder` / `AgNotifier`** (rebuilds) — `AgBuilder` is a thin, consistently-named wrapper over
  Flutter's own `ListenableBuilder`. `AgNotifier` exists only because `ChangeNotifier.notifyListeners` is
  `@protected`: `AgPaginationMixin` holds a *separate* notifier instance and must fire it from outside.
- **`AgApp` / `AgRoute` / `AgShellRoute` / `AgBinding` / `AgNavigator` / `AgGuard` / `AgTransition`**
  (routing) — `MaterialApp.router` over a `GoRouter` that `AgApp` builds from `AgRoute`s. go_router is
  an *implementation detail*: it appears in no consuming app's pubspec and in no generated file, so the
  framework keeps owning the abstraction. What each AG piece maps onto:
  - **`AgRoute.path` is both the URL and the route's identity.** It is registered with go_router as
    `path` *and* as `name`, which is what keeps one `AppRoutes` constant per module — the generator
    writes it, `AgNavigator` is given it, and `ag analyze` validates it, all as the same string. A
    detail module's path declares a parameter (`/product/details/:id`), which is what makes the page
    reachable from a link and not only from an in-app push.
  - **`AgGuard` → `GoRoute.redirect`.** Guards run in order and the first non-null path wins; a blocked
    route is never built, so its binding never registers. The `path` a guard receives is the route
    *template*, so it compares directly against the `AppRoutes` constant.
  - **`AgShellRoute` → `ShellRoute`**, for persistent chrome (bottom nav, rail). Its binding is tied to
    the shell's own lifetime via a small `StatefulWidget` scope, not to any one route inside it.
  - **`AgNavigator.offNamed` uses `pushReplacement`, never go_router's `replace`.** Verified by probe,
    and the distinction is not cosmetic: `replace` reuses the outgoing page's key, so Flutter *updates*
    the existing route instead of creating a new one — `createRoute` never runs, `dispose` never runs,
    the new page's binding is never registered, the old one is never released, and the route keeps
    rendering the previous page's content. Don't "simplify" this to `replace`.
  - **`toNamed` is a push and deliberately does not change the URL** (go_router's own semantics for an
    imperative push); `offAllNamed` is a `go` and does. `toLocation` exists for raw inbound links.

  Two non-obvious invariants, each a real bug found by probing rather than assumed away — both have
  regression tests in `test/navigation/ag_app_test.dart`:
  - **Binding teardown is reference-counted.** `AgLocator` is type-keyed, so one type has at most one
    live instance, so two stacked pushes of the same route legitimately *share* one controller. Tearing
    down on the first pop would leave the instance still on the stack holding a disposed controller.
  - **Teardown fires from the route's own `dispose`, never from a `NavigatorObserver`.** This replaced an
    earlier design that released bindings from `didPop`/`didRemove`/`didReplace`, and it fixed a real
    defect rather than just tidying: an observer's `didPop` fires when the pop *begins*, while the
    outgoing page is still mounted and still reading its controller for the length of the exit
    transition — so teardown there disposes a controller out from under a live widget. `Route.dispose`
    runs once the route is genuinely gone. It also collapses three callbacks into one path and covers a
    case none of them did: the navigator itself being torn down with routes still on the stack.
    `_AgPage` (a `Page` whose `createRoute` acquires the binding) plus `_AgPageRoute` (a
    `PageRouteBuilder` whose `dispose` releases it) is the whole mechanism — and it survived the move to
    go_router unchanged, because go_router builds pages through `pageBuilder` and lets the `Page` decide
    what `Route` to create. Don't "simplify" this back to an observer.

  **Known limitation, pre-dating go_router and not introduced by it**: `AgLocator` is keyed by type, so
  two live instances of the same route *share one controller*. Pushing `/product/7` and then
  `/product/9` shows product 7's data on both, and popping back does not restore the first. The same was
  true of the old argument-object mechanism; path parameters only make it easier to see. Fixing it
  properly means per-route scoping in `AgLocator` (registrations keyed by the route instance that made
  them, with `find` resolving in the current route's scope and falling back to the global one) — a real
  design change, deliberately not bundled into the routing migration.

**`packages/ag_flow/example/`** is entirely `ag_flow_cli`-generated, not hand-wired — `ag init` +
`ag g m product` + `ag g m product/details`, with only `lib/main.dart` written by hand (the
`AgApp` wiring `ag init`'s own printed next-steps describe). It's a real Melos workspace member
(`resolution: workspace` in its `pubspec.yaml`, listed in the root `pubspec.yaml`'s `workspace:` array),
which is exactly what caught two real bugs no isolated test fixture would have:
- **`ProjectAnalyzer.dependenciesResolved` only ever checked `<project root>/.dart_tool/package_config
  .json`.** For a *workspace member* — this example included — that file only ever exists at the
  workspace *root*, never duplicated into each member, so `ag analyze` run from inside
  `packages/ag_flow/example` always silently skipped the resolved-model checks, even with dependencies
  fully resolved. Fixed with `package:package_config`'s `findPackageConfig` (walks up parent directories
  the same way real Dart tooling resolves package configs for workspace members), added as a direct
  dependency for exactly this.
- **`very_good_analysis` (this example's own dev dependency, matching the root's) flags generated code
  that a bare-pubspec test fixture never exercises against any lint config at all**: required named
  constructor params declared after optional ones (`always_put_required_named_parameters_first` — bricks
  fixed to put `required` params first), and `AgNavigator.toNamed(...)`'s untyped generic call
  (`inference_failure_on_function_invocation` — `route_management_updater.dart` fixed to emit
  `AgNavigator.toNamed<dynamic>(...)`). Three more lints don't fit generated/aggregator-file conventions at all —
  `flutter_style_todos` (generated TODOs have no real author to attribute), `always_use_package_imports`
  and `discarded_futures` (both inherent to `core/routes/*.dart`'s deliberate relative-sibling-import and
  fire-and-forget-navigation conventions, not violations) — disabled with a rationale comment in the
  example's own `analysis_options.yaml`, not papered over by weakening the shared root config every other
  package also uses.

## `ag_flow_cli` architecture (generator)

- **Naming** (`lib/src/naming/`): fully cumulative class/route naming (`product/details/reviews/comments`
  → `ProductDetailsReviewsComments*`) — confirmed over the spec's own inconsistent root+leaf examples,
  because cumulative is collision-safe in the flat per-layer folders (two branches sharing a leaf segment
  name can't collide) and root+leaf isn't. **Root-module asymmetry**: a root module's five layer
  files/classes get pluralized (`product` → `Products*`/`products_controller.dart`), but its *components*
  and the module's raw file base never do (`components/product/product_card.dart`, not `products_card
  .dart`) — this is why `ModuleSpec` exposes both `classPrefix`/`layerFileBase` (pluralized) and
  `componentClassPrefix`/`fileBase` (never pluralized), not one pair.
- **Every generated module lives under a shared `lib/modules/` parent** — `lib/modules/product/...`,
  `lib/modules/auth/...` — sitting alongside (never inside) `lib/core`. This is filesystem organization
  only: route paths, class names, and every naming derivation above are unaffected — `ModulePath
  .rootSegment` is still the bare segment (`product`), never `modules/product`. The one place that
  distinction matters is package-import construction: `Project.moduleRootDir` is the single source of
  truth for the on-disk path, and `module_import_path` (`ModuleGenerator`'s vars map, and
  `AggregatorUpdater`'s call into `updateAppPages`) is the single source of truth for the
  `modules/<root>` segment every generated `package:<app>/...` import is built from. **Mason's default
  `{{var}}` interpolation HTML-escapes its value** — a real, empirically-found bug: `{{module_import_path}}`
  rendered `modules/product` as `modules&#x2F;product` in every brick-templated import line, since Mason's
  Mustache engine escapes `/` the same way it escapes `<`/`>`/`&`. Every other brick var was a bare
  PascalCase/snake_case identifier with no special characters, so this never surfaced before
  `module_import_path` introduced the first var whose value contains a `/`. Fixed by switching to
  unescaped triple-mustache (`{{{module_import_path}}}`) at every one of its use sites in the bricks.
- **Templates** (`bricks/`, bundled to `lib/src/templates/generated/`): two Mason bricks,
  `collection_module` and `detail_module`, each generating a full file set for their module type in one
  `mason make`-equivalent call — not one brick per layer, since every layer's content differs between
  collection and detail anyway (conditionals-per-file would've been more, not less, complexity than two
  full brick sets). Generated code uses `package:<app_package_name>/...` imports throughout — never
  relative — resolved from the *target* project's own `pubspec.yaml`. `tool/check_bundles_fresh.dart`
  (wired into CI via `melos run check-bundles-fresh`) decodes every committed bundle's base64 file data
  and byte-compares it against the corresponding file under `bricks/<name>/__brick__/` — an edited brick
  source has no other build-time signal that it's stale, since the bundle is plain committed Dart, not
  derived at build time. Service/Repo/Controller each generate `add`/`update`/`delete` stubs by default
  (matching the always-present read method's own `UnimplementedError`-placeholder shape exactly), gated
  per-method by `{{#generate_add}}`/`{{#generate_update}}`/`{{#generate_delete}}` Mustache conditional
  sections — verified empirically against Mason's real bundle→generate pipeline (boolean vars, section
  rendering, and `DartFormatter` cleanly collapsing the sections' blank-line artifacts) before being
  relied on, since every other var in these bricks had only ever been flat string substitution. `add` is
  declared only in `collection_module/brick.yaml` — a detail module's `brick.yaml` has no `generate_add`
  var at all, so `ModuleGenerator` passing that key unconditionally in its vars map (matching the
  pre-existing pattern of passing every var to both bundles regardless of which brick uses it) is a
  harmless no-op there, not a validation error. All three stubs keep the same name across Service, Repo,
  and Controller. (`AgBaseController` extends `ChangeNotifier`, which declares no `update`, so the
  Controller's stub is plainly named `update` — take care not to confuse it with
  `AgPaginationMixin.updateItems`, one character apart.)
  - **Page-level chrome slots each get their own component file; the success content stays in the page.**
    `appBar`, `loadingBuilder`, `errorBuilder`, and `emptyBuilder` each get a dedicated file under
    `components/<namespace>/` (`_appbar.dart`, `_loading.dart`, `_error.dart`, `_empty.dart`), generated
    and linked into the page automatically. `buildSuccess` is deliberately *not* one of these — an earlier
    version of this also split the success content into its own `_list.dart`/`_view.dart` component, but
    that file was never a reusable widget the way a card or an app bar is: it was just *this page's own
    body*, wrapped in an extra class for no reason. `buildSuccess` stays inline in the page — for a
    collection module, directly constructing `AgListBuilder<dynamic, int>` with an `itemBuilder` that
    references the one genuinely reusable piece, `{{component_class_prefix}}Item` (a real per-row
    component); for a detail module, the same inline placeholder (`Center(child: Text(data.toString()))`)
    it always was. `AppBar` is subclassed directly, not wrapped by composition, since
    `AgBasePage.appBar()` already returns `PreferredSizeWidget?` and `AppBar` already *is* one — note its
    constructor isn't `const` in the pinned Flutter version, so neither is the generated subclass's. Every
    chrome component is a plain, fully-owned starting point: delete one and its one-line reference in the
    page to fall back to `AgBasePage`'s own default for that slot.
- **Typed models (`--model` / `--from-json`)** close the generator's largest remaining gap: without one,
  a generated module hands back **17 `dynamic` placeholders across 5 files** for the developer to find and
  replace, which is the opposite of the stated goal. `ModelSpec` (`lib/src/naming/model_spec.dart`) infers
  fields from a real JSON sample and `renderModel` (`lib/src/generators/model_generator.dart`) emits a
  plain data class — no `build_runner`, no annotations, no part file to keep in sync. The model type is
  then threaded through Service, Repo, Controller, Page and the item component via the `model_class` /
  `id_type` / `has_model` brick vars.
  - **The feature is strictly additive.** With no model the vars default to `model_class: dynamic`,
    `id_type: Object`, `has_model: false`, and the output is what it always was — the golden files prove
    it. (One deliberate improvement came with it: the Repo/Controller's `id` parameter went from `dynamic`
    to `Object`, which is what the Service's `AgCrudService<dynamic, Object>` had always declared. They
    previously contradicted each other.)
  - **A detail module reuses its root's model**, never its own last segment — `product/details` gets
    `Product`, not a second `Details` class. Same reasoning as the flat per-root layer folders.
  - **Path parameters are always strings, so `idOf` is generated with the conversion already written**
    (`int idOf(...) => int.parse(argument.id)`). That single line is the thing a developer would otherwise
    forget on every detail module.
  - **Envelope unwrapping is a fixed key list** (`data`, `result`, `results`, `payload`, `response`,
    `content`, `records`, `rows`), never "any single-key object". `{"rating": {...}}` is a one-field model,
    not an envelope, and shape alone cannot tell them apart — guessing would silently model the wrong
    object. Found by a test, not by reasoning about it afterwards.
  - **`double` decodes through `num`** (`(json['x'] as num).toDouble()`): JSON sends `10`, not `10.0`, for
    a conceptually-double field whenever the sampled value happened to be whole, and `as double` throws on
    it. A `null` in the sample yields `Object?` rather than a guessed type that the next payload
    contradicts.
- **`ModuleGenerator.plan()`** never writes to disk directly — it renders via an in-memory
  `GeneratorTarget`, formats with `DartFormatter`, checks existence, and returns `FileOp`s (`create` /
  `update` / `skipExisting`) for an `Executor` to apply (or, under `--dry-run`, just report). This is what
  makes generation idempotent and the generator unit-testable without a filesystem.
- Parent-existence check (child modules) looks for the parent's controller file under the shared root's
  flat `controllers/` folder — not for a directory matching the child's own path (there isn't one).
- **Aggregator-file updates** (`lib/src/generators/{arguments,app_routes,app_pages,route_management}
  _updater.dart`, orchestrated by `aggregator_updater.dart`): offset-splice AST editing via
  `package:analyzer`'s syntax-only `parseString` (no resolution needed or wanted — see below), computed as
  `Patch(offset, end, text)` values applied in descending-offset order, then the whole file is reformatted.
  Each updater checks for an existing entry **by name only** before inserting — never by comparing or
  replacing a body — which is exactly how a hand-customized `goToLoginPage` survives regeneration forever
  (requirments/routes.md §19). `RouteConflictException` is the one case that *isn't* a safe no-op:
  re-deriving the exact same module is idempotent, but finding an existing route constant of the same name
  pointing at a *different* path is a genuine conflict (routes.md §21) and aborts before writing anything.
  - **A bare `Foo(...)` call parses as `MethodInvocation`, not `InstanceCreationExpression`.** This is the
    one real bug this design produced and a debug script caught immediately: `parseString` only parses
    syntax, and disambiguating "constructor call" from "function call" for an unprefixed identifier
    requires semantic resolution, which offset-splice editing deliberately never does. `AgRoute(...)` in
    `app_pages_updater.dart` is matched as `MethodInvocation` for exactly this reason — don't
    "fix" that back to `InstanceCreationExpression`.
  - **`ClassDeclaration` doesn't have `.name`/`.members` directly in the pinned analyzer version** — it's
    `classDecl.namePart.typeName.lexeme` for the name and `classDecl.body.members` for the member list
    (`ClassBody`, a wrapper introduced for Dart's class-modifiers/augmentation support). This surprised
    every updater's first draft; if a future analyzer major changes this shape again, re-verify against
    the pinned version's actual docs before assuming either the old or new shape.
  - **Import sorting must be group-aware** (`sortImports` in `import_utils.dart`): `dart:` / `package:` /
    relative, each alphabetical within its group, one blank line between groups — a flat alphabetical sort
    would put a relative import like `app_routes.dart` before any `package:` import purely on the letter
    "a" vs. "p", which is wrong. Needed because whether `package:flutter/...` sorts before or after the
    consuming app's own package name depends on that name, so static template ordering can't get it right
    for every consumer, and inserting a new import at a fixed anchor point isn't where it alphabetically
    belongs.

- **`ag init`** (`lib/src/generators/init_generator.dart`): scaffolds the 6-file `lib/core/` skeleton
  (`arguments.dart`, `endpoints.dart`, `routes/{app_routes,app_pages,route_management}.dart`,
  `bindings/initial_binding.dart`) via the same `FileOp`/`Executor` boundary as `ag g m` — each file is
  `create`d only if missing, `skipExisting` otherwise, so re-running `ag init` (or running it after a
  developer has already hand-edited one of those files) is a pure no-op, never an overwrite. Deliberately
  *not* a Mason brick like the module generators: these are fixed, parameter-free skeletons with no
  per-invocation variables to template, so a brick would add indirection without buying anything.
  `endpoints.dart`'s skeleton is comment-only guidance (endpoints are hand-authored, grouped by backend
  domain — never auto-updated by `ag g m`, see below). Verified end-to-end against a real `flutter
  create`d app (not just the bare-pubspec test fixtures): `ag init` → `ag g m product` → `ag g m
  product/details` → `flutter pub get` → `flutter analyze --fatal-infos` reports zero issues, and
  re-running all three `ag` commands a second time is a confirmed no-op.
- **`ag init` scaffolds the architecture standard alongside the code** — `AGENTS.md` (the layer contract,
  folder rules, generator commands and prohibitions), `CLAUDE.md` (a pointer to it, never a second copy),
  `.github/workflows/ag.yaml` and an opt-in `.githooks/pre-commit`. The reasoning is that an agent which
  already knows the standard uses `ag g m` instead of inventing a module layout — which is both more
  consistent and far cheaper, since one command replaces ~14 hand-written files. Instructions alone are
  advisory, so the CI workflow and hook run `ag analyze` as the actual gate. **The hook resolves the CLI
  through the project's own `ag_flow_cli` dev_dependency before anything on `PATH`** — a real bug found by
  running it: a globally-activated, unrelated `ag` shadowed the project's, and its missing `analyze`
  command surfaced as a bogus "architecture violation". A missing tool is reported as a missing tool and
  skips, never as a violation; CI is the authoritative gate and always has the dependency.
- **`ag analyze`** (`lib/src/analyze/`): a structural validator combining two tiers. The **syntax-only
  tier** (no resolved element model, `parseString` throughout, same as the generators) reads every route
  out of `_Routes` in `app_routes.dart` (`route_table.dart`), then re-derives each route's expected
  `ModuleSpec` **from its route path**, not from its constant name — the route path is always the raw,
  never-pluralized segment join (`ModuleSpec.routePath`), so it round-trips through `ModulePath.parse`
  losslessly regardless of which pluralizer (or `--plural=` override) produced the constant's *name*. This
  is what lets the checks reuse the exact same naming machinery the generators use instead of inventing a
  second, possibly-diverging derivation. Five rule categories: missing layer file, missing route wiring
  (`AgRoute` entry/nav method/argument class — matched via the identical AST predicates the updaters already use,
  see `app_pages_updater.dart`'s `alreadyRegistered` check), duplicate route (two different constants
  resolving to the same path — the mirror image of the generator's own same-name-different-path conflict
  check), nested architectural/component folders, and hard-coded route strings (`AgNavigator.toNamed('/literal')`
  outside `route_management.dart` — matched with a `RecursiveAstVisitor`, verified empirically to walk
  arbitrarily nested call sites correctly before being relied on).
  - **Known limitation**: a module generated with a custom `--plural=` override has no record of that
    override anywhere `ag analyze` can read back, so its re-derivation (which always uses the *default*
    pluralizer) can produce a false "missing layer file" positive. Documented, not silently swallowed.
  - The **resolved-model tier** (`dependency_direction_check.dart`, `detail_argument_usage_check.dart`)
    uses `package:analyzer`'s `AnalysisContextCollection` — a real resolved element model, verified via a
    small spike script before being relied on (`InterfaceType.element.allSupertypes`,
    `SimpleIdentifier.element.enclosingElement`, both against the pinned analyzer version's actual classic
    — not `element2`/`element3` — element API). Dependency-direction violations are matched against a
    referenced type's *full supertype chain*, not just its own name, so a concrete `ProductsRepo extends
    AgBaseRepo` is caught the same way a raw `AgBaseRepo` reference would be. This tier only runs when
    `ProjectAnalyzer.dependenciesResolved` is true (`.dart_tool/package_config.json` exists) — skipped, not
    failed, otherwise, with `AnalyzeCommand` printing a notice; every syntax-only check still runs
    regardless. Verified via `dart run` and a real `dart pub global activate`-installed `ag`; a standalone
    `dart compile exe` build does *not* work for this tier — `AnalysisContextCollection`'s default SDK
    detection derives the SDK root from `Platform.resolvedExecutable`, which for a compiled native binary
    is the binary itself, not a path inside a real SDK tree — not fixed, since `dart compile exe` isn't a
    documented distribution method for this CLI. `ProjectAnalyzer.analyze()` is `async` for this reason.
  - Exit codes follow this repo's existing convention (`ExitCode.software` for "the target project has a
    structural problem," reused from `RouteConflictException` in `module_command.dart`): 0 with no issues,
    70 with any.

## Known deferred work (not bugs — see the build plan for phase boundaries)

- `endpoints.dart` is deliberately never auto-updated by `ag g m` (endpoints are grouped by backend
  domain, not frontend module hierarchy — ag_endpoint_rules.md §5).
