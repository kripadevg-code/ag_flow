import 'package:ag_flow_example/core/auth/auth_service.dart';
import 'package:ag_flow_example/core/bindings/initial_binding.dart';
import 'package:ag_flow_example/core/routes/app_pages.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';
import 'package:ag_flow_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login and logout move between routes with no navigation code', (tester) async {
    InitialBinding().dependencies();
    await AuthService.instance.restoreSession();
    await tester.pumpWidget(const AgFlowExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Login as User'), findsOneWidget);

    // A logged-out user can't reach a protected route.
    AppPages.router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.text('Login as User'), findsOneWidget);

    await tester.tap(find.text('Login as User'));
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);
    expect(AuthService.instance.readToken(), 'demo-token-user');

    // Logged in, but not an admin.
    AppPages.router.go(AppRoutes.adminPanel);
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Login as User'), findsOneWidget);
    expect(AuthService.instance.isLoggedIn, isFalse);
    expect(AuthService.instance.readToken(), isNull);
  });
}
