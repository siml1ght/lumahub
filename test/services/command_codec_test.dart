import 'package:flutter_test/flutter_test.dart';
import 'package:strobe_controller_mobile/services/command_codec.dart';

void main() {
  group('ControllerCommandCodec', () {
    final codec = ControllerCommandCodec();

    test('builds strobe command with required parameters', () {
      final command = codec.strobe(
        channels: const ['FrontLeft', 'RearRight'],
        onMs: 80,
        offMs: 90,
        repeat: 4,
        seriesPauseMs: 250,
      );

      expect(
        command,
        'MODE=STROBE;CH=FrontLeft,RearRight;ON=80;OFF=90;REP=4;PAUSE=250',
      );
    });

    test('builds alternate and sequence commands', () {
      expect(
        codec.alternate(
          channels: const ['FrontLeft', 'FrontRight'],
          onMs: 60,
          offMs: 60,
          seriesPauseMs: 100,
        ),
        'MODE=ALTERNATE;CH=FrontLeft,FrontRight;ON=60;OFF=60;PAUSE=100',
      );

      expect(
        codec.sequence(
          order: const ['FrontLeft', 'RearLeft', 'Beacon'],
          onMs: 50,
          offMs: 70,
          seriesPauseMs: 120,
        ),
        'MODE=SEQUENCE;ORDER=FrontLeft,RearLeft,Beacon;ON=50;OFF=70;PAUSE=120',
      );
    });

    test('encodes firmware control commands', () {
      expect(codec.saveProfile(), 'SAVE_CONFIG');
      expect(codec.loadProfile('night-run'), 'GET_CONFIG');
      expect(codec.factoryReset(), 'FACTORY_RESET');
      expect(codec.setGpio('FrontLeft', 16), 'SET_GPIO;CH=FrontLeft;GPIO=16');
      expect(codec.setInvert('Beacon', true), 'SET_INVERT;CH=Beacon;VALUE=1');
      expect(codec.setInvert('Beacon', false), 'SET_INVERT;CH=Beacon;VALUE=0');
      expect(codec.setFailSafe(5000), 'SET_FAILSAFE;MS=5000');
      expect(codec.stop(), 'STOP');
    });

    test('pattern ids map to known firmware patterns', () {
      expect(codec.pattern('strobe'), contains('MODE=STROBE'));
      expect(codec.pattern('alternate'), contains('MODE=ALTERNATE'));
      expect(codec.pattern('sequence'), contains('MODE=SEQUENCE'));
      expect(codec.pattern('unknown'), contains('MODE=STROBE'));
      expect(codec.pattern('STROBE'), contains('MODE=STROBE'));
    });

    test('parses key/value pairs using the firmware delimiter', () {
      expect(
        codec.parseIncoming('MODE=ON;CH=FrontLeft,RearRight'),
        {'MODE': 'ON', 'CH': 'FrontLeft,RearRight'},
      );
      expect(codec.parseIncoming('STATUS'), {'command': 'STATUS'});
      expect(codec.parseIncoming('SET_GPIO;CH=FrontLeft;GPIO=16'), {
        'CH': 'FrontLeft',
        'GPIO': '16',
      });
      expect(codec.parseIncoming(''), isEmpty);
    });
  });
}
