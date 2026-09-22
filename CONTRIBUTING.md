# Contributing to AG Flow

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

## Releasing

**Releases are fully automated. Nobody runs a release command.**

Merging to `main` runs `.github/workflows/release.yaml`, which:

1. Runs the full CI suite (format, analyze, bundle freshness, all tests)
   and the end-to-end generator integration proof.
2. Reads each releasable package's `version:` from its `pubspec.yaml`.
3. For any whose `<package>-v<version>` tag does not exist yet: creates
   the tag, pushes it, and publishes a GitHub Release using that
   version's `CHANGELOG.md` section as the notes.

If every version is already tagged the workflow is a clean no-op, so
ordinary merges never cut accidental releases.

### What you do to ship a change

In the same PR as your change:

- bump `version:` in that package's `pubspec.yaml`
- add a `## <version>` section to its `CHANGELOG.md`

That's it. Merge, and the release happens. **A version bump with no
matching `## <version>` changelog section fails the workflow** rather than
publishing an empty release — release notes are part of the change, not an
afterthought.

Both packages version independently; a change to one doesn't force a bump
on the other. `<package>-v<version>` is the same tag format consuming apps
pin to in their `git:` dependency `ref:`.

### Why not `melos version`

`melos version` infers versions from Conventional Commits, and it was
tried and rejected for this repo for reasons that were measured, not
assumed:

- it versions and tags `ag_flow_example` and both showcase apps, which are
  demos rather than release artifacts;
- for a pre-1.0 package it bumps `0.1.0 → 0.1.1` on a `feat:` even when the
  change is breaking, which understates the change;
- it rewrites `CHANGELOG.md` in its own format — prepending its section
  *above* the `# Changelog` heading (leaving the title stranded mid-file)
  and replacing hand-written notes with commit subjects.

It remains useful locally for inspecting what conventional commits imply
(`melos version --all --yes` in a scratch clone), but it is not in the
release path.

Neither package is published to pub.dev (`publish_to: none` everywhere) —
the GitHub tag and release are the artifact.

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
