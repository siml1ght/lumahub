# LumaHub ESP32 BLE Firmware

Firmware for the ESP32 controller used by LumaHub.

## Libraries
- ESP32 Arduino core
- `BLEDevice.h`
- `BLEServer.h`
- `BLEUtils.h`
- `BLE2902.h`
- `Preferences.h` for ESP32 NVS config storage

## BLE interface

The controller advertises as `LumaHub-ESP32` and exposes one service with command and status characteristics. See the [BLE protocol reference](../../docs/PROTOCOL.md) for UUIDs, command grammar, channel names, status format, and fail-safe rules.

## Supported modes

`HELLO`, `HEARTBEAT`, `PING`, `GET_CONFIG`, `STATUS`, `STOP`, `ALL_OFF`, direct `Channel=ON|OFF`, `MODE=ON|OFF`, and the `SINGLE_FLASH`, `DOUBLE_FLASH`, `STROBE`, `ALTERNATE`, `SEQUENCE` patterns. Configuration uses `SET_GPIO`, `SET_INVERT`, `SET_FAILSAFE`, `SAVE_CONFIG`, and `FACTORY_RESET`.

## Runtime Config
GPIO, inversion, and fail-safe timeout are loaded from ESP32 NVS at boot.
Use `SET_GPIO`, `SET_INVERT`, and `SET_FAILSAFE` to change values without
editing `Config.h`; use `SAVE_CONFIG` to persist and `FACTORY_RESET` to restore
the defaults from `Config.h`.

## Wiring
ESP32 GPIO must drive only logic-level inputs of MOSFETs, transistor stages,
relay drivers, or optocouplers.

- use a shared GND between ESP32 and the driver stage
- do not connect lamps or inductive loads directly to ESP32 GPIO
- add flyback diodes for relays and other inductive loads
- use fused automotive 12V input and a DC-DC supply for ESP32
