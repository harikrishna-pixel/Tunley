import 'package:flutter_test/flutter_test.dart';
import 'package:tunely/core/diagnostics/crash_reporter.dart';

void main() {
  test('paths, file names and emails never reach crash reports', () {
    const message =
        "FileSystemException: Cannot open file, path = '/var/mobile/Containers/"
        "Data/Application/X/Documents/Library/Dance night.mp3' (anna@example.com)"
        ' Concert_clip.mov';
    final out = redact(message);
    expect(out, isNot(contains('/var')));
    expect(out, isNot(contains('.mp3')));
    expect(out, isNot(contains('.mov')));
    expect(out, isNot(contains('anna@')));
    expect(out, contains('FileSystemException'));
  });

  test('debug reporter records redacted errors', () {
    final reporter = DebugCrashReporter();
    reporter.record(StateError('bad /tmp/a.m4a'), null);
    expect(reporter.recorded.single, isNot(contains('/tmp')));
  });
}
