import 'package:shared_preferences/shared_preferences.dart';

import '../engine/audio_engine.dart';
import '../rules/personalization.dart';

/// Onboarding answers and defaults the user can change in Settings.
class UserPrefs {
  const UserPrefs({
    required this.onboardingDone,
    required this.goals,
    required this.frequency,
    required this.defaultFormat,
    required this.defaultKbps,
    this.lastFormat,
  });

  static const initial = UserPrefs(
    onboardingDone: false,
    goals: {},
    frequency: UsageFrequency.fewTimesAWeek,
    defaultFormat: OutFormat.mp3,
    defaultKbps: 256,
  );

  final bool onboardingDone;

  /// One or more goals from O2 (multi-select). [goal] is the primary for
  /// personalisation (hero, paywall header).
  final Set<UserGoal> goals;
  final UsageFrequency frequency;
  final OutFormat defaultFormat;
  final int defaultKbps;

  /// Last audio format converted to ("Convert files" goal starts from it).
  final OutFormat? lastFormat;

  /// Primary goal: first match in product order among the selected set.
  UserGoal get goal {
    for (final candidate in const [
      UserGoal.ringtones,
      UserGoal.mp3FromVideos,
      UserGoal.convertFiles,
    ]) {
      if (goals.contains(candidate)) return candidate;
    }
    return UserGoal.ringtones;
  }

  UserPrefs copyWith({
    bool? onboardingDone,
    Set<UserGoal>? goals,
    UsageFrequency? frequency,
    OutFormat? defaultFormat,
    int? defaultKbps,
    OutFormat? lastFormat,
  }) {
    return UserPrefs(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      goals: goals ?? this.goals,
      frequency: frequency ?? this.frequency,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultKbps: defaultKbps ?? this.defaultKbps,
      lastFormat: lastFormat ?? this.lastFormat,
    );
  }
}

class PreferencesStore {
  PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _onboarding = 'onboarding_done';
  static const _goal = 'goal';
  static const _goals = 'goals';
  static const _frequency = 'frequency';
  static const _format = 'default_format';
  static const _kbps = 'default_kbps';
  static const _last = 'last_format';

  T _enum<T extends Enum>(List<T> values, String key, T fallback) {
    final raw = _prefs.getString(key);
    return values.where((v) => v.name == raw).firstOrNull ?? fallback;
  }

  Set<UserGoal> _readGoals() {
    final raw = _prefs.getStringList(_goals);
    if (raw != null) {
      return {
        for (final name in raw)
          ...UserGoal.values.where((goal) => goal.name == name),
      };
    }
    // Older builds stored a single `goal` string.
    if (_prefs.containsKey(_goal)) {
      return {_enum(UserGoal.values, _goal, UserGoal.ringtones)};
    }
    return {};
  }

  UserPrefs read() {
    const d = UserPrefs.initial;
    final last = _prefs.getString(_last);
    return UserPrefs(
      onboardingDone: _prefs.getBool(_onboarding) ?? false,
      goals: _readGoals(),
      frequency: _enum(UsageFrequency.values, _frequency, d.frequency),
      defaultFormat: _enum(OutFormat.values, _format, d.defaultFormat),
      defaultKbps: _prefs.getInt(_kbps) ?? d.defaultKbps,
      lastFormat: OutFormat.values.where((f) => f.name == last).firstOrNull,
    );
  }

  Future<void> write(UserPrefs prefs) async {
    await _prefs.setBool(_onboarding, prefs.onboardingDone);
    await _prefs.setStringList(
      _goals,
      prefs.goals.map((goal) => goal.name).toList(),
    );
    // Only persist the legacy single-goal key once a goal is chosen, so O2
    // never comes back with a default selection from the fallback.
    if (prefs.goals.isEmpty) {
      await _prefs.remove(_goal);
    } else {
      await _prefs.setString(_goal, prefs.goal.name);
    }
    await _prefs.setString(_frequency, prefs.frequency.name);
    await _prefs.setString(_format, prefs.defaultFormat.name);
    await _prefs.setInt(_kbps, prefs.defaultKbps);
    if (prefs.lastFormat != null) {
      await _prefs.setString(_last, prefs.lastFormat!.name);
    }
  }
}
