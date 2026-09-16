import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:strobe_controller_mobile/app/app.dart';
import 'package:strobe_controller_mobile/providers/app_state.dart';

import '../test/support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('connect screen scan and connect flow', (tester) async {
    final appState = AppState(
      connectionService: FakeConnectionService(),
      profileStorageService: FakeProfileStorageService(),
      blePermissionService: FakeBlePermissionService(),
      profileExchangeService: FakeProfileExchangeService(),
    )..bootstrap();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const LumaHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Controller Connection'), findsOneWidget);

    await tester.tap(find.text('Scan Controllers'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Found'), findsOneWidget);
    expect(find.text('Connect').first, findsOneWidget);
  });
}
