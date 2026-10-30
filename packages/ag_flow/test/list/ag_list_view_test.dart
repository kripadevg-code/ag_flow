import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Plain extends AgBaseController<List<int>> with AgList<int> {
  _Plain() : super(autoLoadOnInit: false);

  @override
  Future<List<int>> list() async => [1, 2, 3];
}

class _Paged extends AgBaseController<List<int>> with AgLoadMore<int> {
  _Paged({this.failPage}) : super(autoLoadOnInit: false);

  int? failPage;
  final List<int> requested = [];

  @override
  Future<List<int>> list({int page = 1}) async {
    requested.add(page);
    if (page == failPage) throw Exception('down');
    if (page > 3) return const [];
    return List.generate(20, (i) => (page - 1) * 20 + i);
  }
}

Widget _host(AgBaseController<List<int>> controller, {Widget? header}) {
  final list = AgListView<int>(
    controller: controller,
    itemBuilder: (context, item, index) => SizedBox(height: 50, child: Text('item $item')),
  );
  return MaterialApp(
    home: Scaffold(
      body: header == null
          ? list
          : Column(
              children: [
                header,
                Expanded(child: list),
              ],
            ),
    ),
  );
}

Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a plain controller is a plain list — no footer', (
    tester,
  ) async {
    final c = _Plain();
    await c.loadInitial();

    await tester.pumpWidget(_host(c));

    expect(find.text('item 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('scrolling to the end of an AgLoadMore list loads the next '
      'page', (tester) async {
    final c = _Paged();
    await c.loadInitial();
    await tester.pumpWidget(_host(c));

    await _scrollToEnd(tester);

    expect(c.requested, [1, 2]);
    expect(c.state.dataOrNull, hasLength(40));
  });

  testWidgets('a nested horizontal scrollable never pages the outer list', (
    tester,
  ) async {
    final c = _Paged();
    await c.loadInitial();
    final carousel = SizedBox(
      height: 40,
      child: ListView(
        key: const Key('carousel'),
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < 5; i++) SizedBox(width: 300, child: Text('chip $i')),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgListView<int>(
            controller: c,
            itemBuilder: (context, item, index) =>
                index == 0 ? carousel : SizedBox(height: 50, child: Text('$item')),
          ),
        ),
      ),
    );

    await tester.drag(find.byKey(const Key('carousel')), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(c.requested, [1]);
  });

  testWidgets('a failed page shows retry and never retries itself on '
      'scroll', (tester) async {
    final c = _Paged(failPage: 2);
    await c.loadInitial();
    await tester.pumpWidget(_host(c));

    await _scrollToEnd(tester);
    expect(find.text('Retry'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(c.requested, [1, 2], reason: 'scrolling must not retry');

    c.failPage = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(c.requested, [1, 2, 2]);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('separators sit between items only', (tester) async {
    final c = _Plain();
    await c.loadInitial();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgListView<int>(
            controller: c,
            itemBuilder: (context, item, index) => Text('item $item'),
            separatorBuilder: (context, index) => const Divider(),
          ),
        ),
      ),
    );

    expect(find.byType(Divider), findsNWidgets(2));
  });
}
