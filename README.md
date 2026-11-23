# LumaHub

LumaHub is a Flutter mobile application and ESP32 firmware for configuring and controlling an eight-channel lighting system over Bluetooth Low Energy (BLE).

> **Project status:** MVP. The mobile client, ESP32 firmware, tests, hardware setup documentation, and an automated Android release workflow are included. BLE control has not been verified on physical hardware yet.

## Overview

The system consists of two parts:

1. **LumaHub mobile client** — discovers and connects to the controller, sends control commands, manages device profiles, and displays connection state.
2. **LumaHub ESP32 controller** — exposes a custom BLE GATT service, parses commands, drives up to eight configured output channels, stores runtime configuration in NVS, and switches outputs off when communication is lost.

The application also includes a mock transport, so most UI flows can be demonstrated without physical hardware.

## Implemented Features

### Mobile application

- Flutter UI for Android and iOS project targets.
- BLE discovery and connection through `flutter_blue_plus`.
- BLE permission handling by `flutter_blue_plus` during scan, with human-readable errors.
- Live control of individual channels and channel groups.
- Strobe, alternate, and sequence command generation.
- Local profile persistence with `shared_preferences`.
- JSON profile import and export.
- Mock connection service for development and demonstrations without an ESP32.
- State management with `provider`.

### ESP32 firmware

- Custom BLE service with separate command and status characteristics.
- Eight configurable output channels.
- Non-blocking pattern execution.
- Direct ON/OFF, group, strobe, alternate, and sequence modes.
- Runtime GPIO, polarity, and fail-safe configuration.
- Persistent configuration using ESP32 NVS (`Preferences`).
- Heartbeat-based fail-safe shutdown.
- Factory-reset support.

## Architecture

```text
LumaHub Flutter UI
   │
   ▼
App state / providers
   │
   ▼
ControllerConnectionService
   ├── BleConnectionService
   └── MockConnectionService
   │
   ▼
ControllerCommandCodec
   │  BLE GATT
   ▼
LumaHub ESP32 BLEHandler
   ▼
CommandParser ── ConfigStore / SafetyManager
   ▼
PatternManager ── LightController ── GPIO driver stage
```

Main source directories:

```text
lib/
├── app/          Application setup
├── models/       Domain and profile models
├── providers/    Application state
├── screens/      Mobile screens
├── services/     BLE, mock transport, protocol, and storage
└── widgets/      Reusable UI components

firmware/esp32_ble_controller/
├── BLEHandler.*
├── CommandParser.*
├── ConfigStore.*
├── LightController.*
├── PatternManager.*
├── SafetyManager.*
└── esp32_ble_controller.ino
```

## Protocol

The app and firmware exchange short text commands over a custom BLE GATT service named `LumaHub-ESP32`. Eight channels are addressed by name (`FrontLeft` … `Flood`) or by group (`FRONT`, `REAR`, `SIDE`, `ALL`).

The [BLE protocol reference](docs/PROTOCOL.md) defines the service, command grammar, channel list, control and configuration commands, status messages, and fail-safe behaviour. Firmware-specific build details live in [firmware/esp32_ble_controller/README.md](firmware/esp32_ble_controller/README.md).

## Getting Started

### Mobile application

Requirements:

- Flutter SDK compatible with Dart `>=3.4.0 <4.0.0`
- Android device/emulator or configured iOS development environment
- A physical BLE-capable device for live controller testing

```bash
git clone https://github.com/siml1ght/lumahub.git
cd lumahub
flutter pub get
flutter run
```

Turn on Bluetooth before scanning. `flutter_blue_plus` requests the needed permissions during `startScan()`: on Android 12 and newer it asks for Nearby Devices, on Android 11 and older it also asks for Location. The app shows a message telling you what to enable if a permission or the adapter is unavailable. Use a physical device for live BLE testing; the mock transport works without hardware.

### ESP32 firmware

Open `firmware/esp32_ble_controller/esp32_ble_controller.ino` in the Arduino IDE with the ESP32 Arduino core installed, select the correct ESP32 board and port, then build and upload the sketch.

Detailed setup instructions: [`firmware/esp32_ble_controller/SETUP_GUIDE_RU.md`](firmware/esp32_ble_controller/SETUP_GUIDE_RU.md).

## Testing

```bash
flutter analyze
flutter test --coverage
flutter test integration_test
```

The integration suite requires a supported configured target. Current automated coverage focuses on protocol encoding, model serialization, application state, widgets, and the main connection flow.

Known gaps include hardware-in-the-loop testing, automated firmware unit tests, and physical-device regression testing. See [`docs/TESTING.md`](docs/TESTING.md) for details.

## Releases

The GitHub Actions workflow runs static analysis and Flutter tests, builds a release APK, and publishes:

- `LumaHub-release.apk`
- `ESP32_firmware_only.zip`
- `LumaHub_sources.zip`

A release is created when a `v*` tag is pushed or when the workflow is started manually. The APK is signed with the Android debug key so it can be installed for testing; a production keystore is required before publishing.

## Hardware Safety

ESP32 GPIO pins must only drive logic-level inputs of a suitable MOSFET, transistor, relay-driver, or optocoupler stage.

- Do not connect lamps, relays, or other power loads directly to ESP32 GPIO.
- Use a shared ground where required by the selected driver topology.
- Add flyback protection for relays and other inductive loads.
- Use appropriate fusing and a regulated DC-DC supply for automotive installations.
- Validate the system with low-power test loads before connecting production hardware.

Hardware documentation:

- [`docs/BUILD_AND_WIRING_GUIDE_RU.md`](docs/BUILD_AND_WIRING_GUIDE_RU.md)
- [`docs/LED_BENCH_TEST_GUIDE_RU.md`](docs/LED_BENCH_TEST_GUIDE_RU.md)
- [`examples/led_bench_profile.json`](examples/led_bench_profile.json)

## Troubleshooting

**"Включите Bluetooth на телефоне и попробуйте снова"** — Bluetooth is off. Turn it on and tap Scan controllers again.

**"Нет разрешения Bluetooth"** — the Nearby Devices permission was denied. Tap Open app settings and allow it.

**No controllers discovered** — confirm the ESP32 is powered, flashed with this firmware, and advertising as `LumaHub-ESP32`. If Android shows the device in its Bluetooth settings, do not pair there; connect from the LumaHub app. Gateways, headphones, and lamps will also appear in the list; pick the controller by its name.

**The app shows an old error message** — check Settings: the current build is labeled `LumaHub 0.2.0+4 / Build 4`. Uninstall an older build before installing a new APK if the version code has not changed.

## Technology Stack

- Flutter / Dart
- ESP32 Arduino / C++
- Bluetooth Low Energy (GATT)
- Provider
- SharedPreferences
- JSON import/export
- Flutter unit, widget, and integration tests
- GitHub Actions

## Roadmap

- Hardware-in-the-loop test bench.
- Host-side or native firmware unit tests.
- Android physical-device regression suite.
- Protocol acknowledgements and stronger error reporting.
- Additional transport implementations behind the connection-service abstraction.

## License

MIT. See [LICENSE](LICENSE).
