import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/connection_state_model.dart';
import '../models/controller_profile.dart';
import '../models/light_device.dart';
import '../models/light_group.dart';
import '../models/pattern_config.dart';
import '../services/ble_connection_service.dart';
import '../services/command_codec.dart';
import '../services/controller_connection_service.dart';
import '../services/mock_connection_service.dart';
import '../services/mock_data.dart';
import '../services/profile_exchange_service.dart';
import '../services/profile_storage_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    ControllerConnectionService? connectionService,
    ProfileStorageService? profileStorageService,
    ControllerCommandCodec? commandCodec,
    ProfileExchangeService? profileExchangeService,
    bool enableHeartbeat = true,
  })  : _profileStorageService = profileStorageService ?? ProfileStorageService(),
        _commandCodec = commandCodec ?? ControllerCommandCodec(),
        _profileExchangeService = profileExchangeService ?? ProfileExchangeService(),
        _enableHeartbeat = enableHeartbeat {
    final mobilePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    useMockMode = !mobilePlatform;
    _connectionService = connectionService ??
        (useMockMode ? MockConnectionService() : BleConnectionService());
  }

  late ControllerConnectionService _connectionService;
  final ProfileStorageService _profileStorageService;
  final ControllerCommandCodec _commandCodec;
  final ProfileExchangeService _profileExchangeService;
  final bool _enableHeartbeat;
  final Uuid _uuid = const Uuid();

  StreamSubscription<String>? _incomingSubscription;
  Timer? _heartbeatTimer;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  ThemeMode themeMode = ThemeMode.system;
  bool useMockMode = true;
  bool isBusy = false;
  int currentIndex = 0;
  ConnectionStateModel connection = ConnectionStateModel.initial;
  List<String> discoveredControllers = <String>[];
  List<LightDevice> devices = <LightDevice>[];
  List<LightGroup> groups = <LightGroup>[];
  List<PatternConfig> patterns = <PatternConfig>[];
  List<ControllerProfile> profiles = <ControllerProfile>[];
  String lastLog = 'App started';
  final List<String> logs = <String>['App started'];
  String? selectedPatternId;
  String configChannel = 'FrontLeft';
  int configGpio = 16;
  bool configInverted = false;
  int failSafeMs = 5000;
  final Set<String> activeControlKeys = <String>{};
  static const Map<String, String> _channelToControlKey = <String, String>{
    'FrontLeft': 'front_left',
    'FrontRight': 'front_right',
    'RearLeft': 'rear_left',
    'RearRight': 'rear_right',
    'SideLeft': 'side_left',
    'SideRight': 'side_right',
    'Beacon': 'beacon',
    'Flood': 'flood',
  };

  Future<void> bootstrap() async {
    devices = useMockMode ? MockData.devices() : <LightDevice>[];
    groups = MockData.groups();
    patterns = MockData.patterns();
    profiles = await _profileStorageService.loadProfiles();
    selectedPatternId = patterns.isNotEmpty ? patterns.first.id : null;
    _incomingSubscription = _connectionService.incomingMessages.listen(_handleIncoming);
    connection = connection.copyWith(
      mockMode: useMockMode,
      message: useMockMode
          ? 'Mock mode enabled'
          : 'Ready for Bluetooth Low Energy scan',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _incomingSubscription?.cancel();
    super.dispose();
  }

  void setTab(int index) {
    currentIndex = index;
    notifyListeners();
  }

  /// Appearance follows the system setting. Kept as a no-op so existing
  /// callers compile; the app-level appearance toggle was removed (HIG:
  /// "Avoid offering an app-specific appearance setting").
  void toggleTheme(bool darkMode) {
    // Deliberately does nothing: themeMode stays ThemeMode.system.
  }

  void setMockMode(bool value) {
    if (useMockMode == value) {
      return;
    }
    useMockMode = value;
    _swapConnectionService(value ? MockConnectionService() : BleConnectionService());
    connection = ConnectionStateModel.initial.copyWith(
      mockMode: value,
      message: value ? 'Mock mode enabled' : 'Ready for Bluetooth Low Energy scan',
    );
    discoveredControllers = <String>[];
    devices = value ? MockData.devices() : <LightDevice>[];
    activeControlKeys.clear();
    notifyListeners();
  }

  Future<void> scanControllers() async {
    isBusy = true;
    connection = connection.copyWith(
      status: ControllerConnectionStatus.scanning,
      message: 'Scanning for controllers',
    );
    notifyListeners();

    try {
      // flutter_blue_plus requests the correct BLE permissions itself inside
      // startScan(), for every Android version. No pre-flight request here.
      discoveredControllers = await _connectionService.scan();
      connection = connection.copyWith(
        status: ControllerConnectionStatus.disconnected,
        message: 'Found ${discoveredControllers.length} controller(s)',
      );
    } catch (error) {
      connection = connection.copyWith(
        status: ControllerConnectionStatus.error,
        message: _friendlyBleError(error),
      );
      _log('ERROR:$error');
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> connect(String controllerName) async {
    isBusy = true;
    connection = connection.copyWith(
      status: ControllerConnectionStatus.connecting,
      message: 'Connecting to $controllerName',
    );
    notifyListeners();

    try {
      connection = await _connectionService.connect(controllerName);
      await sendRawCommand(_commandCodec.hello(), critical: true);
      await sendRawCommand(_commandCodec.getConfig(), critical: true);
      _startHeartbeat();
    } catch (error) {
      _stopHeartbeat();
      connection = connection.copyWith(
        status: ControllerConnectionStatus.error,
        message: _friendlyBleError(error),
      );
      _log('ERROR:$error');
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    await sendRawCommand(_commandCodec.allOff(), critical: true);
    connection = await _connectionService.disconnect();
    activeControlKeys.clear();
    notifyListeners();
  }

  Future<void> sendRawCommand(String command, {bool critical = false}) async {
    if (command.trim().isEmpty) {
      return;
    }

    if (connection.status != ControllerConnectionStatus.connected) {
      _log('QUEUED_OFFLINE:$command');
      return;
    }

    final elapsed = DateTime.now().difference(_lastSentAt);
    if (!critical && elapsed.inMilliseconds < 80) {
      return;
    }

    _lastSentAt = DateTime.now();

    try {
      await _connectionService.sendCommand(command);
      _log('TX:$command');
    } catch (error) {
      connection = connection.copyWith(
        status: ControllerConnectionStatus.error,
        message: 'Send failed: $error',
      );
      _log('ERROR:$error');
      notifyListeners();
    }
  }

  Future<void> toggleDevice(String id) async {
    final index = devices.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    devices[index] = devices[index].copyWith(enabled: !devices[index].enabled);
    devices = [...devices];
    notifyListeners();
  }

  Future<void> triggerControl(String controlKey, String command) async {
    if (!useMockMode && connection.status != ControllerConnectionStatus.connected) {
      _log('WARN:Control ignored while disconnected ($controlKey)');
      return;
    }

    if (controlKey == 'all_off') {
      activeControlKeys.clear();
    } else if (activeControlKeys.contains(controlKey)) {
      activeControlKeys.remove(controlKey);
    } else {
      activeControlKeys.add(controlKey);
    }
    notifyListeners();
    await sendRawCommand(command, critical: controlKey == 'all_off');
  }

  void upsertDevice(LightDevice device) {
    final validationError = validateDevice(device);
    if (validationError != null) {
      _log('VALIDATION:$validationError');
      return;
    }

    final index = devices.indexWhere((item) => item.id == device.id);
    if (index == -1) {
      devices = [...devices, device];
    } else {
      devices[index] = device;
      devices = [...devices];
    }
    notifyListeners();
  }

  LightDevice buildDraftDevice() {
    return LightDevice(
      id: _uuid.v4(),
      name: 'New device',
      type: LightDeviceType.custom,
      channel: nextAvailableChannel(),
      group: 'General',
      enabled: true,
      inverted: false,
      brightness: 255,
      mode: 'steady',
      channelCount: 1,
      primaryOutput: devices.length + 1,
    );
  }

  void deleteDevice(String id) {
    devices = devices.where((item) => item.id != id).toList();
    notifyListeners();
  }

  int nextAvailableChannel() {
    if (devices.isEmpty) {
      return 1;
    }
    final maxChannel = devices
        .map((item) => item.channel + item.channelCount)
        .reduce((value, element) => value > element ? value : element);
    return maxChannel;
  }

  String? validateDevice(LightDevice device) {
    if (device.name.trim().isEmpty) {
      return 'Device name is required';
    }
    if (device.channel < 1) {
      return 'Channel must be greater than 0';
    }
    if (device.brightness < 0 || device.brightness > 255) {
      return 'Brightness must be between 0 and 255';
    }
    return null;
  }

  Future<void> activatePattern(String patternId) async {
    selectedPatternId = patternId;
    notifyListeners();
    await sendRawCommand(_buildPatternCommandById(patternId), critical: true);
  }

  Future<void> updatePattern(PatternConfig pattern) async {
    final index = patterns.indexWhere((item) => item.id == pattern.id);
    if (index == -1) {
      patterns = [...patterns, pattern];
    } else {
      patterns[index] = pattern;
      patterns = [...patterns];
    }
    notifyListeners();
    await sendRawCommand(_buildPatternCommand(pattern));
  }

  Future<void> saveCurrentProfile(String name) async {
    final profile = ControllerProfile(
      name: name,
      devices: devices,
      groups: groups,
      patterns: patterns,
      lastUpdated: DateTime.now(),
    );

    final existingIndex = profiles.indexWhere((item) => item.name == name);
    if (existingIndex == -1) {
      profiles = [...profiles, profile];
    } else {
      profiles[existingIndex] = profile;
      profiles = [...profiles];
    }

    await _profileStorageService.saveProfiles(profiles);
    notifyListeners();
  }

  Future<void> loadProfile(String name) async {
    final profile = profiles.cast<ControllerProfile?>().firstWhere(
          (item) => item?.name == name,
          orElse: () => null,
        );
    if (profile == null) {
      return;
    }

    devices = profile.devices;
    groups = profile.groups;
    patterns = profile.patterns;
    selectedPatternId = patterns.isNotEmpty ? patterns.first.id : null;
    notifyListeners();
  }

  Future<void> deleteProfile(String name) async {
    profiles = profiles.where((item) => item.name != name).toList();
    await _profileStorageService.saveProfiles(profiles);
    notifyListeners();
  }

  Future<void> importProfile() async {
    final imported = await _profileExchangeService.importProfile();
    if (imported == null) {
      return;
    }

    final existingIndex = profiles.indexWhere((item) => item.name == imported.name);
    if (existingIndex == -1) {
      profiles = [...profiles, imported];
    } else {
      profiles[existingIndex] = imported;
      profiles = [...profiles];
    }

    await _profileStorageService.saveProfiles(profiles);
    _log('PROFILE_IMPORTED:${imported.name}');
    notifyListeners();
  }

  Future<void> exportProfile(ControllerProfile profile) async {
    await _profileExchangeService.exportProfile(profile);
    _log('PROFILE_EXPORTED:${profile.name}');
  }

  void clearLogs() {
    logs.clear();
    logs.add('Logs cleared');
    lastLog = 'Logs cleared';
    notifyListeners();
  }

  void updateConfigChannel(String channel) {
    configChannel = channel;
    notifyListeners();
  }

  void updateConfigGpio(int gpio) {
    configGpio = gpio;
    notifyListeners();
  }

  void updateConfigInverted(bool value) {
    configInverted = value;
    notifyListeners();
  }

  void updateFailSafeMs(int value) {
    failSafeMs = value;
    notifyListeners();
  }

  String? gpioWarning(int gpio) {
    if (gpio < 0 || gpio > 39) {
      return 'GPIO must be between 0 and 39.';
    }
    if ({34, 35, 36, 39}.contains(gpio)) {
      return 'GPIO$gpio is input-only on ESP32. Do not use it as an output.';
    }
    if ({0, 2, 12, 15}.contains(gpio)) {
      return 'GPIO$gpio is a boot/strapping pin. Avoid it unless you know the board requirements.';
    }
    if ({1, 3}.contains(gpio)) {
      return 'GPIO$gpio is usually Serial TX/RX. Avoid it while using USB Serial diagnostics.';
    }
    return null;
  }

  bool isBlockedOutputGpio(int gpio) => {34, 35, 36, 39}.contains(gpio);

  Future<void> applyControllerGpioConfig() async {
    final warning = gpioWarning(configGpio);
    if (isBlockedOutputGpio(configGpio)) {
      _log('VALIDATION:$warning');
      return;
    }
    if (warning != null) {
      _log('WARN:$warning');
    }
    await sendRawCommand(
      'SET_GPIO;CH=$configChannel;GPIO=$configGpio',
      critical: true,
    );
    await sendRawCommand(
      'SET_INVERT;CH=$configChannel;VALUE=${configInverted ? 1 : 0}',
      critical: true,
    );
  }

  Future<void> applyFailSafeConfig() async {
    final value = failSafeMs.clamp(1000, 60000).toInt();
    failSafeMs = value;
    await sendRawCommand('SET_FAILSAFE;MS=$value', critical: true);
    notifyListeners();
  }

  Future<void> saveControllerConfig() async {
    await sendRawCommand('SAVE_CONFIG', critical: true);
  }

  Future<void> factoryResetControllerConfig() async {
    await sendRawCommand('FACTORY_RESET', critical: true);
  }

  void _swapConnectionService(ControllerConnectionService nextService) {
    _stopHeartbeat();
    _incomingSubscription?.cancel();
    _connectionService = nextService;
    _incomingSubscription = _connectionService.incomingMessages.listen(_handleIncoming);
  }

  void _handleIncoming(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'DISCONNECTED') {
      _stopHeartbeat();
      connection = ConnectionStateModel.initial.copyWith(
        mockMode: useMockMode,
        message: 'BLE disconnected unexpectedly',
      );
      activeControlKeys.clear();
    } else if (normalized == 'CONNECTED') {
      connection = connection.copyWith(
        status: ControllerConnectionStatus.connected,
        message: 'BLE connected',
      );
    } else if (normalized.startsWith('STATE=')) {
      _applyControllerStatus(value);
    }
    _log(value);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (useMockMode || !_enableHeartbeat) {
      return;
    }
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (connection.status != ControllerConnectionStatus.connected) {
        _stopHeartbeat();
        return;
      }
      unawaited(sendRawCommand(_commandCodec.heartbeat(), critical: true));
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _applyControllerStatus(String value) {
    final fields = <String, String>{};
    for (final part in value.split(';')) {
      final separator = part.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final key = part.substring(0, separator).trim().toUpperCase();
      final fieldValue = part.substring(separator + 1).trim();
      fields[key] = fieldValue;
    }

    final safe = fields['SAFE'] == '1';
    final active = fields['ACTIVE'] ?? '';
    if (safe || active.toUpperCase() == 'NONE') {
      activeControlKeys.clear();
    } else if (active.isNotEmpty) {
      activeControlKeys
        ..clear()
        ..addAll(
          active
              .split(',')
              .map((channel) => _channelToControlKey[channel.trim()])
              .whereType<String>(),
        );
    }

    final stateText = fields['STATE']?.toUpperCase();
    if (stateText == 'DISCONNECTED') {
      connection = connection.copyWith(
        status: ControllerConnectionStatus.disconnected,
        message: value,
      );
    } else if (stateText == 'CONNECTED') {
      connection = connection.copyWith(
        status: ControllerConnectionStatus.connected,
        message: value,
      );
    }
  }

  void _log(String value) {
    lastLog = value;
    logs.insert(0, '${DateTime.now().toIso8601String()}  $value');
    if (logs.length > 200) {
      logs.removeRange(200, logs.length);
    }
    notifyListeners();
  }

  String _buildPatternCommandById(String patternId) {
    final pattern = patterns.cast<PatternConfig?>().firstWhere(
          (item) => item?.id == patternId,
          orElse: () => null,
        );
    if (pattern == null) {
      return _commandCodec.strobe(
        channels: ControllerCommandCodec.allChannels,
        onMs: 80,
        offMs: 80,
        repeat: 5,
        seriesPauseMs: 300,
      );
    }
    return _buildPatternCommand(pattern);
  }

  String _buildPatternCommand(PatternConfig pattern) {
    final int onMs = (120 / pattern.speed).clamp(20, 400).round();
    final int offMs = onMs;
    final int pauseMs = pattern.pauseMs.clamp(20, 2000);

    if (pattern.randomMode) {
      return _commandCodec.sequence(
        order: ControllerCommandCodec.allChannels,
        onMs: onMs,
        offMs: offMs,
        seriesPauseMs: pauseMs,
      );
    }

    if (pattern.alternating) {
      return _commandCodec.alternate(
        channels: [
          ...ControllerCommandCodec.frontChannels,
          ...ControllerCommandCodec.rearChannels,
          ...ControllerCommandCodec.sideChannels,
        ],
        onMs: onMs,
        offMs: offMs,
        seriesPauseMs: pauseMs,
      );
    }

    return _commandCodec.strobe(
      channels: ControllerCommandCodec.allChannels,
      onMs: onMs,
      offMs: offMs,
      repeat: 5,
      seriesPauseMs: pauseMs,
    );
  }

  /// Maps the raw PlatformException messages from flutter_blue_plus to text a
  /// person can act on. The plugin owns permission handling; we only translate
  /// its errors, never pre-empt them.
  String _friendlyBleError(Object error) {
    final text = error.toString();

    // Our own timeout while waiting for the adapter to come on.
    if (error is TimeoutException ||
        text.contains('Bluetooth adapter is off or unavailable')) {
      return 'Включите Bluetooth на телефоне и попробуйте снова.';
    }
    if (text.contains('Bluetooth must be turned on')) {
      return 'Включите Bluetooth на телефоне и попробуйте снова.';
    }
    if (text.contains('BLUETOOTH_SCAN') || text.contains('BLUETOOTH_CONNECT')) {
      return 'Нет разрешения Bluetooth. Откройте настройки приложения и включите его.';
    }
    if (text.contains('ACCESS_FINE_LOCATION') ||
        text.contains('location') ||
        text.contains('Location services')) {
      return 'Для поиска BLE нужна геолокация. Включите её в настройках телефона.';
    }
    return 'Не удалось подключиться по Bluetooth. Попробуйте снова.';
  }
}
