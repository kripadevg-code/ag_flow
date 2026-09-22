# Changelog

## 0.3.0

- `ag_flow` dependency updated to `^0.3.0`.

## 0.2.0

- `ag_flow` dependency updated to `^0.2.0`.

## 0.1.0

Initial release.

- `@AgInject()` annotation — place on any class extending `AgBaseController`,
  `AgListController`, `AgDetailController`, `AgBaseService`, or
  `AgStateService`.
- `AgInjectGenerator` — `build_runner` generator that emits a
  `mixin _$FooAgInject` with a static `find` getter (controllers) or
  `instance` getter (services), so `AgLocator.find<T>()` never appears
  at a call site.
- `agInjectBuilder` — `SharedPartBuilder` factory referenced by
  `build.yaml`; auto-applies to any package that lists `ag_flow_generator`
  as a dev dependency.
