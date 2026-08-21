# Changelog

## Unreleased

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

- Initial runtime framework: `AgPageState`, `AgBaseController`,
  `AgListController`/`AgPaginationMixin`, `AgDetailController`,
  `AgBasePage`, `AgPage`, `AgListBuilder`, `AgLoading`/`AgError`/`AgEmpty`,
  `AgBaseRepo`, `AgBaseService`/`AgCrudService`, `AgEndpoint`/`AgRequest`/
  `AgPathResolver`, `ApiProvider`, `AgArguments`.
