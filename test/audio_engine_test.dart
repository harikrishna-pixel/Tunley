import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely_engine/tunely_engine.dart';

class _FailingApi extends EngineApi {
  _FailingApi(this.code);

  final String code;

  @override
  Future<MediaInfo> inspect(String path) async {
    throw PlatformException(code: code, message: 'native message');
  }
}

void main() {
  test('every native error code maps to a typed code', () {
    const wire = {
      'unreadable': EngineErrorCode.unreadable,
      'no_audio': EngineErrorCode.noAudio,
      'protected': EngineErrorCode.protected,
      'icloud': EngineErrorCode.icloud,
      'no_space': EngineErrorCode.noSpace,
      'interrupted': EngineErrorCode.interrupted,
      'cancelled': EngineErrorCode.cancelled,
      'decode': EngineErrorCode.decode,
      'encode': EngineErrorCode.encode,
      'io': EngineErrorCode.io,
      'stale_bookmark': EngineErrorCode.staleBookmark,
      'unavailable': EngineErrorCode.unavailable,
      'something_new': EngineErrorCode.unknown,
    };
    wire.forEach((code, expected) {
      expect(EngineErrorCode.fromWire(code), expected, reason: code);
    });
  });

  test('platform errors surface as EngineException', () async {
    final engine = PigeonAudioEngine(api: _FailingApi('no_audio'));
    await expectLater(
      engine.inspect('/tmp/video.mov'),
      throwsA(
        isA<EngineException>()
            .having((e) => e.code, 'code', EngineErrorCode.noAudio)
            .having((e) => e.message, 'message', 'native message'),
      ),
    );
  });
}
