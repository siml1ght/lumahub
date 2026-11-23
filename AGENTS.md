# LumaHub Project Rules

## Product Goal
- Build a Flutter MVP for configuring and controlling an Arduino or ESP32 strobe-light controller.
- Optimize for phone usage with a dark UI, large controls, and fast real-time actions.
- Keep the app usable offline with a mock communication mode.

## Architecture
- Organize Flutter code into `models`, `services`, `providers`, `screens`, and `widgets`.
- Use `provider` for state in this MVP.
- Hide transport logic behind an adapter interface so BLE can later be swapped for Bluetooth Serial or Wi-Fi.
- Store profiles locally as JSON through `shared_preferences` with clean seams for later migration.

## Firmware Rules
- Keep command parsing separate from output control logic.
- Fail safe on disconnect by turning all outputs off.
- Use defensive parsing for inbound commands.

## UX Rules
- Default to dark theme and clear touch targets.
- Manual control actions must visually indicate active state.
- Connection problems and validation issues must always be surfaced in the UI.
