# ag_flow_cli example

Add the CLI to a Flutter app, bootstrap AG Flow, and generate modules:

```bash
flutter pub add ag_flow go_router
dart pub add --dev ag_flow_cli

dart run ag_flow_cli:ag init                    # lib/core/ skeleton, AGENTS.md, CI check
dart run ag_flow_cli:ag g m product             # a list module
dart run ag_flow_cli:ag g m product/details     # a detail module under it
dart run ag_flow_cli:ag g m order --from-json=order.json --methods=create
dart run ag_flow_cli:ag analyze                 # check the project's structure
```

Then wire the generated router in `lib/main.dart`:

```dart
void main() {
  InitialBinding().dependencies();
  runApp(MaterialApp.router(routerConfig: AppPages.router));
}
```

For a complete generated app, see
[`ag_flow/example`](https://github.com/kripadevg-code/ag_flow/tree/main/packages/ag_flow/example).
