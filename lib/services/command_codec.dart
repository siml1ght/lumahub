/// Encodes app actions into the text protocol understood by the ESP32 firmware.
///
/// The wire format is a sequence of `KEY=VALUE` pairs separated by `;`.
/// A standalone command is a single word (HELLO, STATUS, ALL_OFF, ...).
class ControllerCommandCodec {
  static const frontChannels = ['FrontLeft', 'FrontRight'];
  static const rearChannels = ['RearLeft', 'RearRight'];
  static const sideChannels = ['SideLeft', 'SideRight'];
  static const allChannels = [
    'FrontLeft',
    'FrontRight',
    'RearLeft',
    'RearRight',
    'SideLeft',
    'SideRight',
    'Beacon',
    'Flood',
  ];

  static const _patternDefaults = {
    'strobe': 'MODE=STROBE;GROUP=ALL;ON=80;OFF=80;REP=5;PAUSE=300',
    'alternate': 'MODE=ALTERNATE;GROUP=ALL;ON=80;OFF=80;PAUSE=300',
    'sequence': 'MODE=SEQUENCE;ORDER=FrontLeft,FrontRight,RearLeft,RearRight;ON=80;OFF=80;PAUSE=300',
  };

  String hello() => 'HELLO';
  String heartbeat() => 'HEARTBEAT';
  String ping() => 'PING';
  String getConfig() => 'GET_CONFIG';
  String status() => 'STATUS';
  String stop() => 'STOP';

  /// Persists the controller's runtime config to NVS.
  String saveProfile() => 'SAVE_CONFIG';

  /// The firmware stores one active config in NVS. `GET_CONFIG` returns it;
  /// the profile name is an app-side concept and is not sent over the wire.
  String loadProfile(String name) => 'GET_CONFIG';

  String allOff() => 'ALL_OFF';

  /// Builds a pattern command from a known pattern id, falling back to strobe.
  String pattern(String patternId) =>
      _patternDefaults[patternId.toLowerCase()] ?? _patternDefaults['strobe']!;

  String on(String id) => '$id=ON';
  String off(String id) => '$id=OFF';

  String setGroup(String groupName, bool on) =>
      'MODE=${on ? 'ON' : 'OFF'};GROUP=$groupName';

  String setChannels(List<String> channels, bool on) =>
      'MODE=${on ? 'ON' : 'OFF'};CH=${channels.join(',')}';

  /// Sets the GPIO pin for a channel (runtime, persist with [saveProfile]).
  String setGpio(String channel, int gpio) =>
      'SET_GPIO;CH=$channel;GPIO=$gpio';

  /// Sets channel polarity. `true` inverts the output.
  String setInvert(String channel, bool invert) =>
      'SET_INVERT;CH=$channel;VALUE=${invert ? 1 : 0}';

  /// Sets the disconnect fail-safe timeout in milliseconds.
  String setFailSafe(int ms) => 'SET_FAILSAFE;MS=$ms';

  String factoryReset() => 'FACTORY_RESET';

  String strobe({
    required List<String> channels,
    required int onMs,
    required int offMs,
    required int repeat,
    required int seriesPauseMs,
  }) {
    return 'MODE=STROBE;CH=${channels.join(',')};ON=$onMs;OFF=$offMs;REP=$repeat;PAUSE=$seriesPauseMs';
  }

  String alternate({
    required List<String> channels,
    required int onMs,
    required int offMs,
    required int seriesPauseMs,
  }) {
    return 'MODE=ALTERNATE;CH=${channels.join(',')};ON=$onMs;OFF=$offMs;PAUSE=$seriesPauseMs';
  }

  String sequence({
    required List<String> order,
    required int onMs,
    required int offMs,
    required int seriesPauseMs,
  }) {
    return 'MODE=SEQUENCE;ORDER=${order.join(',')};ON=$onMs;OFF=$offMs;PAUSE=$seriesPauseMs';
  }

  /// Splits a key/value command into a map.
  ///
  /// Protocol uses `;` between pairs and `=` between key and value, e.g.
  /// `MODE=ON;CH=FrontLeft`. A single word such as `STATUS` yields an
  /// empty payload.
  Map<String, String> parseIncoming(String raw) {
    final result = <String, String>{};
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return result;

    for (final token in trimmed.split(';')) {
      final separator = token.indexOf('=');
      if (separator <= 0) continue;
      final key = token.substring(0, separator).trim();
      final value = token.substring(separator + 1).trim();
      if (key.isEmpty) continue;
      result[key] = value;
    }

    if (result.isEmpty) {
      result['command'] = trimmed;
    }
    return result;
  }
}
