import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeController extends AgBaseController<String> {
  _FakeController() : super(autoLoadOnInit: false);

  @override
  Future<String> fetch() async => 'data';

  void setState(AgPageState<String> next) => emit(next);
}

Widget _harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AgPage — independent state overrides (ag_framework.md §15)', () {
    testWidgets(
      'renders the AG default AgLoading when no loadingBuilder is supplied',
      (
        tester,
      ) async {
        final controller = _FakeController()
          ..setState(const AgPageState.loading());
        await tester.pumpWidget(
          _harness(
            AgPage<String>(
              controller: controller,
              builder: (context, data) => Text(data),
            ),
          ),
        );
        expect(find.byType(AgLoading), findsOneWidget);
      },
    );

    testWidgets(
      'renders the AG default AgError when no errorBuilder is supplied',
      (tester) async {
        final controller = _FakeController()
          ..setState(const AgPageState.error('boom'));
        await tester.pumpWidget(
          _harness(
            AgPage<String>(
              controller: controller,
              builder: (context, data) => Text(data),
            ),
          ),
        );
        expect(find.byType(AgError), findsOneWidget);
      },
    );

    testWidgets(
      'renders the AG default AgEmpty when no emptyBuilder is supplied',
      (tester) async {
        final controller = _FakeController()
          ..setState(const AgPageState.empty());
        await tester.pumpWidget(
          _harness(
            AgPage<String>(
              controller: controller,
              builder: (context, data) => Text(data),
            ),
          ),
        );
        expect(find.byType(AgEmpty), findsOneWidget);
      },
    );

    testWidgets(
      'overriding ONLY errorBuilder leaves Loading and Empty on AG defaults — the core '
      'independent-override guarantee',
      (tester) async {
        final controller = _FakeController();
        Widget build() => _harness(
          AgPage<String>(
            controller: controller,
            builder: (context, data) => Text(data),
            errorBuilder: (context, error, stackTrace, retry) =>
                const Text('custom error'),
          ),
        );

        controller.setState(const AgPageState.loading());
        await tester.pumpWidget(build());
        expect(
          find.byType(AgLoading),
          findsOneWidget,
          reason: 'loadingBuilder was not overridden',
        );

        controller.setState(const AgPageState.empty());
        await tester.pumpWidget(build());
        expect(
          find.byType(AgEmpty),
          findsOneWidget,
          reason: 'emptyBuilder was not overridden',
        );

        controller.setState(const AgPageState.error('boom'));
        await tester.pumpWidget(build());
        expect(find.text('custom error'), findsOneWidget);
        expect(find.byType(AgError), findsNothing);
      },
    );

    testWidgets(
      'a second page overriding ONLY loadingBuilder demonstrates a different override '
      'combination — Error and Empty stay AG defaults there instead',
      (tester) async {
        final controller = _FakeController();
        Widget build() => _harness(
          AgPage<String>(
            controller: controller,
            builder: (context, data) => Text(data),
            loadingBuilder: (context) => const Text('custom loading'),
          ),
        );

        controller.setState(const AgPageState.loading());
        await tester.pumpWidget(build());
        expect(find.text('custom loading'), findsOneWidget);

        controller.setState(const AgPageState.error('boom'));
        await tester.pumpWidget(build());
        expect(find.byType(AgError), findsOneWidget);

        controller.setState(const AgPageState.empty());
        await tester.pumpWidget(build());
        expect(find.byType(AgEmpty), findsOneWidget);
      },
    );

    testWidgets(
      'renders success content via builder, with the AG default fallbacks unused',
      (
        tester,
      ) async {
        final controller = _FakeController()
          ..setState(const AgPageState.success('hello'));
        await tester.pumpWidget(
          _harness(
            AgPage<String>(
              controller: controller,
              builder: (context, data) => Text(data),
            ),
          ),
        );
        expect(find.text('hello'), findsOneWidget);
        expect(find.byType(AgLoading), findsNothing);
        expect(find.byType(AgError), findsNothing);
        expect(find.byType(AgEmpty), findsNothing);
      },
    );

    testWidgets('tapping retry in the default AgError calls controller.retry', (
      tester,
    ) async {
      final controller = _FakeController()
        ..setState(const AgPageState.error('boom'));
      await tester.pumpWidget(
        _harness(
          AgPage<String>(
            controller: controller,
            builder: (context, data) => Text(data),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(controller.state, isA<AgPageSuccess<String>>());
    });
  });
}
