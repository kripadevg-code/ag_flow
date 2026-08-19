# AG

AG is Infraon's opinionated Flutter framework and CLI, built on top of
[GetX](https://pub.dev/packages/get). It standardizes the shape of every
feature module (page → controller → repo → service → binding), the routing/
navigation-argument wiring, and page-state handling (loading/error/empty/
refresh/retry), so teams spend their time on business logic and UI instead
of re-building the same infrastructure for every screen.

The binding specification for AG lives in [requirments/](requirments/):

- [ag_framework.md](requirments/ag_framework.md) — module structure, architectural layers, page/controller/repo/service contracts
- [routes.md](requirments/routes.md) — routing/navigation/arguments generation rules
- [ag_endpoint_rules.md](requirments/ag_endpoint_rules.md) — centralized API endpoint/request rules

See [CLAUDE.md](CLAUDE.md) for a condensed architecture summary aimed at
engineers (and AI assistants) working in this repo.

## Packages

This is a [Melos](https://melos.invertase.dev/) monorepo built on native
Dart pub workspaces.

| Package | Status | Purpose |
|---|---|---|
| [`packages/ag_flow`](packages/ag_flow) | Available | The runtime framework: `AgBasePage`, `AgBaseController`, `AgListBuilder`, `AgBaseRepo`, `AgBaseService`, `ApiProvider`, and the rest of the classes every generated module is built from. |
| [`packages/ag_flow_cli`](packages/ag_flow_cli) | `ag g m` available; `ag init`/`ag analyze` planned | The `ag` CLI. `ag g m <module>` generates and wires a module's page/controller/repo/service/binding/component files today. Named `ag_flow_cli` (not `ag_cli`) to avoid colliding with the maintainer's unrelated, separately published `ag-cli` package. |

## Installing (enterprise-internal)

Neither package is published to public pub.dev — per Infraon policy, this
code stays inside the enterprise. Consuming apps depend on it via a git
dependency pinned to a tag:

```yaml
dependencies:
  ag_flow:
    git:
      url: <enterprise-git-host>/ag_flow.git
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
melos run test
```

`ag g m` is available today; the full end-to-end flow (see
[routes.md](requirments/routes.md) §29) — including `ag init` project
bootstrap — is the target once later phases land:

```bash
ag init                     # planned
ag g m product              # available
ag g m product/details      # available
```
