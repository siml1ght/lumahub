# Гайд: безопасный тест LumaHub на обычных LED

Цель этого режима: проверить приложение, BLE-связь, прошивку ESP32, кнопки и паттерны без подключения к машине, без 12V и без силовой нагрузки.

Это первый обязательный тест перед MOSFET, реле, стробами и автомобильной проводкой.

## 1. Что нужно

- ESP32 DevKit.
- 8 обычных светодиодов 3 мм или 5 мм.
- 8 резисторов `220-330 Ом`.
- Макетная плата или пайка на временную плату.
- USB-кабель для питания ESP32.
- Android-телефон с `LumaHub-release.apk`.

Не нужны:

- 12V питание.
- MOSFET-модули.
- Реле.
- Подключение к машине.
- Реальные строб-модули.
- LED-ленты или автомобильные LED-модули.

## 2. Главное правило

Светодиод нельзя подключать напрямую к GPIO ESP32.

Всегда ставь резистор последовательно со светодиодом:

```text
GPIO ESP32 -> резистор 220-330 Ом -> длинная ножка LED
короткая ножка LED -> GND ESP32
```

Если перепутать ножки LED, он обычно просто не загорится. Если убрать резистор, можно повредить GPIO или светодиод.

Для этого теста используй только маленькие индикаторные LED. LED-ленты, автомобильные лампы, мощные светодиодные модули и любые 12V устройства нельзя питать от GPIO ESP32.

## 3. Распиновка для теста

Прошивка уже настроена под эти 8 каналов:

| Канал в приложении | GPIO ESP32 | Что подключить |
|---|---:|---|
| `FrontLeft` | GPIO16 | LED через резистор |
| `FrontRight` | GPIO17 | LED через резистор |
| `RearLeft` | GPIO18 | LED через резистор |
| `RearRight` | GPIO19 | LED через резистор |
| `SideLeft` | GPIO21 | LED через резистор |
| `SideRight` | GPIO22 | LED через резистор |
| `Beacon` | GPIO23 | LED через резистор |
| `Flood` | GPIO25 | LED через резистор |

Общий провод всех LED идет на `GND ESP32`.

## 4. Схема одного канала

Пример для `FrontLeft`:

```text
ESP32 GPIO16
  |
  | провод
  |
[резистор 220-330 Ом]
  |
  | длинная ножка LED (+)
[LED]
  | короткая ножка LED (-)
  |
ESP32 GND
```

Для остальных каналов схема такая же, меняется только GPIO.

## 5. Настройка прошивки

Открой:

```text
firmware/esp32_ble_controller/Config.h
```

Для LED-теста должны остаться такие настройки:

```cpp
constexpr uint8_t kChannelPins[kChannelCount] = {16, 17, 18, 19, 21, 22, 23, 25};
constexpr bool kChannelInverted[kChannelCount] = {
    false, false, false, false, false, false, false, false};
```

`false` означает: GPIO HIGH включает LED, GPIO LOW выключает LED. Для обычного подключения через резистор это правильно.

## 6. Прошивка ESP32

1. Открой Arduino IDE.
2. Установи пакет плат `ESP32 by Espressif Systems`.
3. Открой файл:

```text
firmware/esp32_ble_controller/esp32_ble_controller.ino
```

4. Выбери плату `ESP32 Dev Module`.
5. Выбери COM-порт ESP32.
6. Нажми `Upload`.
7. Открой `Serial Monitor`.
8. Скорость поставь `115200`.
9. После перезапуска должно быть видно `READY`.

При старте прошивка также печатает карту:

```text
GPIO MAP:
  FrontLeft -> GPIO16
  FrontRight -> GPIO17
  RearLeft -> GPIO18
  RearRight -> GPIO19
  SideLeft -> GPIO21
  SideRight -> GPIO22
  Beacon -> GPIO23
  Flood -> GPIO25
```

Если Arduino IDE пишет `Wrong boot mode detected` или `Failed to connect to ESP32`, код уже скомпилировался, но плата не вошла в режим загрузки:

