import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:strobe_controller_mobile/app/app.dart';
import 'package:strobe_controller_mobile/providers/app_state.dart';

void main() {
  testWidgets('app shell renders connection screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const LumaHubApp(),
      ),
    );

    await tester.pump();

    expect(find.text('LumaHub Connection'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
