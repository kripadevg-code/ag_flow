# Changelog

## Unreleased

- **Every generated module now lives under a shared `lib/modules/`
  parent** — `lib/modules/product/...`, `lib/modules/auth/...` — instead
  of directly under `lib/`, sitting alongside (never inside) `lib/core`.
  Filesystem organization only: route paths, class names, and every other
  naming derivation are unchanged. `ag analyze`'s structural and
  resolved-model checks look under `lib/modules/` accordingly. Found and
  fixed along the way: Mason's default `{{var}}` interpolation
  HTML-escapes its value, so the new `module_import_path` var (the first
  brick var whose value contains a `/`) rendered as `modules&#x2F;product`
  in every brick-templated import until switched to unescaped
  triple-mustache (`{{{module_import_path}}}`).
- **`ag g m`'s generated page is now pure wiring — every overridable slot
  is its own component file, generated and linked in automatically.**
  `appBar`, `loadingBuilder`, `errorBuilder`, and `emptyBuilder` each get a
  dedicated file under `components/<namespace>/` (`_appbar.dart`,
  `_loading.dart`, `_error.dart`, `_empty.dart`), and the success content
  does too: a collection module's `_list.dart` (wraps `AgListBuilder`,
  referencing the existing `_item.dart` per-row widget — previously
  generated but never actually wired into the page) and a detail module's
  `_view.dart` (previously generated but likewise dangling). All are plain
  starting-point widgets — customize freely, or delete one and its
  one-line reference in the page to fall back to `AgBasePage`'s own
  default for that slot.
  - Found and fixed along the way, via a real `dart analyze` against a
    freshly generated, `pub get`-resolved project (this repo's own
    verification convention, but not previously re-run after the
    add/update/delete stub feature below shipped): the generated
    Controller's `update()` stub silently collided with `GetxController
    .update()` — an override with an incompatible signature, a genuine
    `invalid_override` compile error in every project that generated one.
    Renamed to `updateItem` on the Controller only (Service/Repo keep
    `update()` — they don't extend `GetxController`, so there's no clash).
- **`ag g m` now generates `add`/`update`/`delete` stubs by default**
  across Service/Repo/Controller, alongside the always-present read
  method (`getPage`/`getByArgument`) — matching the read method's own
  shape exactly (a plain `UnimplementedError` placeholder with a `TODO`
  pointing at `core/endpoints.dart`). Not a mixin, not framework-owned:
  a generator's whole point is to hand over more working boilerplate
  than starting from scratch, and every stub is deleted exactly as
  freely as any other generated code if a module doesn't need it. `add`
  is only generated for collection modules — a detail module has no
  "create a new one" concept. New `--methods=` flag controls which get
  generated (`--methods=add,delete`, or `--methods=none` for read-only);
  omitting it generates all applicable ones. Golden fixtures regenerated
  from real tool output, not hand-transcribed, matching this repo's own
  existing convention for avoiding formatter-output guessing errors.
- **Fixed: `--plural=` was documented and fully implemented at the
  `ModuleGenerator`/`ModuleSpec` layer, but never wired into `ag g m`
  itself** — `ModuleCommand` never registered the option, so it was
  unreachable from the actual CLI. Wired via `argParser.addOption
  ('plural', ...)`; the supplied override is run through the same
  `pascalCase` conversion the naming machinery already uses for every
  other segment, since an early version of this fix passed the raw CLI
  argument straight through and produced `companiesController` instead
  of `CompaniesController`. Covered by a new
  `test/src/commands/module_command_test.dart`, exercising the real
  `args`-parsing/`CommandRunner` path rather than only the generator API
  directly (which is exactly where the wiring gap — and the casing bug —
  were both invisible before).
- `ag analyze` v2 checks — dependency-direction violations and unused
  detail arguments, both previously deferred pending a resolved element
  model. Built on `package:analyzer`'s `AnalysisContextCollection`
  (resolved units, not just `parseString`) instead of the syntax-only
  approach every other check uses:
  - **Dependency-direction**: flags a Page directly referencing a Repo or
    Service, a Controller directly referencing a Service/`ApiProvider`/
    `Dio`, or a Repo directly referencing `ApiProvider`/`Dio` — matched
    against the referenced type's full supertype chain (via
    `InterfaceType.allSupertypes`), so a concrete `ProductsRepo` is caught
    the same way a raw `AgBaseRepo` reference would be
    (requirments/ag_framework.md §11/§70).
  - **Unused detail argument**: flags a detail controller (one extending
    `AgDetailController`) whose inherited `arguments` accessor is never
    referenced anywhere in the class — resolved-model-based specifically
    so a reference is confirmed to resolve to the real inherited getter,
    not just a same-named local that would false-positive a syntax-only
    search.
  - Both checks are skipped (not a failure) if the project's dependencies
    haven't been resolved yet (no `.dart_tool/package_config.json`) —
    `ag analyze` prints a notice telling the user to run `pub get` first,
    while every other (syntax-only) check still runs normally.
  - Verified end-to-end via `dart run` and a real `dart pub global
    activate`-installed `ag` against a genuine `flutter pub add`-wired
    project. A standalone `dart compile exe` build does *not* work for
    these two checks — the analyzer can't auto-detect the Dart SDK from a
    self-contained native binary — documented as a known limitation since
    that isn't this package's supported distribution method anyway.
  - `ProjectAnalyzer.analyze()` is now `async` (`Future<List<AnalyzeIssue>>`)
    to support this; every existing syntax-only check is unaffected and
    every existing test still passes unchanged.

## 0.1.0

- `ag generate module <path>` (aliased `ag g m <path>`): generates the
  page/controller/repo/service/binding/component files for a new
  collection (root) or detail (child) module, via Mason bricks bundled as
  committed Dart sources.
- Fully cumulative naming derivation (`ModulePath`/`ModuleSpec`), with
  root-module layer pluralization handled separately from (never-
  pluralized) component naming.
- Parent-existence validation for child/detail modules, with the exact
  spec-mandated error message and no partial writes on failure.
- `--dry-run` support; idempotent re-generation (never overwrites an
  existing file).
- Idempotent updates to the shared aggregator files (`app_routes.dart`,
  `app_pages.dart`, `route_management.dart`, and — for detail modules —
  `arguments.dart`) via offset-splice AST editing (`package:analyzer`,
  syntax-only parse): a new entry is inserted only if missing; an existing
  entry — including a hand-customized navigation method — is left
  byte-for-byte untouched. Requires the project to already have the
  `ag init` skeleton in place (that command itself doesn't exist yet).
- `RouteConflictException`: a route constant that already exists pointing
  at a different path than this module would derive is reported as a
  distinct conflict, never silently overwritten.
- `ag init`: bootstraps a bare project's `lib/core/` skeleton (`arguments
  .dart`, `endpoints.dart`, `routes/{app_routes,app_pages,route_management}
  .dart`, `bindings/initial_binding.dart`) so `ag g m` has somewhere to wire
  generated modules into. Idempotent via the same `FileOp`/`Executor`
  boundary as `ag g m` — an existing file is skipped, never overwritten.
  Verified end-to-end against a real `flutter create`d app: `ag init` →
  `ag g m product` → `ag g m product/details` → `flutter analyze
  --fatal-infos` reports zero issues.
- `ag analyze`: a v1, mechanical/structural-only validator. Re-parses
  `app_routes.dart`'s route table and re-derives each route's expected
  `ModuleSpec` from its path (not its constant name, which is what makes
  this immune to whatever pluralizer produced the name), then checks:
  missing architectural-layer files, missing `GetPage`/nav-method/argument-
  class wiring, two route constants pointing at the identical path, nested
  architectural/component folders, and hard-coded `Get.toNamed('/literal')`
  calls outside `route_management.dart`. Exits `0` clean, non-zero with
  every issue printed otherwise. Dependency-direction violations and
  detail-route-without-argument-usage checks are deliberately deferred to
  v2+ (need a resolved element model, not just syntax) — a regression test
  confirms a Page hand-edited to call a Service directly produces zero
  issues today, documenting that boundary explicitly rather than leaving
  it implicit.
