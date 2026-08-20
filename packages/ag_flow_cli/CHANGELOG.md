# Changelog

## Unreleased

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
