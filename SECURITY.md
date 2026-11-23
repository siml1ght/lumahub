# Security policy

## Supported versions

Security fixes are applied to the latest published release. This project is an MVP; do not deploy it where an unauthorized nearby device could create a physical or safety risk.

## Reporting a vulnerability

Do not open a public issue for a security problem. Report it privately to the repository owner through GitHub's private vulnerability reporting, or by email if contact details are published on the profile.

Include:

- the affected component (Flutter app, ESP32 firmware, BLE protocol, or release workflow);
- steps to reproduce;
- the impact, especially any effect on the fail-safe shutdown or on output state;
- a suggested fix if you have one.

## Scope and known limits

- The custom BLE GATT service has no application-level authentication. Anyone able to connect can send commands. This is documented in `docs/PRODUCTION_READINESS.md`.
- The ESP32 fail-safe turns all outputs off when communication is lost. Any change that can bypass it is treated as a security issue.
- Release signing keys and credentials are never committed. If a key is exposed, rotate it and report it as a security issue.

You should receive an acknowledgement within a reasonable time. Fixes are released with a note in `CHANGELOG.md`.
