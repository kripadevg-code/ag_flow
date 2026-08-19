# Contributing to AG

## Setup

```bash
dart pub global activate melos
melos bootstrap
```

## Before sending a change

```bash
melos run format-check
melos run analyze
melos run test
```

All three must pass. CI runs the same commands plus (once `ag_flow_cli`
exists) an integration job that scaffolds a real app with the CLI and
verifies it compiles — see `.github/workflows/`.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`,
`fix:`, `chore:`, `docs:`, `test:`, ...). This repo versions `ag_flow` and
`ag_flow_cli` independently via `melos version --scope=<package>`, which
relies on commit messages to generate changelogs.

## Adding a new module type / AG widget

Per `requirments/ag_framework.md` §69, only standardize a pattern once it's
repeated across multiple real modules — don't add `AgFormPage`,
`AgWizardPage`, `AgGridBuilder`, etc. speculatively. When a pattern does
justify standardizing, keep it feature-independent (no knowledge of any
specific business entity) and add it alongside the existing classes in
`packages/ag_flow/lib/src/`, with unit/widget tests covering it the same
way `AgBaseController`/`AgListBuilder` are covered today.

## Architectural rules

The three documents in `requirments/` are the binding spec. If a change
would violate one of them (e.g. business logic leaking into `AgListBuilder`,
a per-module `ApiProvider`, a nested architectural folder), that's a bug —
fix the change, not the spec, unless you're deliberately proposing a spec
amendment (call that out explicitly in the PR description).
