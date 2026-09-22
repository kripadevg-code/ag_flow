# Changelog

## Unreleased

- **Routing now runs on `go_router`.** AG keeps owning the API — `AgApp`,
  `AgRoute`, `AgBinding`, `AgNavigator`, `AgGuard` are unchanged in
  spirit, and go_router appears in no consuming app's pubspec and in no
  generated file — but the engine underneath is the Flutter team's own
  package rather than a hand-rolled `onGenerateRoute`. That reintroduces
  a dependency, though not the one that motivated dropping GetX: this one
  is maintained in `flutter/packages`.
  - **Routes are real URLs.** `AgRoute.name` became `AgRoute.path`, and a
    path may declare parameters: `/product/details/:id`. The path is
    registered as go_router's `path` *and* `name`, so there is still
    exactly one `AppRoutes` constant per module.
  - **Detail pages are deep-linkable.** A detail module's argument is now
    built from the route's path parameters via
    `AgDetailController.argumentsFromPath`, so the page opens correctly
    from a notification, a shared link, or a reloaded web URL — not only
    from an in-app push. `AgNavigator.extra` still carries a payload that
    genuinely cannot be expressed in a URL, and is documented as not
    deep-link safe.
  - **`AgShellRoute`** wraps a group of routes in persistent chrome (a
    bottom bar, a rail) whose own state survives navigation between them.
    Its binding is scoped to the shell's lifetime, not to any one route.
  - **`AgGuard` now maps onto go_router's `redirect`** — guards still run
    in order with the first non-null path winning, but a blocked route is
    never built at all, so its binding never registers.
  - **`AgNavigator`** gains `pathParameters`/`queryParameters`, `canPop`,
    `location`, and `toLocation` for raw inbound links. `offNamed` uses
    `pushReplacement`, never go_router's `replace` — `replace` reuses the
    outgoing page's key, which would leave the binding lifecycle unrun
    and the route rendering the previous page's content.
  - **Unmatched locations** land on `AgApp.errorBuilder` instead of
    silently doing nothing.
  - The binding lifecycle is unchanged and still reference-counted, still
    driven by the route's own `dispose` — it survived the migration
    because go_router lets a `Page` decide which `Route` to create.

### Known limitation (pre-existing, not introduced here)

`AgLocator` is keyed by type, so two live instances of the same route
share one controller: pushing `/product/7` then `/product/9` shows the
first product's data on both. This was equally true of the old
argument-object mechanism; path parameters only make it easy to see.
Fixing it properly needs per-route scoping in `AgLocator`.

- **Six production defects fixed in the state, DI, and routing
  primitives** — each one found by writing a test that reproduced it
  first, not by reading the code and guessing. All six have permanent
  regression tests.
  - **`AgLocator.put` leaked the instance it replaced.** Registering over
    an existing type dropped the previous instance without disposing it,
    so anything still listening to it leaked for the rest of the app run.
    It is now disposed as it is replaced (unless it is literally the same
    instance).
  - **Out-of-order responses let stale data win.** Two loads overlapping
    is ordinary use — tapping retry twice, or pulling to refresh while
    the first load is still running — and nothing orders the responses.
    The *slower* request used to win and silently overwrite fresh data
    with stale data; an abandoned request failing could also blank out an
    already-loaded screen. `AgBaseController` now stamps each load with a
    request token and discards anything superseded.
  - **A refresh during an in-flight `loadMore` spliced stale rows into
    the fresh list.** The in-flight page belonged to the list as it was
    *before* the refresh. It is now dropped, and it no longer leaves a
    load-more spinner stuck on screen.
  - **Controllers were disposed mid-pop-transition.** Binding teardown
    ran from a `NavigatorObserver`'s `didPop`, which fires when the pop
    *begins* — the outgoing page is still mounted and still reading its
    controller for the whole exit animation. Teardown now runs from the
    route's own `dispose`, once the route is genuinely gone. This also
    covers a case the observer never did: an app torn down with routes
    still on the stack.
  - **A nested scrollable paged the list it was sitting inside.** A
    horizontal carousel inside a row bubbled its own scroll metrics up to
    the outer list, and a short inner list always reads as "near the
    bottom" — so scrolling the carousel loaded page after page of the
    outer list. Only the list's own scrollable is considered now.
  - **A failed page retried itself on every scroll frame.** After a
    load-more failure, continuing to scroll re-issued the same failing
    request ~60 times a second. The error is latched; recovery is the
    deliberate `retryLoadMore()` from the error slot.
