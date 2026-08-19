# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository State

This repository currently contains **no implementation code** — only specification documents in
[requirments/](requirments/) describing a Flutter framework/CLI called **AG** that has not yet been built.
There is no `pubspec.yaml`, no `lib/`, no CLI source, and no build/test/lint tooling. There is nothing to
run, build, or test yet.

When asked to implement AG (the CLI generator and/or the runtime framework classes), treat the three files
below as the binding spec. When the three documents conflict or are ambiguous, ask before inventing
behavior — these are precise, numbered rulesets and deviations are easy to get wrong.

- [requirments/ag_framework.md](requirments/ag_framework.md) — module structure, architectural layers, page/controller/repo/service contracts
- [requirments/routes.md](requirments/routes.md) — routing/navigation/arguments generation rules
- [requirments/ag_endpoint_rules.md](requirments/ag_endpoint_rules.md) — centralized API endpoint/request rules

## What AG Is

AG is an opinionated Flutter framework + CLI (built on **GetX**) for generating standardized feature
modules via `ag g m <module_path>` (e.g. `ag g m product`, `ag g m product/details`). Core principle:

> Automate repetitive architecture, not business decisions.

AG owns generated infrastructure (bindings, routing, DI, page-state plumbing). The developer owns
business logic, UI, and feature-specific API/data behavior — and these must never mix.

## Module Types

- **Collection module** (`ag g m product`): `ProductsPage → AgBasePage<ProductsController> → AgPage → AgListBuilder → Item UI`
- **Detail module** (`ag g m product/details`): `ProductDetailsPage → AgBasePage<ProductDetailsController, ProductDetailsArguments> → AgPage → Detail UI`

Nested child modules are supported to arbitrary depth (`product/details/reviews/comments`). A child
module requires its parent to already exist — the CLI must error if the parent is missing rather than
create an invalid hierarchy.

## Layer Architecture (strict, one-directional)

```
Page → Controller → Repo → Service → ApiProvider
```

- **Page**: UI composition only. Never touches Repo/Service/ApiProvider/Dio directly. Uses `AgBasePage`.
- **Controller**: extends `AgBaseController`. Feature state, orchestration, business logic. Never touches Service/ApiProvider/Dio directly — only calls its Repo.
- **Repo**: extends `AgBaseRepo`. Data abstraction, calls its Service. Never touches ApiProvider/Dio directly. No `RepoImpl` classes — the repo class itself is concrete.
- **Service**: extends `AgBaseService`. Owns API/endpoint communication via the single shared `ApiProvider`. No per-module `ApiProvider` subclasses.
- **Binding**: wires `ApiProvider → Service → Repo → Controller` for the module; DI is fully generated, never hand-wired.
- **Component**: reusable UI under the module's `components/` namespace; never calls Service/Repo/ApiProvider directly.

`AgBasePage`/`AgListBuilder`/`AgLoading`/`AgError`/`AgEmpty` are generic framework widgets and must
remain feature-independent (no `ProductBasePage`, `TicketListBuilder`, etc.).

### Page-state responsibility split (important, frequently violated)

- `AgBasePage`/`AgPage` own page-level state: Loading, Error, Empty, Refresh, Retry, Success. Each is
  independently overridable without replacing the others.
- `AgListBuilder` owns *only* collection concerns: item rendering, scrolling, load-more/pagination. It
  must never own page-level loading/error/empty or contain business/API logic.
- Initial-load loading/error and load-more loading/error are distinct states handled at different layers
  — do not conflate them.

## Filesystem Layout (per-module, must stay flat)

Architectural layers are **flat within a module** regardless of how deep the logical module hierarchy
goes — child-module artifacts live alongside the parent's in the same shared folder, never in nested
subfolders:

```
product/
├── components/
│   ├── product/       # module "product" → components/product/
│   ├── details/        # module "product/details" → components/details/
│   └── reviews/         # module "product/details/reviews" → components/reviews/
├── bindings/
├── controllers/
├── services/
├── repos/
└── pages/
```

Never create `controllers/details/`, `components/details/reviews/`, or any nested architectural/
component folder — the module hierarchy is logical (via naming/routing), not physical.

Naming: module paths use `snake_case`; generated Dart classes use `PascalCase` derived from the full
module path (e.g. `product/details/reviews` → `ProductDetailsReviewsController`).

## Routing (GetX), Arguments, Endpoints — single sources of truth

Exactly one of each, generated/maintained by the CLI, never duplicated per-module:

```
lib/core/
├── arguments/arguments.dart   # every navigation argument class, e.g. ProductDetailsPageArgument
├── endpoints.dart              # every API endpoint definition, grouped by backend domain (not by frontend module)
└── routes/
    ├── app_routes.dart         # route path constants (AppRoutes.productDetails), no hard-coded strings in feature code
    ├── app_pages.dart          # GetPage registrations (page + binding + transition)
    └── route_management.dart   # the only navigation API: RouteManagement.goToXPage(...), not raw Get.toNamed(...)
```

- Route path/constant/page/controller/binding/argument/nav-method are all derived mechanically from the
  module path (see `routes.md` §26 for the full derivation table).
- Detail/child modules require an argument object by default (`goToProductDetailsPage(ProductDetailsPageArgument(...))`); argument-free is the exception, not the default.
- Endpoint definitions (`endpoints.dart`) are grouped by **backend API domain**, not mirrored to frontend
  module structure — multiple services/modules may legitimately share one `AgEndpoint`.
- Endpoints (`AgEndpoint`, reusable path contract) are distinct from requests (`AgRequest`, per-call
  method/path-params/query-params/headers/body) — dynamic values never mutate the shared endpoint
  definition; path params are resolved by AG, never hand-built as `'/products/$id'`.

## Generation Invariants (apply to any CLI implementation work)

- **Idempotent**: re-running `ag g m <module>` must add only missing pieces — never duplicate files, classes, routes, bindings, arguments, or imports.
- **Never overwrite developer code**: generated infrastructure (bindings, route registration, DI, arguments registration) is CLI-owned and safe to regenerate; business logic, custom service/repo/controller methods, and custom UI are developer-owned and must be preserved across regeneration.
- **Automatic import/formatting management**: the CLI is responsible for correct relative imports and Dart formatting on every generation/update.
- Child modules never automatically depend on or receive their parent's Controller/Repo/Service — each module tier is independently generated and wired.
