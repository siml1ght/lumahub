# Production readiness

This document defines what “production ready” means for LumaHub and separates repository hardening from hardware validation.

## Implemented baseline

- Strict BLE discovery by LumaHub service UUID or device name.
- BLE adapter and scan timeouts.
- Connection cleanup after discovery or GATT failures.
- Serialized GATT writes with command-size limits.
- Required command and status characteristic validation.
- Defensive profile parsing with schema versioning and size limits.
- Corrupt local profiles no longer prevent startup.
- Safe export filenames and user-visible import/export errors.
- Android backup and cleartext traffic disabled.
- Android package identity moved out of the `com.example` namespace.
- Release builds no longer fall back to debug signing.
- CI runs analysis, tests, and an Android debug build on pull requests.
- Firmware rejects oversized commands and retains fail-safe output shutdown.

## Required before a public production release

### Android signing

Create and back up an upload keystore, then configure the repository secrets described in [`ANDROID_SIGNING.md`](ANDROID_SIGNING.md). A production APK must never be distributed with a debug signature.

### Physical-device validation

Run the complete test matrix on the exact ESP32 board, driver stage, phone models, Android versions, power supply, wiring, and loads intended for deployment. Include:

- repeated connect/disconnect cycles;
- Bluetooth disabled during an active pattern;
- application termination and phone restart;
- controller restart during commands;
- corrupted profile imports;
- rapid command bursts;
- low supply voltage and electrical-noise tests;
- fail-safe timing measurement;
- verification that every output powers up OFF;
- long-duration thermal and stability testing.

### BLE security

The current custom GATT service does not provide application-level authentication. Do not deploy LumaHub where an unauthorized nearby device could create a safety or security risk. Add authenticated pairing/bonding and document key-reset/recovery behavior before such deployment.

### Store and platform configuration

Before publishing, provide final privacy-policy and support URLs, review runtime permission copy, configure store metadata, and validate the final package/bundle identifiers. iOS requires a valid Apple signing team and physical-device testing.

### Observability and support

Select a crash-reporting provider, define a privacy policy for collected diagnostics, add release symbol retention, and document user-facing support and rollback procedures.

## Release decision

A passing CI run proves that the checked-in Flutter code analyzes, tests, and builds. It does not certify the electrical design, the attached loads, BLE security, or behavior on every physical device. Release approval must include the hardware and security checks above.