1. Нажми `Upload`.
2. Когда появится `Connecting...`, зажми кнопку `BOOT` на ESP32.
3. Держи `BOOT`, пока не начнется `Writing at...` или загрузка в процентах.
4. Отпусти `BOOT`.
5. Если не помогло, нажми и отпусти `EN`/`RST`, затем снова попробуй `Upload` с зажатым `BOOT`.
6. Поставь `Upload Speed` в Arduino IDE на `115200`.
7. Проверь, что USB-кабель передает данные, а не только питание.
8. На время прошивки отключи все провода от ESP32, кроме USB. LED можно подключить после успешной прошивки.

## 7. Установка приложения

1. Установи на Android:

```text
dist/LumaHub-release.apk
```

2. Включи Bluetooth.
3. Дай приложению разрешения Bluetooth и Location.
4. Открой вкладку `Connect`.
5. Нажми `Scan Controllers`.
6. Выбери только устройство:

```text
ESP32-StrobeCtrl
```

7. Нажми `Connect`.

Если в списке есть телевизоры, наушники или лампы, их не выбирай. Нужен именно `ESP32-StrobeCtrl`.

Если `ESP32-StrobeCtrl` не появляется после `Scan Controllers`:

1. Проверь в `Serial Monitor`, что есть `STATUS: READY`.
2. Проверь, что после старта есть строка `BLE advertising started as ESP32-StrobeCtrl`.
3. Выключи и включи Bluetooth на телефоне.
4. Полностью закрой приложение и открой заново.
5. Проверь разрешения Android: Bluetooth scan, Bluetooth connect и Location должны быть разрешены.
6. В настройках Android включи геолокацию. На части Android BLE scan без включенной геолокации не показывает устройства.
7. Не подключайся к ESP32 через системное меню Bluetooth. BLE-подключение должно идти из приложения.
8. Если не помогло, перезагрузи ESP32 кнопкой `EN`/`RST` и снова нажми `Scan Controllers`.

## 8. Первый ручной тест

Во вкладке `Control`:

1. Нажми `Front Left`.
2. LED на GPIO16 должен включиться.
3. Нажми `Front Left` еще раз.
4. LED должен выключиться.
5. Нажми `Beacon`.
6. LED на GPIO23 должен включиться.
7. Нажми `All Off`.
8. Все LED должны выключиться.

Если LED не горит:

- проверь, что короткая ножка LED идет на `GND`;
- проверь резистор;
- проверь номер GPIO;
- проверь, что приложение подключено именно к `ESP32-StrobeCtrl`;
- проверь `Serial Monitor`.

Точная таблица для мультиметра:

| Кнопка в приложении | Команда | Пин ESP32 | Ожидаемо OFF | Ожидаемо ON |
|---|---|---:|---:|---:|
| `Front Left` | `FrontLeft=ON/OFF` | GPIO16 | около `0V` | около `3.0-3.3V` |
| `Front Right` | `FrontRight=ON/OFF` | GPIO17 | около `0V` | около `3.0-3.3V` |
| `Rear Left` | `RearLeft=ON/OFF` | GPIO18 | около `0V` | около `3.0-3.3V` |
| `Rear Right` | `RearRight=ON/OFF` | GPIO19 | около `0V` | около `3.0-3.3V` |
| `Side Left` | `SideLeft=ON/OFF` | GPIO21 | около `0V` | около `3.0-3.3V` |
| `Side Right` | `SideRight=ON/OFF` | GPIO22 | около `0V` | около `3.0-3.3V` |
| `Beacon` | `Beacon=ON/OFF` | GPIO23 | около `0V` | около `3.0-3.3V` |
| `Flood` | `Flood=ON/OFF` | GPIO25 | около `0V` | около `3.0-3.3V` |

Как мерить:

1. Мультиметр поставь в `DC V`, диапазон `20V`.
2. Черный щуп держи на `GND ESP32`.
3. Красным щупом касайся нужного GPIO из таблицы.
4. Нажимай соответствующую кнопку в приложении.

В `Serial Monitor` при нажатии должно появляться, например:

