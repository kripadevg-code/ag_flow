# Removing the GetX dependency — design proposal

**Status: IMPLEMENTED.** Kept as the decision record for *why* each primitive looks the way it does.
The as-built shape matches this proposal, with names settled as `AgLocator` / `AgBuilder` + `AgNotifier` /
`AgApp` + `AgRoute` + `AgBinding` + `AgNavigator` + `AgTransition`.

Three defects were found while building — by probing the new primitives rather than assuming they were
sound — and all three are fixed and regression-tested. See `CLAUDE.md`'s "Owned primitives" section for
the invariants they established:

1. `AgLocator.delete` didn't dispose controllers → listener leak on every popped route.
2. `emit()` after disposal threw → crash when a user backs out mid-fetch.
3. Popping one of two stacked instances of a route tore down deps the other still needed; and
   `offNamed`/`offAllNamed` leaked bindings entirely, because they never fire `didPop`.

## What GetX actually does for `ag_flow` today

Everything GetX-shaped in this framework reduces to exactly three jobs. Nothing else — AG never
uses GetX's snackbars, dialogs-without-context, translations, theming, or its `tag`-based DI
variant, so the replacement doesn't need to either.

| Job | GetX API used | Where |
|---|---|---|
| Dependency injection | `Get.put`, `Get.lazyPut`, `Get.find`, `Get.delete` | Every generated `Binding`; `AgBasePage`'s controller resolution |
| Rebuild plumbing | `GetxController`, `.update([ids])`, `GetBuilder<T>(id:)` | `AgBaseController`, `AgPaginationMixin`, `AgPage`, `AgListBuilder` |
| Routing | `GetMaterialApp`, `GetPage`, `Get.toNamed`, `Get.back`, `Get.arguments`, `Transition` | Every generated `main.dart`/`app_pages.dart`/`route_management.dart`; `AgArguments.resolve` |

None of these are AG's actual architecture (Page → Controller → Repo → Service, sealed
`AgPageState`, `AgListController`/`AgPaginationMixin`) — they're infrastructure *underneath* it.
This migration changes what powers that architecture, not the architecture itself. A developer's
mental model of AG (layers, page states, pagination) doesn't change at all.

## Proposed replacements

Three new, independent primitives, each named to match AG's existing `Ag<Noun>` convention. They
intentionally do **not** collapse into one `Ag`-god-object the way `Get` does — that's a real,
frequently-criticized GetX design smell, and splitting by concern makes each piece easier to reason
about and test in isolation.

### 1. `AgLocator` — dependency injection

```dart
abstract class AgLocator {
  static void put<T extends Object>(T instance, {bool permanent = false});
  static void lazyPut<T extends Object>(T Function() factory);
  static T find<T extends Object>();
  static void delete<T extends Object>();
}
```

Implementation: one `Map<Type, Object>` for realized singletons, one `Map<Type, Object Function()>`
for pending lazy factories, one `Set<Type>` for `permanent` entries (never auto-removed). This is
the entire DI surface AG has ever used — no tags, no `fenix`, no scoping. A `find<T>()` on a type
with a pending lazy factory realizes it and caches the instance, matching `Get.lazyPut`'s behavior
exactly.

### 2. Plain `ChangeNotifier` + `AgBuilder` — rebuild plumbing

`AgBaseController` extends Flutter's own `ChangeNotifier` (SDK-provided, no dependency) instead of
`GetxController`. The id-based `GetBuilder<T>(id: someId)` trick — used today specifically so a
pagination-only change never also re-triggers the page-level loading/error/empty/success switch —
is replaced by giving each concern its **own** `ChangeNotifier`, rather than one controller
multiplexing rebuild groups by string id:

```dart
abstract class AgBaseController<T> extends ChangeNotifier {
  // page state: notifyListeners() called only from emit()
}

mixin AgPaginationMixin<ItemType, PageKeyType> on AgBaseController<List<ItemType>> {
  final paginationNotifier = _PaginationNotifier(); // separate ChangeNotifier
}
```

`AgPage`/`AgListBuilder` each listen to the *specific* notifier they care about via
`AgBuilder(listenable: ..., builder: ...)` — a thin, AG-branded wrapper around Flutter's own
`ListenableBuilder` (confirmed present in the pinned SDK — `flutter/lib/src/widgets/transitions.dart`
— stable since Flutter 3.13). This is arguably **more** correct than the current id-string
approach: two separate objects can't accidentally collide on the same id, where today nothing stops
a typo'd id string from silently listening to the wrong group.

`emit()` stays the single write path on `AgBaseController`; it just calls `notifyListeners()`
instead of `update([pageStateUpdateId])`.

### 3. `AgApp` / `AgRoute` / `AgNavigator` / `AgBinding` — routing

```dart
class AgBinding {
  const AgBinding();
  void dependencies() {} // override to register Service/Repo/Controller
}

class AgRoute {
  const AgRoute({
    required this.name,
    required this.page,
    this.binding,
    this.transition = AgTransition.rightToLeft,
  });
  final String name;
  final Widget Function() page;
  final AgBinding? binding;
  final AgTransition transition;
}

enum AgTransition { rightToLeft, fade, none }

class AgApp extends StatelessWidget {
  const AgApp({required this.initialRoute, required this.routes, this.initialBinding, ...});
  // wraps MaterialApp, builds onGenerateRoute from `routes`, applying each
  // AgRoute's binding via a wrapper page that calls it once per push and
  // AgTransition via PageRouteBuilder.transitionsBuilder — a well-known,
  // no-dependency Flutter pattern.
}

abstract class AgNavigator {
  static Future<T?> toNamed<T>(String route, {Object? arguments});
  static void back<T>([T? result]);
  static Object? get arguments; // from the most recent push's RouteSettings
}
```

