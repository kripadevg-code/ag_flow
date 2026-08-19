# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Melos monorepo (native Dart pub workspaces) implementing **AG** — Infraon's opinionated Flutter
framework + CLI, built on GetX. Two packages:

- [packages/ag_flow](packages/ag_flow) — the runtime framework (`AgBasePage`, `AgBaseController`, etc.). Complete for the classes listed below.
- [packages/ag_flow_cli](packages/ag_flow_cli) — the `ag` generator CLI. `ag init` bootstraps a bare
  project's `lib/core/` skeleton, and `ag g m <module>` works end-to-end from there: fresh-file generation
  *and* idempotent updates to the shared aggregator files (`arguments.dart`, `app_routes.dart`,
  `app_pages.dart`, `route_management.dart`). `ag analyze` doesn't exist yet.

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

- **`AgBasePage<C extends AgBaseController>`** — one type parameter for *both* collection and detail
  pages (a deliberate deviation from the spec's literal 2-type-arg diagram for detail pages — Dart can't
  have one class name support two different generic arities. `C`'s own generics already carry the
  argument type for detail controllers, so nothing is lost).
- **`AgBaseController<T>`** — page state via sealed `AgPageState<T>` (`initial/loading/success/empty/
  error`), not ad-hoc booleans. `AgPageSuccess`/`AgPageError` use deep equality (`package:collection`) so
  `T` being a `List`/`Map` of value objects compares by content, not identity.
- **`AgListController<ItemType, PageKeyType>`** (`AgPaginationMixin`) — pagination/load-more state,
  tracked separately from page-level state (a load-more failure never corrupts `AgPageSuccess`). Implement
  `fetchPage(key)` as a pure function; the mixin is the sole writer of pagination state.
- **`AgDetailController<T, A>`** — adds `late final A arguments`, resolved via `AgArguments.resolve<A>()`
  (throws a named `AgArgumentError`, never a bare cast failure).
- **`AgBaseRepo`** / **`AgBaseService`** (`AgCrudService<T, ID>` opt-in mixin) — no `Impl` classes.
- **`ApiProvider`** — wraps `dio` directly; dio types never leak past it (`AgRequest` in,
  `AgResponse`/`AgApiException` out). `AgEndpoint` is immutable/`const`-friendly (which is *why*
  `AgHttpMethod` has no custom `==` — Dart forbids custom-equality types as `const` set elements, and
  `AgEndpoint.methods` needs to be a `const` default).

See [packages/ag_flow/example](packages/ag_flow/example) for a complete hand-wired app (no CLI involved)
— it's the CLI's acceptance target, so its structure (`lib/<root>/{bindings,components,controllers,
pages,repos,services}/`, no extra wrapper folder) is authoritative for what the generator must produce.

## `ag_flow_cli` architecture (generator)

- **Naming** (`lib/src/naming/`): fully cumulative class/route naming (`product/details/reviews/comments`
  → `ProductDetailsReviewsComments*`) — confirmed over the spec's own inconsistent root+leaf examples,
  because cumulative is collision-safe in the flat per-layer folders (two branches sharing a leaf segment
  name can't collide) and root+leaf isn't. **Root-module asymmetry**: a root module's five layer
  files/classes get pluralized (`product` → `Products*`/`products_controller.dart`), but its *components*
  and the module's raw file base never do (`components/product/product_card.dart`, not `products_card
  .dart`) — this is why `ModuleSpec` exposes both `classPrefix`/`layerFileBase` (pluralized) and
  `componentClassPrefix`/`fileBase` (never pluralized), not one pair.
- **Templates** (`bricks/`, bundled to `lib/src/templates/generated/`): two Mason bricks,
  `collection_module` and `detail_module`, each generating all 6 files for their module type in one
  `mason make`-equivalent call — not one brick per layer, since every layer's content differs between
  collection and detail anyway (conditionals-per-file would've been more, not less, complexity than two
  full brick sets). Generated code uses `package:<app_package_name>/...` imports throughout — never
  relative — resolved from the *target* project's own `pubspec.yaml`.
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
    requires semantic resolution, which offset-splice editing deliberately never does. `GetPage(...)` in
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

## Known deferred work (not bugs — see the build plan for phase boundaries)

- `ag analyze` is unbuilt; `endpoints.dart` is deliberately never auto-updated by `ag g m`
  (endpoints are grouped by backend domain, not frontend module hierarchy — ag_endpoint_rules.md §5).
- `tool/check_bundles_fresh.dart` (a CI guard against editing a brick without re-bundling) is deferred to
  the polish phase.
- `.github/workflows/generator-integration.yaml` is intentionally the *reduced* init-only job (scaffold →
  `ag init` → `flutter analyze`) per the build plan's phase boundary — it does not yet run `ag g m` or
  byte-diff the aggregator files for idempotency. That fuller job (matching what's been manually verified
  above) is deferred to the polish phase, alongside `tool/check_bundles_fresh.dart`.
- The example app's `InitialBinding` points at a real public API (`jsonplaceholder.typicode.com`) — fine
  for manual `flutter run` demos, deliberately never exercised by an automated widget test (an early
  attempt at that hit a real pending-timer failure from live network I/O inside `flutter_test`'s strict
  binding; don't reintroduce that pattern).
