import 'package:shared_preferences/shared_preferences.dart';

/// Everything paywall caps need to remember across launches (`05` §2).
class PaywallMemory {
  const PaywallMemory({
    this.sessions = 0,
    this.p1Shown = false,
    this.exitShownAt,
    this.exitEndsAt,
    this.exitDone = false,
    this.p4DayKey,
    this.p4Session,
    this.p5Shown = false,
    this.p7TrialKey,
    this.lastWinBackAt,
    this.cachedPro = false,
  });

  final int sessions;
  final bool p1Shown;
  final DateTime? exitShownAt;

  /// Real persisted end of the 10-minute exit offer.
  final DateTime? exitEndsAt;

  /// Claimed or dismissed: never shown again.
  final bool exitDone;
  final String? p4DayKey;
  final int? p4Session;
  final bool p5Shown;

  /// Trial start the P7 reminder was shown for.
  final String? p7TrialKey;
  final DateTime? lastWinBackAt;

  /// Last known entitlement so Pro works offline.
  final bool cachedPro;

  bool get exitEverShown => exitShownAt != null;

  PaywallMemory copyWith({
    int? sessions,
    bool? p1Shown,
    DateTime? exitShownAt,
    DateTime? exitEndsAt,
    bool? exitDone,
    String? p4DayKey,
    int? p4Session,
    bool? p5Shown,
    String? p7TrialKey,
    DateTime? lastWinBackAt,
    bool? cachedPro,
  }) {
    return PaywallMemory(
      sessions: sessions ?? this.sessions,
      p1Shown: p1Shown ?? this.p1Shown,
      exitShownAt: exitShownAt ?? this.exitShownAt,
      exitEndsAt: exitEndsAt ?? this.exitEndsAt,
      exitDone: exitDone ?? this.exitDone,
      p4DayKey: p4DayKey ?? this.p4DayKey,
      p4Session: p4Session ?? this.p4Session,
      p5Shown: p5Shown ?? this.p5Shown,
      p7TrialKey: p7TrialKey ?? this.p7TrialKey,
      lastWinBackAt: lastWinBackAt ?? this.lastWinBackAt,
      cachedPro: cachedPro ?? this.cachedPro,
    );
  }
}

class PaywallStore {
  PaywallStore(this._prefs);

  final SharedPreferences _prefs;
  static const _prefix = 'paywall.';

  DateTime? _date(String key) {
    final ms = _prefs.getInt('$_prefix$key');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  PaywallMemory read() {
    return PaywallMemory(
      sessions: _prefs.getInt('${_prefix}sessions') ?? 0,
      p1Shown: _prefs.getBool('${_prefix}p1') ?? false,
      exitShownAt: _date('exitShownAt'),
      exitEndsAt: _date('exitEndsAt'),
      exitDone: _prefs.getBool('${_prefix}exitDone') ?? false,
      p4DayKey: _prefs.getString('${_prefix}p4Day'),
      p4Session: _prefs.getInt('${_prefix}p4Session'),
      p5Shown: _prefs.getBool('${_prefix}p5') ?? false,
      p7TrialKey: _prefs.getString('${_prefix}p7Trial'),
      lastWinBackAt: _date('winBack'),
      cachedPro: _prefs.getBool('${_prefix}pro') ?? false,
    );
  }

  Future<void> write(PaywallMemory m) async {
    Future<void> date(String key, DateTime? value) async {
      if (value != null) {
        await _prefs.setInt('$_prefix$key', value.millisecondsSinceEpoch);
      }
    }

    await _prefs.setInt('${_prefix}sessions', m.sessions);
    await _prefs.setBool('${_prefix}p1', m.p1Shown);
    await date('exitShownAt', m.exitShownAt);
    await date('exitEndsAt', m.exitEndsAt);
    await _prefs.setBool('${_prefix}exitDone', m.exitDone);
    if (m.p4DayKey != null) {
      await _prefs.setString('${_prefix}p4Day', m.p4DayKey!);
    }
    if (m.p4Session != null) {
      await _prefs.setInt('${_prefix}p4Session', m.p4Session!);
    }
    await _prefs.setBool('${_prefix}p5', m.p5Shown);
    if (m.p7TrialKey != null) {
      await _prefs.setString('${_prefix}p7Trial', m.p7TrialKey!);
    }
    await date('winBack', m.lastWinBackAt);
    await _prefs.setBool('${_prefix}pro', m.cachedPro);
  }
}
