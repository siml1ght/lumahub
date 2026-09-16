# LumaHub ESP32 BLE Firmware

Firmware for the ESP32 controller used by LumaHub.

## Libraries
- ESP32 Arduino core
- `BLEDevice.h`
- `BLEServer.h`
- `BLEUtils.h`
- `BLE2902.h`
- `Preferences.h` for ESP32 NVS config storage

## BLE UUIDs
- Service: `5E7A1001-0000-4C0A-B001-112233445566`
- Command: `5E7A1002-0000-4C0A-B001-112233445566`
- Status: `5E7A1003-0000-4C0A-B001-112233445566`

## BLE Name
- `LumaHub-ESP32`

## Commands
- `HELLO`
- `HEARTBEAT`
- `PING`
- `GET_CONFIG`
- `STATUS`
- `STOP`
- `ALL_OFF`
- `SET_GPIO;CH=FrontLeft;GPIO=16`
- `SET_INVERT;CH=Beacon;VALUE=0`
- `SET_FAILSAFE;MS=5000`
- `SAVE_CONFIG`
- `FACTORY_RESET`
- `FrontLeft=ON`
- `RearRight=OFF`
- `MODE=ON;CH=FrontLeft,RearRight`
- `MODE=OFF;GROUP=REAR`
- `MODE=SINGLE_FLASH;CH=FrontLeft;ON=120;OFF=180;REP=3`
- `MODE=DOUBLE_FLASH;CH=Beacon;ON=70;OFF=70;PAUSE=250`
- `MODE=STROBE;CH=FrontLeft,RearRight;ON=80;OFF=80;REP=5;PAUSE=300`
- `MODE=ALTERNATE;CH=FrontLeft,FrontRight,RearLeft,RearRight;ON=90;OFF=90`
- `MODE=SEQUENCE;ORDER=FrontLeft,FrontRight,RearRight,RearLeft;ON=120;OFF=80;PAUSE=300`

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