- **Refreshing no longer throws a scrolled list back to the top.**
  `AgPage` used to wrap the success content in a `Stack` only while
  refreshing, which changed the widget type at that slot and re-inflated
  the whole subtree — losing the `ScrollPosition` on every single
  refresh, and laying the content out under different constraints
  mid-refresh. The `Stack` is now unconditional with
  `StackFit.passthrough`, so the element stays put and the constraints
  are identical to being a direct child.
- **`AgApp` is simpler as a result of the teardown fix**, not just
  more correct: one release path via a `PageRouteBuilder` subclass
  replaces three `NavigatorObserver` callbacks and the `Route`-keyed map
  that existed only to correlate them back to bindings.

- **Services are declarative now — backend differences are values, not
  code.** Previously `AgCrudService` had no `getPage`, so the moment a
  backend paginated, a module fell out of the declarative shape and
  hand-wrote its own query params, decoding, and `hasMore` arithmetic.
  That was the single largest source of inconsistency between modules:
  every paginated collection encoded its backend's quirks in imperative
  code that looked different everywhere. Three new pieces close it:
  - **`AgPageStrategy<K>`** — a backend's paging dialect as a declared
    value: `AgPageNumberStrategy`, `AgOffsetStrategy`, `AgCursorStrategy`,
    and `AgSinglePageStrategy` for backends that return everything at
    once. That last one is first-class on purpose: it keeps a
    non-paginating backend on the identical Service shape as a
    paginating one.
  - **`AgEnvelope`** — where the payload sits in a response body (`raw`,
    `.key('data')`, `.path([...])`, `.custom`). A mismatch throws
    `AgEnvelopeException` naming the fix rather than failing as an opaque
    cast inside a decode callback.
  - **`AgPagedService<T, K>`** — implements `getPage` once from those two
    values. Composes with `AgCrudService`; both declare
    `collectionEndpoint`/`fromJson`, satisfied once by the class.
- **`AgBaseService` gained `fetchList`/`fetchItem` (and the underlying
  `decodeListPayload`/`decodeItemPayload`)** so the feature-specific reads
  no mixin can anticipate — `getByCategory`, `search`, a nested
  collection — are also one declarative line decoding through the same
  envelope. `AgCrudService`'s own five methods were rewritten onto them,
  so every read in the framework now unwraps identically.

- **Removed the GetX dependency entirely.** `ag_flow` no longer depends on
  `get` — DI, rebuild plumbing, and routing are all AG's own now, built on
  Flutter SDK primitives (`ChangeNotifier`, `ListenableBuilder`,
  `Navigator`). Deliberately three separate primitives rather than one
  `Get`-style god object:
  - **`AgLocator`** replaces `Get.put`/`lazyPut`/`find`/`delete` — a
    type-keyed registry with no tags, scoping, or `fenix` (AG never used
    them). `find` on an unregistered type throws a named `StateError`
    naming the type. An `AgInitializable` instance gets `onAgInit()` the
    moment it's realized, which is how a controller auto-starts its load
    without `AgLocator` knowing what a controller is.
  - **`AgBuilder`/`AgNotifier`** replace `GetBuilder`. `AgBaseController`
    now extends `ChangeNotifier`; `AgPaginationMixin` owns a *separate*
    notifier (`paginationListenable`) so pagination changes never
    re-trigger `AgPage`'s state switch. Two distinct objects rather than
    one controller multiplexing rebuild groups by string id — two objects
    can't collide the way a typo'd id silently could.
  - **`AgApp`/`AgRoute`/`AgBinding`/`AgNavigator`/`AgTransition`** replace
    `GetMaterialApp`/`GetPage`/`Bindings`/`Get.toNamed`/`Transition`.
    Context-less navigation goes through a `GlobalKey<NavigatorState>` —
    the same technique GetX used internally.
- **Fixed three real lifecycle defects found by probing the new
  primitives before trusting them** (all now regression-tested):
  - `AgLocator.delete` dropped a controller's reference without disposing
    it, leaking its listeners on every popped route. It now disposes any
    realized `ChangeNotifier` — GetX did the equivalent via `onClose`, and
    losing that silently was the biggest risk in replacing it.
  - `emit()` after disposal threw "was used after being disposed". An
    in-flight `fetch()` routinely outlives its route — a user backing out
    mid-load is ordinary, not an edge case — so `emit()` (and the
    pagination equivalent) now no-op once `isDisposed`.
  - Popping one of two *stacked* instances of the same route tore down
    dependencies the other still needed. Binding teardown is now
    reference-counted, keyed by `Route` identity rather than route name,
    and fires on all three of `didPop`/`didRemove`/`didReplace` — handling
    only `didPop` silently leaked every route left via `offNamed`.

