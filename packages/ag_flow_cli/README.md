# ag_flow_cli

The `ag` CLI — the generator half of [AG](../../README.md). Scaffolds and
wires [`ag_flow`](../ag_flow) feature modules so a developer runs one
command instead of hand-writing a page/controller/repo/service/binding set
— and its routing/argument wiring — every time.

## Install (enterprise-internal)

```bash
dart pub global activate --source git <enterprise-git-host>/ag_flow.git --git-path packages/ag_flow_cli --git-ref ag_flow_cli-v0.1.0
```

## Usage

```bash
ag g m product            # a collection (root) module
ag g m product/details    # a detail (child) module — requires product to already exist
ag g m product/details/reviews/comments   # nesting to any depth
```

Requires the project to already have the `lib/core/{arguments/arguments
.dart, routes/{app_routes,app_pages,route_management}.dart}` skeleton in
place (`ag init` will create this automatically once it exists — see
"What this package does not do yet" below; for now, create the skeleton
by hand once per project, matching [`packages/ag_flow/example`](../ag_flow/example)'s
`core/` files).

Each `ag g m <path>` generates six files under `lib/<root_segment>/`
(flat by architectural layer, per requirments/ag_framework.md §6):

```
lib/product/
├── bindings/products_binding.dart
├── components/product/product_item.dart
├── controllers/products_controller.dart
├── pages/products_page.dart
├── repos/products_repo.dart
└── services/products_service.dart
```

...and idempotently wires it into the shared aggregator files:

- `lib/core/routes/app_routes.dart` — a new `AppRoutes`/`_Routes` constant pair.
- `lib/core/routes/app_pages.dart` — a new `GetPage(...)` entry (plus the imports it needs).
- `lib/core/routes/route_management.dart` — a new `goToXPage(...)` navigation method.
- `lib/core/arguments/arguments.dart` — (detail modules only) a new `<ClassPrefix>PageArgument` class, generated empty — add fields yourself; the generated controller/repo/service pass the whole argument object through rather than guessing field names.

Root modules get their layer classes/files pluralized (`Products*`); child
modules and every module's components never are (`ProductCard`, not
`ProductsCard`) — matching requirments/ag_framework.md §5 exactly.

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

## What this package does not do yet

- `ag init` (project bootstrap) and `ag analyze` (validation) don't exist
  yet — see the build plan's phased roadmap.
- `endpoints.dart` is never touched by `ag g m` (by design — endpoint
  definitions are grouped by backend domain, not frontend module
  hierarchy, per requirments/ag_endpoint_rules.md §5).

## Contributing to the generator templates

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to edit and
re-bundle the Mason bricks under `bricks/`.
