import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash and non-fatal error reporting. Never sends file names or paths.
abstract class CrashReporter {
  void record(Object error, StackTrace? stack, {bool fatal = false});
}

/// Paths and file names out of error messages before anything leaves the
/// device (`.cursor/rules`: no file names, paths or personal data in logs).
String redact(String message) => message
    .replaceAll(RegExp(r'''(file://)?/[^\s'":,)]+'''), '<path>')
    .replaceAll(
      RegExp(
        r'\S+\.(mp3|m4a|m4r|wav|flac|aac|ogg|mov|mp4|m4v|caf|aif{1,2})\b',
        caseSensitive: false,
      ),
      '<file>',
    )
    .replaceAll(RegExp(r'\S+@\S+\.\w+'), '<email>');

class _Redacted {
  _Redacted(this.original);

  final Object original;

  @override
  String toString() =>
      '${original.runtimeType}: ${redact(original.toString())}';
}

class CrashlyticsReporter implements CrashReporter {
  @override
  void record(Object error, StackTrace? stack, {bool fatal = false}) {
    FirebaseCrashlytics.instance.recordError(
      _Redacted(error),
      stack,
      fatal: fatal,
    );
  }
}

class DebugCrashReporter implements CrashReporter {
  final List<String> recorded = [];

  @override
  void record(Object error, StackTrace? stack, {bool fatal = false}) {
    final line = '${fatal ? 'fatal' : 'error'}: ${_Redacted(error)}';
    recorded.add(line);
    if (kDebugMode) debugPrint('crash $line');
  }
}

/// Crashlytics needs `ios/Runner/GoogleService-Info.plist` (Firebase
/// project); without it `Firebase.initializeApp` aborts natively, so it is
/// only started with `--dart-define=CRASHLYTICS=true`.
Future<CrashReporter> createCrashReporter() async {
  const enabled = bool.fromEnvironment('CRASHLYTICS');
  if (!enabled) return DebugCrashReporter();
  try {
    await Firebase.initializeApp();
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    return CrashlyticsReporter();
  } on Object {
    return DebugCrashReporter();
  }
}
