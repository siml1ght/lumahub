# BLE protocol

LumaHub uses a text protocol over a custom BLE GATT service. The Flutter app encodes commands; the ESP32 firmware parses and executes them. This document is the single source of truth for the wire format.

## Transport

| Item | Value |
|---|---|
| Advertised device name | `LumaHub-ESP32` |
| Service UUID | `5E7A1001-0000-4C0A-B001-112233445566` |
| Command characteristic | `5E7A1002-0000-4C0A-B001-112233445566` (write) |
| Status characteristic | `5E7A1003-0000-4C0A-B001-112233445566` (read, notify) |
| Max command length | 180 bytes |
| Min write spacing | 40 ms |

The app writes to the command characteristic. The firmware publishes status messages on the status characteristic via notifications.

## Grammar

A command is either a single word or a list of `KEY=VALUE` pairs separated by `;`:

```text
COMMAND
KEY=VALUE;KEY=VALUE;...
```

Keys and values are case-insensitive. Channel names and group names are defined below. The firmware rejects commands that exceed the length limit or contain unknown keys; it replies with `ERROR:<reason>` on the status characteristic.

## Channels and groups

Eight channels, fixed order:

| Index | Name | Default GPIO |
|---|---|---|
| 1 | `FrontLeft` | 16 |
| 2 | `FrontRight` | 17 |
| 3 | `RearLeft` | 18 |
| 4 | `RearRight` | 19 |
| 5 | `SideLeft` | 21 |
| 6 | `SideRight` | 22 |
| 7 | `Beacon` | 23 |
| 8 | `Flood` | 25 |

Groups: `FRONT`, `REAR`, `SIDE`, `ALL`.

## Commands

### Session

| Command | Effect |
|---|---|
| `HELLO` | Identify the controller; status returns its name and version. |
| `HEARTBEAT` | Keepalive; refreshes the disconnect timer. |
| `PING` | Liveness check; status returns `PONG`. |
| `STATUS` | Request the current state, mode, and safe flag. |
| `GET_CONFIG` | Request GPIO, inversion, and fail-safe settings. |

### Control

| Command | Effect |
|---|---|
| `FrontLeft=ON` | Switch one channel on. `OFF` switches it off. |
| `MODE=ON;CH=FrontLeft,RearRight` | Switch a channel list on. `OFF` switches it off. |
| `MODE=ON;GROUP=FRONT` | Switch a group on. `OFF` switches it off. |
| `MODE=SINGLE_FLASH;CH=Beacon;ON=120;OFF=180;REP=3` | Flash once per repetition. |
| `MODE=DOUBLE_FLASH;CH=Beacon;ON=70;OFF=70;PAUSE=250` | Flash twice per repetition. |
| `MODE=STROBE;CH=...;ON=80;OFF=80;REP=5;PAUSE=300` | Flash channels for a number of repetitions. |
| `MODE=ALTERNATE;CH=...;ON=100;OFF=100;PAUSE=300` | Alternate channels in sequence. |
| `MODE=SEQUENCE;ORDER=...;ON=50;OFF=70;PAUSE=120` | Run channels in a custom order. |
| `STOP` | Stop a running pattern. |
| `ALL_OFF` | Stop the pattern and switch every channel off. |

Timing values are milliseconds. `REP` is a repeat count.

### Configuration

| Command | Effect |
|---|---|
| `SET_GPIO;CH=FrontLeft;GPIO=16` | Assign a GPIO pin to a channel. |
| `SET_INVERT;CH=Beacon;VALUE=1` | Invert a channel (`0` or `1`). |
| `SET_FAILSAFE;MS=5000` | Set the disconnect timeout. Range: 1000–60000 ms. |
| `SAVE_CONFIG` | Persist configuration to NVS. |
| `FACTORY_RESET` | Restore defaults and clear NVS. |

GPIO changes and inversion take effect immediately; call `SAVE_CONFIG` to keep them after a restart.

## Fail-safe

The firmware switches all outputs off when either happens:

- the BLE client disconnects;
- no command arrives within the fail-safe timeout (default 5000 ms).

The app sends `HEARTBEAT` periodically while connected. A safe-state shutdown reports `SAFE=1` and `STATE=DISCONNECTED` in the status message. The app clears its active-control display and requires a new command to resume.

## Status messages

Status is a `;`-separated list of `KEY=VALUE` pairs:

```text
STATE=CONNECTED;MODE=STROBE;ACTIVE=FrontLeft,Beacon;SAFE=0
```

| Key | Meaning |
|---|---|
| `STATE` | `CONNECTED` or `DISCONNECTED` |
| `MODE` | Current mode, or `IDLE` |
| `ACTIVE` | Comma-separated active channels, or `NONE` |
| `SAFE` | `1` when fail-safe is engaged |

Acknowledgements and errors use the same characteristic, for example `ACK:SET_GPIO;...`, `ERROR:COMMAND_TOO_LONG`, `ERROR:Invalid CH`.

## Safety

GPIO pins drive logic-level inputs only. Use a MOSFET, transistor, relay driver, or optocoupler stage for lamps and other loads. Keep the fail-safe wiring intact so outputs switch off if the phone disconnects. See [BUILD_AND_WIRING_GUIDE_RU.md](BUILD_AND_WIRING_GUIDE_RU.md) before connecting power.