- **`example/` is back, this time generated rather than hand-wired**:
  `ag init` + `ag g m product` + `ag g m product/details` against a real
  Melos workspace member, with only `main.dart` written by hand. Building
  it for real (rather than in an isolated test fixture) surfaced two real
  `ag_flow_cli` bugs — a `dependenciesResolved` check that never worked
  for a workspace member, and a couple of `very_good_analysis` findings
  against generated code — both fixed there; see `ag_flow_cli`'s own
  CHANGELOG.
- **Removed `example/`** (superseded by the above — kept for changelog
  continuity). The generator's own golden fixtures
  (`packages/ag_flow_cli/test/goldens/`, regenerated from real tool output)
  had briefly served as the sole reference for generated module structure
  in between.
- **Added `AgPaginationMixin.updateItems`** — an `emit()`-style escape
  hatch for reflecting a mutation (add/update/delete against the Repo) in
  the currently-displayed list directly, for when a full `refresh()`
  wouldn't show it (e.g. a demo/mock backend that doesn't actually persist
  writes) or to avoid the round-trip for an optimistic update. Added while
  wiring a full create/read/update/delete cycle into `example/` — the
  example previously only demonstrated read (list + detail); it now
  demonstrates all four, entirely hand-written (no `AgCrudService`,
  since the collection needs a paginated `getPage` that mixin doesn't
  provide) — reinforcing that AG never requires a fixed CRUD method set.
  Verified end-to-end against the real jsonplaceholder API, not mocked.
- **Reactivity: `GetBuilder` instead of `Obx`/`Rx`**, throughout — no
  per-value `Stream` wrapper, just a direct listener callback fired from
  `GetxController.update([id])`; lighter-weight for this framework's page-
  and list-level rebuild granularity. `AgBaseController.pageStateUpdateId`
  and `AgPaginationMixin.paginationUpdateId` keep page-state and
  pagination-state rebuilds independent, matching what two separate `Rx`
  values used to give for free. `AgPage`/`AgListBuilder` use
  `GetBuilder(global: false, autoRemove: false, init: controller)` — bound
  to the exact controller instance passed in (never a DI lookup by type,
  preserving testability with no `Get.put` required), with `autoRemove:
  false` load-bearing: `GetBuilder`'s default would delete the controller
  from Get's DI container on *this widget's* dispose, which must never
  happen since a Binding owns that lifecycle, not the widget reading it.
- **`AgListBuilder` is now `CustomScrollView` + `SliverList` internally**,
  behind the same external API — composable inside a larger sliver-based
  scroll view later without a breaking change. Separator interleaving
  mirrors `ListView.separated`'s own technique (verified against the
  Flutter SDK's source, not reinvented).
- **Fixed: `AgCrudService` was fundamentally broken.** A single shared
  `resourceEndpoint` can't serve both `getAll`/`add` (no id) and
  `getById`/`update`/`delete` (one id) — either shape throws on half the
  methods or silently drops the id on the other half. Split into
  `collectionEndpoint` (`getAll`/`add`) and `resourceEndpoint`
  (`getById`/`update`/`delete`). Previously had zero test coverage; now
  covered end-to-end against a fake transport.
- **Fixed: `AgEndpoint.baseUrlOverride` was dead code** — `ApiProvider
  .send` never read it. Now wired: dio treats a path starting with
  `http(s)` as absolute and ignores its own configured `baseUrl`, so the
  override is applied by concatenating it onto the resolved path.
- **Fixed: the logging interceptor omitted query parameters**
  (ag_endpoint_rules.md §23) and **only masked body keys at the top
  level** (§24) — a nested `{"user": {"password": "..."}}` or a list of
  objects passed through unmasked. Both fixed; query strings are now
  included in every log line and masking recurses through nested
  `Map`/`List` structures.
- **`AgRequest`'s contract checks are real exceptions now, not `assert`**
  — `assert` is stripped from release builds, so an unsupported
  method/endpoint pairing or a body+form-data conflict would silently
  stop being caught outside debug mode. New `AgUnsupportedMethodException`
  for the first case; `ArgumentError` for the second.
- **Added `AgCancelToken`** — `ApiProvider.send`'s cancellation parameter
  was dio's own `CancelToken`, contradicting this package's "dio types
  never leak past `ApiProvider`" invariant. `AgCancelToken` wraps it.
