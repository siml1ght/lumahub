# StrobeSystem Controller

A Flutter mobile application and ESP32 firmware for configuring and controlling an eight-channel strobe-light controller over Bluetooth Low Energy (BLE).

> **Project status:** MVP / prototype. The repository includes the mobile client, ESP32 firmware, tests, hardware setup documentation, and an automated Android release workflow.

## Overview

The system consists of two parts:

1. **Flutter client** — discovers and connects to the controller, sends control commands, manages device profiles, and displays connection state.
2. **ESP32 firmware** — exposes a custom BLE GATT service, parses commands, drives up to eight configured output channels, stores runtime configuration in NVS, and switches outputs off when communication is lost.

The application also includes a mock transport, so most UI flows can be demonstrated without physical hardware.

## Implemented Features

### Mobile application

- Flutter UI for Android and iOS project targets.
- BLE discovery and connection through `flutter_blue_plus`.
- Runtime Bluetooth permission handling.
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
Flutter UI
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
ESP32 BLEHandler
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

## BLE Interface

| Item | Value |
|---|---|
| Advertised device name | `ESP32-StrobeCtrl` |
| Service UUID | `5E7A1001-0000-4C0A-B001-112233445566` |
| Command characteristic | `5E7A1002-0000-4C0A-B001-112233445566` |
| Status characteristic | `5E7A1003-0000-4C0A-B001-112233445566` |

The command characteristic is written by the mobile client. The status characteristic is used for reads and notifications from the controller.

### Protocol examples

```text
HELLO
HEARTBEAT
PING
GET_CONFIG
STATUS
STOP
ALL_OFF

FrontLeft=ON
RearRight=OFF

MODE=ON;CH=FrontLeft,RearRight
MODE=OFF;GROUP=REAR
MODE=STROBE;CH=FrontLeft,RearRight;ON=80;OFF=80;REP=5;PAUSE=300
MODE=ALTERNATE;CH=FrontLeft,FrontRight;ON=90;OFF=90;PAUSE=300
MODE=SEQUENCE;ORDER=FrontLeft,RearLeft,Beacon;ON=50;OFF=70;PAUSE=120

SET_GPIO;CH=FrontLeft;GPIO=16
SET_INVERT;CH=Beacon;VALUE=0
SET_FAILSAFE;MS=5000
SAVE_CONFIG
FACTORY_RESET
```

See [`firmware/esp32_ble_controller/README.md`](firmware/esp32_ble_controller/README.md) for the firmware command reference.

## Default Firmware Configuration

- Channels: `8`
- GPIO pins: `16, 17, 18, 19, 21, 22, 23, 25`
- Default polarity: active-high
- Default fail-safe timeout: `5000 ms`
- Allowed fail-safe range: `1000–60000 ms`
- Default pulse timing: `80 ms ON / 80 ms OFF`
- Default series pause: `300 ms`
- Default repeat count: `5`

GPIO assignments, polarity, and fail-safe timeout can be changed at runtime and persisted to NVS.

## Getting Started

### Mobile application

Requirements:

- Flutter SDK compatible with Dart `>=3.4.0 <4.0.0`
- Android device/emulator or configured iOS development environment
- A physical BLE-capable device for live controller testing

```bash
git clone https://github.com/siml1ght/strobesystem-controller.git
cd strobesystem-controller
flutter pub get
flutter run
```

On Android, grant the Bluetooth permissions requested by the application. Live BLE testing should be performed on a physical device; the mock service can be used when hardware is unavailable.

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

- `StagePatch-release.apk`
- `ESP32_firmware_only.zip`
- `StagePatch_sources.zip`

A release is created when a `v*` tag is pushed or when the workflow is started manually.

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

No license file is currently included. Unless a license is added, the source code remains under the repository owner's default copyright.