# ag_flow_cli

The `ag` CLI — the generator half of [AG Flow](../../README.md). Scaffolds and
wires [`ag_flow`](../ag_flow) feature modules so a developer runs one
command instead of hand-writing a page/controller/repo/service/binding set
— and its routing/argument wiring — every time.

## Install

```bash
dart pub global activate --source git https://github.com/kripadevg-code/ag_flow.git --git-path packages/ag_flow_cli --git-ref ag_flow_cli-v0.1.0
```

## Usage

```bash
ag init                    # once per project — bootstraps lib/core/
ag g m product              # a collection (root) module
ag g m product/details      # a detail (child) module — requires product to already exist
ag g m product/details/reviews/comments   # nesting to any depth
ag analyze                  # validate the project against AG's structural rules
```

`ag init` creates the `lib/core/{arguments/arguments.dart, endpoints.dart,
routes/{app_routes,app_pages,route_management}.dart,
bindings/initial_binding.dart}` skeleton that `ag g m` wires modules into.
It's idempotent — safe to run again on an already-initialized project (or
one where you've since hand-edited a file under `lib/core/`) since every
file is only ever created if missing, never overwritten.

Each `ag g m <path>` generates a full set of files under
`lib/modules/<root_segment>/` (flat by architectural layer, per
requirments/ag_framework.md §6) — every module shares one `lib/modules/`
parent, sitting alongside (never inside) `lib/core`. Every page-level
chrome slot — `appBar`, `loadingBuilder`, `errorBuilder`, `emptyBuilder` —
is its own component file under `components/`, generated and linked into
the page automatically. `buildSuccess` (the actual content) stays inline
in the page itself — it's the page's own body, not a separately reusable
widget:

```
lib/modules/product/
├── bindings/products_binding.dart
├── components/product/
│   ├── product_appbar.dart    # appBar
│   ├── product_loading.dart   # loadingBuilder
│   ├── product_error.dart     # errorBuilder
│   ├── product_empty.dart     # emptyBuilder
│   └── product_item.dart      # one row, referenced from buildSuccess
├── controllers/products_controller.dart
├── pages/products_page.dart   # wires the four slots above; buildSuccess inline
├── repos/products_repo.dart
└── services/products_service.dart
```

(A detail module gets the same `_appbar`/`_loading`/`_error`/`_empty` set
and no `_item.dart` — there's no per-row widget to extract, since a detail
page renders one thing, not a list.) Every chrome component is a plain,
fully-owned starting point — customize it freely, or delete it and its
one-line reference in the page to fall back to `AgBasePage`'s own default
for that slot.

...and idempotently wires it into the shared aggregator files:

- `lib/core/routes/app_routes.dart` — a new `AppRoutes`/`_Routes` constant pair.
- `lib/core/routes/app_pages.dart` — a new `AgRoute(...)` entry (plus the imports it needs).
- `lib/core/routes/route_management.dart` — a new `goToXPage(...)` navigation method.
- `lib/core/arguments/arguments.dart` — (detail modules only) a new `<ClassPrefix>PageArgument` class, generated empty — add fields yourself; the generated controller/repo/service pass the whole argument object through rather than guessing field names.

Root modules get their layer classes/files pluralized (`Products*`); child
modules and every module's components never are (`ProductCard`, not
`ProductsCard`) — matching requirments/ag_framework.md §5 exactly. If the
default pluralizer gets a root module's name wrong, override it:

```bash
ag g m company --plural=companies   # ClassPrefix becomes "Companies", not the default guess
```

