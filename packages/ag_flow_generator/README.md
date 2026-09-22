# ag_flow_generator

[![pub.dev](https://img.shields.io/pub/v/ag_flow_generator.svg)](https://pub.dev/packages/ag_flow_generator)

Optional `build_runner` code generator for [ag_flow](https://pub.dev/packages/ag_flow).

Annotate a controller or service with `@AgInject()` and the generator
produces a static `find` or `instance` accessor so you never write
`AgLocator.find<T>()` at a call site.

```dart
// Before
final controller = AgLocator.find<LoginController>();
final service    = AgLocator.find<AuthService>();

// After — Dart infers the type from the left side
final controller = LoginController.find;
final service    = AuthService.instance;
```

## Setup

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  ag_flow_generator: ^0.1.0
  build_runner: ^2.4.0
```

Annotate and add the `with` mixin:

```dart
part 'login_controller.g.dart';

@AgInject()
class LoginController extends AgBaseController<User>
    with _$LoginControllerAgInject {
  // LoginController.find is generated automatically
}
```

Run the generator:

```bash
dart run build_runner build
```

## Naming convention

| Base class | Generated getter |
|---|---|
| `AgBaseController` / `AgListController` / `AgDetailController` | `.find` |
| `AgBaseService` / `AgStateService` | `.instance` |

The correct getter name is determined automatically from the supertype
chain — you never specify it.

## Part of the AG Flow ecosystem

- [`ag_flow`](https://pub.dev/packages/ag_flow) — the runtime framework
- [`ag_flow_cli`](https://pub.dev/packages/ag_flow_cli) — the `ag` CLI generator
- [`ag_flow_generator`](https://pub.dev/packages/ag_flow_generator) — this package
