import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:strobe_controller_mobile/providers/app_state.dart';
import 'package:strobe_controller_mobile/screens/manual_control_screen.dart';
import 'package:strobe_controller_mobile/screens/patterns_screen.dart';
import 'package:strobe_controller_mobile/screens/settings_screen.dart';

import '../support/fakes.dart';

Widget _hosted(Widget child, AppState state) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(home: child),
  );
}

void main() {
  group('Screen interactions', () {
    testWidgets('manual control sends command when connected', (tester) async {
      final connection = FakeConnectionService();
      final state = AppState(
        connectionService: connection,
        profileStorageService: FakeProfileStorageService(),
        profileExchangeService: FakeProfileExchangeService(),
        enableHeartbeat: false,
      );
      await state.bootstrap();
      await state.connect('ESP32-StrobeCtrl');
      connection.sentCommands.clear();

      await tester.pumpWidget(_hosted(const ManualControlScreen(), state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Front left'));
      await tester.pumpAndSettle();

      expect(connection.sentCommands, contains('FrontLeft=ON'));
      expect(state.activeControlKeys.contains('front_left'), isTrue);
    });

    testWidgets('pattern switch activates selected pattern', (tester) async {
      final connection = FakeConnectionService();
      final state = AppState(
        connectionService: connection,
        profileStorageService: FakeProfileStorageService(),
        profileExchangeService: FakeProfileExchangeService(),
        enableHeartbeat: false,
      );
      await state.bootstrap();
      await state.connect('ESP32-StrobeCtrl');
      connection.sentCommands.clear();

      await tester.pumpWidget(_hosted(const PatternsScreen(), state));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(state.selectedPatternId, isNotNull);
      expect(connection.sentCommands.any((c) => c.startsWith('MODE=')), isTrue);
    });

    testWidgets('settings toggles theme and mock mode', (tester) async {
      final state = AppState(
        connectionService: FakeConnectionService(),
        profileStorageService: FakeProfileStorageService(),
        profileExchangeService: FakeProfileExchangeService(),
        enableHeartbeat: false,
      );
      await state.bootstrap();

      await tester.pumpWidget(_hosted(const SettingsScreen(), state));
      await tester.pumpAndSettle();

      // Appearance follows the system; no in-app appearance toggle.
      expect(state.themeMode, ThemeMode.system);

      final before = state.useMockMode;
      await tester.tap(find.text('Mock mode'));
      await tester.pumpAndSettle();
      expect(state.useMockMode, isNot(before));
    });
  });
}
