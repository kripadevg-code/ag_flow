# ag_flow_cli

The `ag` CLI — the generator half of [AG](../../README.md). Scaffolds and
wires [`ag_flow`](../ag_flow) feature modules so a developer runs one
command instead of hand-writing a page/controller/repo/service/binding set
every time.

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

A detail module's controller/repo/service reference a
`<ClassPrefix>PageArgument` type from `lib/core/arguments/arguments.dart` —
add that class yourself for now (idempotently maintaining that file
automatically is a later phase; see the build plan).

Root modules get their layer classes/files pluralized (`Products*`); child
modules and every module's components never are (`ProductCard`, not
`ProductsCard`) — matching requirments/ag_framework.md §5 exactly.

Running `ag g m` again for a module that already exists is always safe —
existing files are left untouched, never overwritten. Add `--dry-run` to
preview what would be generated without writing anything.

## What this package does not do yet

- `ag init` (project bootstrap) and `ag analyze` (validation) don't exist
  yet.
- The shared aggregator files (`arguments.dart`, `app_routes.dart`,
  `app_pages.dart`, `route_management.dart`) are not updated automatically
  — only the six per-module files above are generated.

See the repository root's build plan for the phased roadmap toward the
full `ag init` → `ag g m` → `ag analyze` flow.

## Contributing to the generator templates

See the root [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to edit and
re-bundle the Mason bricks under `bricks/`.
