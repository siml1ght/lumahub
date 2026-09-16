#include "BLEHandler.h"

BLEHandler::BLEHandler(BLEHandlerListener& listener) : _listener(listener) {}

void BLEHandler::begin() {
  BLEDevice::init(Config::kDeviceName);
  _server = BLEDevice::createServer();
  _server->setCallbacks(new ServerCallbacks(*this));

  BLEService* service = _server->createService(Config::kServiceUuid);

  _commandCharacteristic = service->createCharacteristic(
      Config::kCommandCharacteristicUuid, BLECharacteristic::PROPERTY_WRITE);
  _commandCharacteristic->setCallbacks(new CommandCallbacks(*this));

  _statusCharacteristic = service->createCharacteristic(
      Config::kStatusCharacteristicUuid,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  _statusCharacteristic->addDescriptor(new BLE2902());
  _statusCharacteristic->setValue("BOOT");

  service->start();

  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(Config::kServiceUuid);
  advertising->setScanResponse(true);
  advertising->setMinPreferred(0x06);
  advertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.print("BLE advertising started as ");
  Serial.println(Config::kDeviceName);
}

void BLEHandler::updateStatus(const String& statusText) {
  if (_statusCharacteristic == nullptr) {
    return;
  }

  _statusCharacteristic->setValue(statusText.c_str());
  _statusCharacteristic->notify();
}

void BLEHandler::ServerCallbacks::onConnect(BLEServer* server) {
  _owner._listener.onBleConnected();
  _owner.updateStatus("CONNECTED");
}

void BLEHandler::ServerCallbacks::onDisconnect(BLEServer* server) {
  _owner._listener.onBleDisconnected();
  _owner.updateStatus("DISCONNECTED");
  BLEDevice::startAdvertising();
}

void BLEHandler::CommandCallbacks::onWrite(BLECharacteristic* characteristic) {
  const auto raw = characteristic->getValue();
  if (raw.empty()) {
    return;
  }
  if (raw.length() > Config::kMaxCommandLength) {
    _owner.updateStatus("ERROR:COMMAND_TOO_LONG");
    return;
  }
  _owner._listener.onBleCommand(String(raw.c_str()));
}
