import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/features/errors/error_screen.dart';

void main() {
  test('fixed error codes from 05 §6, VFR only for decode/encode failures', () {
    expect(audCode(EngineErrorCode.decode), 'AUD-DEC-01');
    expect(audCode(EngineErrorCode.encode), 'AUD-ENC-03');
    expect(audCode(EngineErrorCode.interrupted), 'AUD-INT-04');
    expect(audCode(EngineErrorCode.io), 'AUD-IO-05');
    expect(
      const ErrorArgs(EngineErrorCode.decode, variableFrameRate: true).audCode,
      'AUD-VFR-02',
    );
    expect(
      const ErrorArgs(EngineErrorCode.io, variableFrameRate: true).audCode,
      'AUD-IO-05',
    );
  });
}