- **Fixed: `example/`'s route naming didn't match what the generator
  actually derives.** It used pluralized route constants/paths for the
  root module (`AppRoutes.products` → `/products`); the generator (and
  `routes.md` §6's own example) never pluralizes the route path/constant
  — only the five architectural-layer classes/files are pluralized for a
  root module. Since this example is the generator's own acceptance
  target for structural fidelity (see CLAUDE.md), a mismatch here was a
  real bug in the reference implementation, not a documented deviation.
- Added missing test coverage found while auditing against the spec: a
  dedicated `AgListBuilder` widget-test suite (previously the one core
  spec-mandated widget with zero tests) — which caught a real pre-existing
  bug along the way: `noMoreItemsBuilder`'s trailing slot was structurally
  unreachable, since `AgPaginationMixin` never produces `hasNextPage:
  false` at the same time as `isLoadingMore`/`loadMoreError`. Fixed by
  reserving a trailing slot for the exhausted case specifically when a
  `noMoreItemsBuilder` is supplied.

## 0.1.0

Initial release.

**Runtime primitives**

- `AgBasePage` / `AgPage` — state-rendering scaffold with four independent
  override slots (`loadingBuilder`, `errorBuilder`, `emptyBuilder`,
  `buildSuccess`) and optional pull-to-refresh.
- `AgBaseController<T>` — sealed `AgPageState` machine (`initial` → `loading`
  → `success` / `empty` / `error`); `emit()` is no-op after dispose, so an
  in-flight fetch completing after a route is popped never throws.
- `AgListController<Item, Key>` + `AgPaginationMixin` — paginated list
  controller with reference-counted load-more, `updateItems` optimistic
  mutation, and a separate pagination notifier so list-position changes never
  re-trigger the full page-state switch.
- `AgDetailController<T, A>` — resolves a typed navigation argument from
  `AgNavigator.pathParameters` once (lazily); throws a named
  `AgArgumentError` on a missing or wrong-type argument.
- `AgListBuilder` — `SliverList`-based widget driving `AgListController`;
  emits loading/error/empty/no-more-items slots independent of page state.

**DI**

- `AgLocator` — type-keyed service locator (`put`, `lazyPut`, `find`,
  `delete`); disposes `ChangeNotifier` instances on removal; realizes
  `AgInitializable` immediately on registration.
- `AgBinding` — route-scoped DI registration; `disposeAll` called
  automatically when the last live instance of the route is gone.

**Routing (go\_router-backed)**

- `AgApp` — `MaterialApp.router` wrapper; builds a `GoRouter` from
  `List<AgRouteBase>`; `initialBinding` registered once before the first
  frame for app-wide singletons.
- `AgRoute` — path + page builder + binding + transition + guards.
- `AgShellRoute` — persistent chrome (bottom nav, side rail) wrapping a group
  of routes; shell binding scoped to the shell's lifetime.
- `AgGuard` — single `redirect(path) → String?` contract; guards run
  in-order, first non-null wins; blocking route is never built so its binding
  never registers.
- `AgNavigator` — context-less navigation (`toNamed`, `offNamed`,
  `offAllNamed`, `back`, `toLocation`); exposes `pathParameters`, `extra`,
  `canPop`, `location`.
- `AgTransition` — `rightToLeft`, `fade`, `none`.

**Networking**

- `ApiProvider` — single Dio wrapper; interceptor-based auth/retry/logging;
  `AgCancelToken` keeps Dio types behind the framework boundary.
- `AgEndpoint` / `AgRequest` / `AgPathResolver` — declarative endpoint
  definitions; `AgUnsupportedMethodException` on method/endpoint mismatch.
- `AgBaseService` — `fetchList` / `fetchItem` with `AgEnvelope` unwrapping;
  `decodeListPayload` / `decodeItemPayload` for custom decode paths.
- `AgCrudService<T, ID>` — `getAll` / `getById` / `add` / `update` / `delete`
  from two endpoint declarations plus `fromJson` / `toJson`.
- `AgPagedService<T, K>` — `getPage` from `pageStrategy` + `envelope` +
  `fromJson`; composes with `AgCrudService`.
- `AgPageStrategy<K>` — paging dialect as a value: `AgPageNumberStrategy`,
  `AgOffsetStrategy`, `AgCursorStrategy`, `AgSinglePageStrategy`.
- `AgEnvelope` — payload location in a response body (`raw`, `.key`,
  `.path`, `.custom`).
- `AgStateService` — base class for reactive state-only services (no
  `ApiProvider`); extends `ChangeNotifier`.

**Auth guard helpers**

- `AgGuard` abstract class — the single contract for route-level access
  control; return `null` to allow, return a path to redirect.
