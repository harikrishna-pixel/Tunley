import '../engine/audio_engine.dart';
import '../entitlements/purchases.dart';
import '../rules/personalization.dart';
import '../rules/ringtone_rules.dart';

/// Property values exactly as listed in `08`.
abstract final class AnalyticsValues {
  static String goal(UserGoal goal) => switch (goal) {
    UserGoal.ringtones => 'ringtone',
    UserGoal.mp3FromVideos => 'mp3',
    UserGoal.convertFiles => 'convert',
  };

  static String frequency(UsageFrequency frequency) => switch (frequency) {
    UsageFrequency.everyDay => 'daily',
    UsageFrequency.fewTimesAWeek => 'weekly',
    UsageFrequency.onceInAWhile => 'rarely',
  };

  static String format(OutFormat format) => format.name;

  static String mode(ConvertMode mode) => switch (mode) {
    ConvertMode.audioFile => 'audio',
    ConvertMode.ringtone => 'ringtone',
  };

  static String toneType(ToneType type) => switch (type) {
    ToneType.ringtone => 'ringtone',
    ToneType.alarm => 'alarm',
    ToneType.textTone => 'text',
  };

  /// `task_failed.error_type`.
  static String errorType(EngineErrorCode code) => switch (code) {
    EngineErrorCode.decode || EngineErrorCode.unreadable => 'decode',
    EngineErrorCode.encode => 'encode',
    EngineErrorCode.io || EngineErrorCode.noSpace => 'io',
    EngineErrorCode.interrupted => 'interrupted',
    _ => 'unknown',
  };

  /// `error_shown.type`.
  static String errorScreen(EngineErrorCode code) => switch (code) {
    EngineErrorCode.noSpace => 'no_storage',
    EngineErrorCode.icloud => 'icloud',
    EngineErrorCode.protected => 'drm',
    EngineErrorCode.noAudio => 'no_audio',
    EngineErrorCode.staleBookmark => 'stale_folder',
    _ => 'conversion_failed',
  };

  static String planKind(PlanKind kind) => switch (kind) {
    PlanKind.weekly => 'weekly',
    PlanKind.yearly => 'yearly',
    PlanKind.lifetime => 'lifetime',
    PlanKind.exit => 'yearly_exit',
    PlanKind.winBack => 'yearly_winback',
  };

  /// User/super property `plan`: none · trial · weekly · yearly ·
  /// yearly_exit · yearly_winback · lifetime. [lastKind] is the plan bought
  /// on this device (win-back shares the yearly product).
  static String plan(Entitlement e, {PlanKind? lastKind}) {
    if (!e.isPro) return 'none';
    if (e.isTrial) return 'trial';
    final id = e.productId ?? '';
    if (id.contains('lifetime')) return 'lifetime';
    if (id.contains('weekly')) return 'weekly';
    if (id.contains('exit')) return 'yearly_exit';
    if (lastKind == PlanKind.winBack) return 'yearly_winback';
    return 'yearly';
  }
}
