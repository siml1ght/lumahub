#pragma once

#include <Arduino.h>

namespace Config {
constexpr char kDeviceName[] = "LumaHub-ESP32";
constexpr char kServiceUuid[] = "5E7A1001-0000-4C0A-B001-112233445566";
constexpr char kCommandCharacteristicUuid[] =
    "5E7A1002-0000-4C0A-B001-112233445566";
constexpr char kStatusCharacteristicUuid[] =
    "5E7A1003-0000-4C0A-B001-112233445566";

constexpr size_t kMaxCommandLength = 180;
constexpr uint8_t kChannelCount = 8;
constexpr unsigned long kDisconnectSafeTimeoutMs = 5000;
constexpr unsigned long kMinDisconnectSafeTimeoutMs = 1000;
constexpr unsigned long kMaxDisconnectSafeTimeoutMs = 60000;
constexpr unsigned long kDefaultPulseOnMs = 80;
constexpr unsigned long kDefaultPulseOffMs = 80;
constexpr unsigned long kDefaultSeriesPauseMs = 300;
constexpr uint16_t kDefaultRepeat = 5;
constexpr uint8_t kMaxSequenceLength = kChannelCount;

constexpr uint8_t kChannelPins[kChannelCount] = {16, 17, 18, 19, 21, 22, 23, 25};
constexpr bool kChannelInverted[kChannelCount] = {
    false, false, false, false, false, false, false, false};
}  // namespace Config