```text
RX: FrontLeft=ON
PARSED: type=ImmediateOn mode=IDLE onMs=80 offMs=80 repeat=5 pauseMs=300 speedPercent=100
CHANNEL_MASK: 0b00000001 channels=FrontLeft
GPIO_WRITE: channel=FrontLeft gpio=16 logical=ON inverted=false pinLevel=HIGH readback=HIGH
STATUS: STATE=CONNECTED;MODE=ON;ACTIVE=FrontLeft;SAFE=0
GPIO_STATE_SNAPSHOT:
  channel=FrontLeft gpio=16 logical=ON readback=HIGH
```

Если `GPIO_WRITE: channel=FrontLeft gpio=16 ... readback=HIGH` есть, а на измеряемом контакте `0V`, значит щуп стоит не на GPIO16 или контакт на плате выбран неверно.

Если не получается найти нужный контакт, используй `Pin Scan` во вкладке `Control`.

`Pin Scan` включает каналы по очереди:

```text
FrontLeft  / GPIO16 -> 3 секунды ON
FrontRight / GPIO17 -> 3 секунды ON
RearLeft   / GPIO18 -> 3 секунды ON
RearRight  / GPIO19 -> 3 секунды ON
SideLeft   / GPIO21 -> 3 секунды ON
SideRight  / GPIO22 -> 3 секунды ON
Beacon     / GPIO23 -> 3 секунды ON
Flood      / GPIO25 -> 3 секунды ON
```

Во время `Pin Scan` держи черный щуп на `GND`, а красным по очереди проверяй пины. Где появляется `3.0-3.3V`, там сейчас активный выход.

## 9. Тест паттернов

После ручного теста можно проверять режимы:

1. Открой `Patterns`.
2. Выбери строб или alternating pattern.
3. Нажми запуск паттерна.
4. LED должны мигать без зависаний.
5. Нажми `All Off` или `STOP`.
6. Все LED должны сразу выключиться.

Для ручной проверки через BLE-команды прошивка понимает (полный справочник — в [PROTOCOL.md](PROTOCOL.md)):

```text
HELLO
GET_CONFIG
HEARTBEAT
MODE=STROBE;CH=FrontLeft,RearRight;ON=80;OFF=80;REP=5;PAUSE=300
MODE=ALTERNATE;CH=FrontLeft,FrontRight;ON=80;OFF=80;PAUSE=300
MODE=SEQUENCE;ORDER=FrontLeft,FrontRight,RearLeft,RearRight;ON=80;OFF=80;PAUSE=200
ALL_OFF
STOP
STATUS
PING
```

Настройки ESP32 можно менять командами:

```text
SET_GPIO;CH=FrontLeft;GPIO=16
SET_INVERT;CH=Beacon;VALUE=0
SET_FAILSAFE;MS=5000
SAVE_CONFIG
FACTORY_RESET
```

Эти настройки сохраняются в NVS-памяти ESP32 и переживают перезагрузку.

## 10. Тест fail-safe

1. Включи любой LED через приложение.
2. Выключи Bluetooth на телефоне или уйди из зоны связи.
3. Через fail-safe таймаут все LED должны выключиться.
4. Включи Bluetooth обратно.
5. Подключись заново.
6. Нажми `All Off`.

Если LED остается включенным после потери связи, не переходи к реальным стробам. Сначала надо разбираться с прошивкой, питанием или BLE-соединением.

## 11. Когда можно переходить к машине

Переходить к MOSFET/реле и 12V можно только если выполнено все:

- каждый LED включается своей кнопкой;
- `All Off` выключает все LED;
- паттерны работают без зависаний;
- после перезагрузки ESP32 все LED выключены;
- при потере BLE все LED выключаются;
- выбранные GPIO совпадают с таблицей в `Config.h`.

До этого этапа к машине ничего не подключать.

## 12. Что сказать другу

Для первого запуска пусть делает именно LED-тест:

1. Прошить ESP32.
2. Подключить 1 LED к GPIO16 через резистор.
3. Проверить `Front Left`.
4. Потом подключить остальные LED.
5. Проверить `All Off`.
6. Проверить потерю Bluetooth.
7. Только после этого думать про MOSFET и 12V.
