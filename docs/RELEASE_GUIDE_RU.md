# Как выпускать LumaHub APK через GitHub Release

Этот проект настроен так, чтобы GitHub автоматически собирал LumaHub APK и прикреплял его к релизу.

## Где находится APK

Открой раздел Releases текущего репозитория:

https://github.com/siml1ght/strobesystem-controller/releases

Файл для установки на телефон:

- `LumaHub-android.apk`

Дополнительные файлы релиза:

- `LumaHub-ESP32-firmware.zip` — прошивка ESP32.
- `LumaHub-sources.zip` — исходники приложения, прошивки, документы и примеры.

## Как выпустить новую версию

1. Убедись, что все изменения отправлены в `main`.
2. Выбери номер версии, например `v0.1.1`.
3. В PowerShell из папки проекта выполни:

```powershell
git tag v0.1.1
git push origin v0.1.1
```

4. GitHub Actions автоматически запустит сборку.
5. После успешной сборки появится новый Release с LumaHub APK.

## Как выпустить APK без тега

1. Открой репозиторий на GitHub.
2. Перейди во вкладку **Actions**.
3. Выбери workflow **Build LumaHub APK and publish release**.
4. Нажми **Run workflow**.
5. В поле `tag` можно указать, например, `v0.1.1-test`.
6. GitHub соберёт APK и прикрепит его к релизу.

## Что проверяет GitHub перед сборкой APK

```text
flutter pub get
flutter analyze
flutter test --coverage
flutter build apk --release
```

Если один из этапов завершается с ошибкой, релиз не публикуется.

## Что передавать для установки или сборки

Для установки приложения на Android:

- открой ссылку на Release;
- скачай `LumaHub-android.apk`;
- установи APK;
- выполняй BLE-подключение внутри LumaHub, а не через системное меню Bluetooth.

Для прошивки ESP32:

- скачай `LumaHub-ESP32-firmware.zip`;
- открой `.ino` в Arduino IDE;
- прошей ESP32 по инструкции из архива.

Для доступа ко всем исходникам скачай `LumaHub-sources.zip`.

## Важно по безопасности

- Перед подключением к машине сначала проверь систему на LED или мультиметре.
- ESP32 GPIO не должны питать нагрузку напрямую.
- Для автомобильной нагрузки нужны MOSFET, реле или драйверы, предохранитель, общий GND и защита питания.
- При потере связи прошивка должна выключить выходы через fail-safe.
