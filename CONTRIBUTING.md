# Contributing

## Scope

LumaHub is a Flutter client and ESP32 firmware for an eight-channel BLE lighting controller. Contributions to the app, firmware, protocol, tests, and documentation are welcome.

## Before you start

- Read `AGENTS.md` for architecture and product rules.
- Read `docs/TESTING.md` for the test strategy and known gaps.
- Read `docs/PRODUCTION_READINESS.md` before changing anything that affects safety or release builds.

## Development

```bash
flutter pub get
flutter analyze
flutter test --coverage
```

The firmware lives in `firmware/esp32_ble_controller/` and uses the Arduino IDE with the ESP32 core. Keep command parsing separate from output control, and keep the fail-safe shutdown on disconnect.

## Protocol changes

The text protocol is shared with the firmware. If you add or change a command:

1. Update `lib/services/command_codec.dart`.
2. Update `CommandParser.cpp` in the firmware.
3. Update the protocol table in `README.md`.
4. Add tests in `test/services/command_codec_test.dart`.

## Commits

Use Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.

Do not commit secrets, signing keys, credentials, build output, or generated artifacts. Never commit an upload keystore.

## Pull requests

- Keep changes focused on one concern.
- Explain what changed and how you verified it.
- Confirm `flutter analyze` and `flutter test` pass.
- For hardware or safety changes, describe the bench test you ran. CI passing does not certify electrical safety.