**By default, every module's Service/Repo/Controller also get `add`/
`update`/`delete` stubs** — a generator's whole point is to hand over more
working boilerplate than a developer would start from by hand, not less.
(A detail module never gets `add`: there's no "create a new one" concept
on a page that's about one existing entity.) Every stub is a plain
`UnimplementedError` placeholder with a `TODO` pointing at
`core/endpoints.dart`, exactly like the always-present read method
(`getPage`/`getByArgument`) already is — not a mixin, not framework-owned:
delete whichever ones a module doesn't need, exactly as freely as any
other generated code. All three keep the same name across Service, Repo,
and Controller, so a change reads the same at every layer. Control which
get generated with `--methods=`:

```bash
ag g m product                          # add, update, delete — all three
ag g m product --methods=add,delete     # only these two
ag g m product --methods=none           # only the read method
```

Running `ag g m` again for a module that already exists is always safe —
every file, and every aggregator-file entry, is left untouched if it
already exists, never overwritten or duplicated. A hand-customized
navigation method in `route_management.dart` (see requirments/routes.md
§19) survives regeneration byte-for-byte, no matter what else gets
generated — the check is by method name only, never by inspecting or
replacing its body. Add `--dry-run` to preview what would be generated
without writing anything.

If a route constant already exists but points at a different path than
this module would derive, generation stops with a distinct "Route already
exists" conflict error (requirments/routes.md §21) rather than silently
overwriting or duplicating it — this is different from the safe idempotent
case above, which only applies when re-deriving the *exact same* module.

### Typed modules

`--from-json` infers the module's model from a real API response and
threads the type through every layer, so a generated module compiles
against your data instead of leaving `dynamic` placeholders behind:

```bash
ag g m product --from-json=product.json   # infer Product from a real response
ag g m product --model=Product            # name the type, write the fields yourself
```

Nested objects become nested classes; a list response and a single-key
envelope (`{"data": [...]}`) are both understood. The generated model is
a plain data class — no `build_runner`, no annotations — and is never
overwritten once it exists. A detail module reuses its root's model and
gets its `idOf` path-parameter conversion written for it.

### The architecture standard

`ag init` writes more than code. It also scaffolds the standard itself, so
every developer — and every coding agent — working in the project follows
the same architecture without being told:

| File | Purpose |
|---|---|
| `AGENTS.md` | The layer contract, folder rules, generator commands, and an explicit "must not" list. Coding agents read this automatically. |
| `CLAUDE.md` | A pointer to `AGENTS.md`, not a second copy that can drift. |
| `.github/workflows/ag.yaml` | Runs `ag analyze` + analysis + tests on every push. |
| `.githooks/pre-commit` | The same check locally. Opt in with `git config core.hooksPath .githooks`. |

Instructions are advisory; the workflow and hook are the gate. All four are
skipped if they already exist, so re-running `ag init` never overwrites an
edited standard.

This matters most with AI agents: an agent that knows the standard runs
`ag g m product --from-json=api.json` — one command — instead of writing
~14 files and inventing its own structure. That is cheaper, faster, and
consistent by construction, and `ag analyze` stops it deviating.

## `ag analyze`

Validates the current project against AG's structural rules — no arguments,
run it from the project root once `ag init` has been run:

```bash
ag analyze
```

Mechanical/structural checks — always run, derived from re-parsing
`app_routes.dart`'s route table and re-deriving each route's expected
`ModuleSpec` from its path:

- a module missing one of its five architectural-layer files
  (page/controller/repo/service/binding)
- a route with no `AgRoute` entry in `app_pages.dart`
- a route with no navigation method in `route_management.dart`
- a detail route missing its argument class in `arguments.dart`
- two different route constants pointing at the identical path
- a nested subfolder under an architectural-layer or component-namespace
  folder (both must stay flat)
- a hard-coded route string (`AgNavigator.toNamed('/literal')`) anywhere outside
  `route_management.dart`

Resolved-model checks — need a *resolved* element model (`analyzer`'s
`AnalysisContextCollection`, not just a syntactic parse) to check inherited
types, so they only run once the project's dependencies have been
resolved (`dart pub get` / `flutter pub get`):

- **Dependency-direction violations**: a Page directly referencing a Repo
  or Service (or `AgBaseRepo`/`AgBaseService`/`ApiProvider`/`Dio`), a
  Controller directly referencing a Service/`ApiProvider`/`Dio`, or a Repo
  directly referencing `ApiProvider`/`Dio` — checked against the
  referenced type's full supertype chain, so a concrete `ProductsRepo`
  is caught the same way a raw `AgBaseRepo` reference would be
  (requirments/ag_framework.md §11/§70).
- **Unused detail argument**: a detail module's controller (one extending
  `AgDetailController`) that never reads its inherited `arguments`
  anywhere in the class — the navigation argument that route exists to
  carry is going unread.

If dependencies haven't been resolved yet, these two are silently skipped
(everything else still runs) and `ag analyze` prints a note telling you to
run `pub get` first — it's a notice, not a failure. Resolution is detected
by walking up from the project root looking for `.dart_tool/package_config
.json` (not just checking the root itself), so this also works correctly
for a project that's a *member* of a native pub workspace — its own
resolved config only ever lives at the workspace root.

Exits `0` with "No issues found." if clean, or non-zero with every issue
printed (one per line) otherwise.

**Known limitations**:

- A module generated with a custom `--plural=` override isn't recorded
  anywhere `ag analyze` can read it back from, so re-deriving that
  module's expected file names with the default pluralizer can produce a
  false "missing layer file" positive.
- The resolved-model checks work correctly via `dart run` and a real
  `dart pub global activate`-installed `ag` (this package's only
  documented install method — see above) but not via a standalone
  `dart compile exe` build: the analyzer can't auto-detect the Dart SDK
  from a self-contained native binary the way it can from a process
  running through the real `dart` executable.
- Several checks from `ag_framework.md` §70 / `routes.md` §24's own
  validation checklists aren't implemented yet: duplicate argument class,
  incorrect class naming (a layer file exists with the right *name* but
  the class inside it doesn't match), duplicate dependency registration,
  a module whose files exist but was never wired into `app_routes.dart`
  at all ("orphaned module"), and route-hierarchy checks (e.g. a
  `/product/details` route registered with no `/product` route). None of
  these are silently swallowed — they're just not built yet; tracked as
  v3 scope rather than left unstated.

## What this package does not do yet

- `endpoints.dart` is never touched by `ag g m` (by design — endpoint
  definitions are grouped by backend domain, not frontend module
  hierarchy, per requirments/ag_endpoint_rules.md §5). `ag init` scaffolds
  it with comment-only guidance; add your own endpoint classes there.

## Contributing to the generator templates

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to edit and
re-bundle the Mason bricks under `bricks/`.
