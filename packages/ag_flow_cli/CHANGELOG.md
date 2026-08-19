# Changelog

## 0.1.0

- `ag generate module <path>` (aliased `ag g m <path>`): generates the
  page/controller/repo/service/binding/component files for a new
  collection (root) or detail (child) module, via Mason bricks bundled as
  committed Dart sources.
- Fully cumulative naming derivation (`ModulePath`/`ModuleSpec`), with
  root-module layer pluralization handled separately from (never-
  pluralized) component naming.
- Parent-existence validation for child/detail modules, with the exact
  spec-mandated error message and no partial writes on failure.
- `--dry-run` support; idempotent re-generation (never overwrites an
  existing file).
- Idempotent updates to the shared aggregator files (`app_routes.dart`,
  `app_pages.dart`, `route_management.dart`, and — for detail modules —
  `arguments.dart`) via offset-splice AST editing (`package:analyzer`,
  syntax-only parse): a new entry is inserted only if missing; an existing
  entry — including a hand-customized navigation method — is left
  byte-for-byte untouched. Requires the project to already have the
  `ag init` skeleton in place (that command itself doesn't exist yet).
- `RouteConflictException`: a route constant that already exists pointing
  at a different path than this module would derive is reported as a
  distinct conflict, never silently overwritten.
- Does not yet provide `ag init`/`ag analyze` — see the build plan's
  phased roadmap.
