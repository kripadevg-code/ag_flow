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
melos run check-bundles-fresh
melos run test
```

All four must pass. CI runs the same commands plus an integration job that
scaffolds a real app, runs `ag init` → `ag g m product` → `ag g m
product/details` → `ag analyze` twice (byte-diffing the aggregator files in
between to prove idempotency) → `flutter analyze --fatal-infos` — see
`.github/workflows/generator-integration.yaml`.

## Authoring/editing `ag_flow_cli` Mason bricks

`packages/ag_flow_cli/bricks/**/__brick__/**` files contain literal
`{{mustache}}` placeholders and are not valid Dart — `dart analyze` already
skips them (`ag_flow_cli/analysis_options.yaml` excludes `bricks/**`), but
`dart format` has no exclude mechanism, which is why `format-check` lists
explicit source roots instead of `.` (see that script's `pubspec.yaml`
comment). After editing any brick, re-bundle it before committing:

```bash
dart pub global activate mason_cli   # once per machine
cd packages/ag_flow_cli
mason bundle bricks/<brick_name> -t dart -o lib/src/templates/generated/
```

The committed `lib/src/templates/generated/*.dart` bundle files are what
`ag_flow_cli` actually loads at runtime (via `MasonGenerator.fromBundle`) —
editing a brick's `__brick__/` source without re-bundling has no effect.
`melos run check-bundles-fresh` (also run in CI) catches this: it decodes
each committed bundle's file data and byte-compares it against the brick
source on disk, so a forgotten re-bundle fails fast instead of silently
shipping stale generated code.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`,
`fix:`, `chore:`, `docs:`, `test:`, ...). This repo versions `ag_flow` and
`ag_flow_cli` independently via `melos version --scope=<package>`, which
relies on commit messages to generate changelogs.

## Cutting a release

Both packages are versioned and tagged independently — a change to one
doesn't force a version bump on the other:

```bash
melos version --scope=ag_flow          # or --scope=ag_flow_cli
```

This bumps the package's `pubspec.yaml` version (via Conventional Commits
since its last tag), updates its `CHANGELOG.md`, commits, and creates a
`<package>-v<version>` git tag (e.g. `ag_flow-v0.2.0`) — the same tag
format consuming apps pin to in their `git:` dependency `ref:`. Push the
tag once you're ready for consumers to pick it up:

```bash
git push --follow-tags
```

Pushing a `ag_flow-v*`/`ag_flow_cli-v*` tag triggers
`.github/workflows/release.yaml`, which verifies the tag's version
matches `pubspec.yaml`, runs that package's tests, and creates a GitHub
release with that version's `CHANGELOG.md` section as its notes — a
mismatched version (a tag cut without actually running `melos version`
first, for instance) fails the workflow loudly rather than publishing a
release with the wrong notes.

Neither package is published to public pub.dev (`publish_to: none`
everywhere, per Infraon's enterprise-only policy) — the tag itself, on
this repo's own enterprise git remote, is the release artifact.

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