Context-less navigation (calling `AgNavigator.toNamed` from inside a Controller, with no
`BuildContext` in scope) needs the same trick GetX itself uses under the hood: `AgApp` owns a single
`GlobalKey<NavigatorState>`, and `AgNavigator` pushes/pops through it. `AgNavigator.arguments` is
populated by a small `NavigatorObserver` that records `route.settings.arguments` on every push —
attached once, inside `AgApp`.

This covers exactly what AG's generated `route_management.dart`/`app_pages.dart` need: named routes,
per-route bindings, transitions, and argument passing. It deliberately does not attempt deep
linking, nested navigators, or `Router`/`RouteInformationParser` — AG has never used those, and
GetX's own routing doesn't meaningfully use them either in how AG applies it.

## What this does *not* change

- `AgPageState` (sealed `initial/loading/success/empty/error`), `AgListPage`,
  `AgPaginationMixin`'s state machine, `AgBaseRepo`, `AgBaseService`/`AgCrudService`, `ApiProvider`/
  `AgRequest`/`AgEndpoint`/`AgResponse` — none of this touches GetX today and none of it changes.
- The five-file-per-module generated shape, naming rules, or `lib/modules/` layout.
- The `--methods=`/CRUD-stub-by-default generator behavior.

## What has to change (full impact list)

**`ag_flow` runtime**: `ag_base_controller.dart`, `ag_list_controller.dart` (+ pagination state),
`ag_base_page.dart`, `ag_page.dart`, `ag_list_builder.dart`, `ag_arguments.dart` — plus five new
files (`ag_locator.dart`, `ag_navigator.dart`, `ag_app.dart`, `ag_route.dart`, `ag_binding.dart`).
Remove `get` from `pubspec.yaml` and the `export 'package:get/get.dart';` line from the public
barrel. Every existing test that constructs a controller/widget touching GetX (which is most of
`ag_flow`'s test suite) needs its harness updated — no `Get.put` calls to set up, no `GetBuilder`
internals to reason about.

**`ag_flow_cli` generator**: every brick template (`bricks/collection_module/`,
`bricks/detail_module/`) that emits `Bindings`/`Get.lazyPut`/`Get.find`/`GetPage`/`Get.toNamed`/
`Transition`/`GetMaterialApp` — rewritten to the new names, rebundled. `app_pages_updater.dart`,
`app_routes_updater.dart` (unaffected — no GetX types), `route_management_updater.dart`,
`arguments_updater.dart` (unaffected), `init_generator.dart`'s four skeleton strings
(`_appPagesSkeleton`, `_routeManagementSkeleton`, `_initialBindingSkeleton`, and
`main.dart`-wiring guidance printed in `ag init`'s own next-steps). `hardcoded_route_check.dart`
matches `Get.toNamed(...)`-shaped calls by name — needs to match `AgNavigator.toNamed` instead. Every
golden fixture (`test/goldens/collection_module/`, `test/goldens/detail_module/`) regenerated from
real tool output, per this repo's existing convention.

**Consuming apps**: `packages/ag_flow/example/`, `showcase/blog/`, `showcase/store/` — every
`main.dart`, every generated `Binding`, every page's controller-resolution and navigation call sites
migrated to the new API. Mechanically the same shape of change as the generator's own templates,
just applied to already-generated code instead of template source.

**Docs**: `CLAUDE.md`, `GETTING_STARTED.md`, both package `README.md`s, and — since `requirments/`
is the *binding specification*, not just internal notes — `routes.md` and `ag_framework.md`'s
GetX-specific passages (`GetPage`, `Get.toNamed`, `Bindings`) get rewritten to describe the new
primitives. This is the one place the spec itself changes, not just its implementation.

## Honest scale assessment

This is comparable in size to the original runtime build (the "Phase 1" work that built
`ag_flow` from nothing) — it touches every runtime class, every brick template, every generated
file across three apps, and the binding specification itself. It is **not** a small refactor.

## Proposed phased plan

1. **Build the three primitives in `ag_flow`, additively** — `AgLocator`, the notifier-based state
   change, `AgBuilder`, `AgApp`/`AgRoute`/`AgNavigator`/`AgBinding` — alongside the existing GetX
   code, with real unit/widget tests for each (matching this repo's "verify empirically before
   relying on any API" convention: a real navigation-with-arguments round trip, a real
   context-less `AgNavigator.toNamed` call from inside a plain object, a real two-notifier rebuild
   isolation test). No breaking change yet — `ag_flow` still depends on `get` at the end of this
   phase.
2. **Migrate `ag_flow`'s own runtime classes** to the new primitives; remove `get` from
   `pubspec.yaml`; update `ag_flow`'s test suite.
3. **Migrate `ag_flow_cli`**: bricks, aggregator updaters, `init_generator.dart`'s skeletons,
   `hardcoded_route_check.dart`; rebundle; regenerate every golden fixture from real tool output.
4. **Migrate the three consuming apps** (`example/`, `showcase/blog/`, `showcase/store/`) —
   mechanical, mirrors what the generator now emits.
5. **Rewrite the affected spec/doc passages** — `routes.md`, `ag_framework.md`, `CLAUDE.md`,
   `GETTING_STARTED.md`, both READMEs.
6. **Full verification**: `melos run test`/`format-check`/`analyze`/`check-bundles-fresh`,
   `flutter analyze --fatal-infos` on both showcases + example, and a real simulator run
   confirming navigation/DI/rebuilds all still work end-to-end (the same bar this session has
   held for every other change).

Each phase is independently committable and testable — this doesn't have to land as one giant
change.
