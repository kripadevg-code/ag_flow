# AG Flow

[![CI](https://github.com/kripadevg-code/ag_flow/actions/workflows/ci.yaml/badge.svg)](https://github.com/kripadevg-code/ag_flow/actions/workflows/ci.yaml)
[![Generator Integration](https://github.com/kripadevg-code/ag_flow/actions/workflows/generator-integration.yaml/badge.svg)](https://github.com/kripadevg-code/ag_flow/actions/workflows/generator-integration.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Open Source](https://img.shields.io/badge/open--source-yes-brightgreen.svg)](https://github.com/kripadevg-code/ag_flow)

**An opinionated Flutter framework and CLI — zero third-party state-management dependency — that turns "write a new feature module" into a single command.**

AG Flow standardizes the shape of every feature module (page → controller →
repo → service → binding), the routing/navigation-argument wiring, and
page-state handling (loading/error/empty/refresh/retry) — so you spend
your time on business logic and UI instead of re-building the same
infrastructure for every screen.

Built for developers who want structure without ceremony. Open-source,
free to use, adopt, and adapt in your own personal or professional projects.

![ag init, ag g m, and ag analyze generating and validating a real module end-to-end](docs/demo.gif)

## Why AG Flow

- **One command per module.** `ag g m product` generates a fully-wired
  page/controller/repo/service/binding/component set — routing, DI, and
  navigation arguments included — in one shot. `ag g m product/details`
  nests to any depth from there.
- **A structure you can enforce, not just suggest.** `ag analyze` checks a
  real project against the architecture — missing layer files, routes
  with no navigation wiring, a Page reaching straight past its Controller
  into a Service, a detail route whose argument is generated but never
  read — the same rules the generator itself follows, so drift gets
  caught instead of accumulating.
- **Independent overrides, not an all-or-nothing template.** Override only
  the error state, or only the loading state — every other AG default
  stays exactly as generated.
- **One networking chokepoint.** Every generated Service goes through a
  single, centrally-configured `ApiProvider` — no per-feature `Dio`
  instances, no hand-rolled URLs, no scattered auth/retry/logging logic.
- **Regeneration never clobbers your work.** Re-running `ag g m` on an
  existing module is a no-op; a hand-customized navigation method survives
  regeneration byte-for-byte, forever.

The binding specification for AG Flow lives in [requirments/](requirments/):

- [ag_framework.md](requirments/ag_framework.md) — module structure, architectural layers, page/controller/repo/service contracts
- [routes.md](requirments/routes.md) — routing/navigation/arguments generation rules
- [ag_endpoint_rules.md](requirments/ag_endpoint_rules.md) — centralized API endpoint/request rules

**New to AG Flow?** See [GETTING_STARTED.md](GETTING_STARTED.md) — a
hands-on walkthrough of every feature, from `ag init` through a fully
wired detail module, written for a developer who's never touched this
framework before.

See [CLAUDE.md](CLAUDE.md) for a condensed architecture summary aimed at
engineers (and AI assistants) working in this repo.

## Packages

This is a [Melos](https://melos.invertase.dev/) monorepo built on native
Dart pub workspaces.

| Package | Status | Purpose |
|---|---|---|
| [`packages/ag_flow`](packages/ag_flow) | Available | The runtime framework: `AgBasePage`, `AgBaseController`, `AgListBuilder`, `AgBaseRepo`, `AgBaseService`, `ApiProvider`, and the rest of the classes every generated module is built from. |
| [`packages/ag_flow_cli`](packages/ag_flow_cli) | Available | The `ag` CLI. `ag init` bootstraps a bare project's `lib/core/` skeleton; `ag g m <module>` generates a module's page/controller/repo/service/binding/component files *and* idempotently wires its route/argument/nav-method into the shared aggregator files; `ag analyze` validates a project against AG's structural rules, including resolved-model checks (dependency-direction violations, unused detail arguments) once dependencies are resolved. Named `ag_flow_cli` (not `ag_cli`) to avoid colliding with the maintainer's unrelated, separately published `ag-cli` package. |

## Installing

Add as a git dependency pinned to a tag in your app's `pubspec.yaml`:

```yaml
dependencies:
  ag_flow:
    git:
      url: https://github.com/kripadevg-code/ag_flow.git
      path: packages/ag_flow
      ref: ag_flow-v0.1.0
```

`ag_flow_cli` is added the same way, with `path: packages/ag_flow_cli`, or
activated globally as a CLI tool — see its own
[README](packages/ag_flow_cli/README.md).

## Working in this repo

```bash
dart pub global activate melos   # once per machine
melos bootstrap                  # resolves the whole workspace
melos run format-check
melos run analyze
melos run check-bundles-fresh
melos run test
```

The full end-to-end flow (see [routes.md](requirments/routes.md) §29) is
available today:

```bash
ag init                     # bootstraps lib/core/ once per project
ag g m product
ag g m product/details
ag analyze                  # validates the project's structural rules
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full contributor workflow,
including how to cut a release.
