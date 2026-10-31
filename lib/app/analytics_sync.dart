import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics.dart';
import '../core/analytics/values.dart';
import '../core/engine/audio_engine.dart';
import '../core/library/usage_store.dart';
import '../features/paywall/checkout.dart';
import 'monetization.dart';
import 'state.dart';

/// Keeps super and user properties (`08`) in step with the app: updated on
/// launch and whenever entitlement, preferences, session or theme change.
class AnalyticsSync with WidgetsBindingObserver {
  AnalyticsSync(this._ref);

  final Ref _ref;
  final List<ProviderSubscription<Object?>> _subs = [];
  bool _observing = false;
  Analytics get _analytics => _ref.read(analyticsProvider);

  Future<void> start() async {
    final usage = _ref.read(usageStoreProvider);
    final engine = _ref.read(audioEngineProvider);
    final info = await engine.appInfo();
    final iosMajor = osMajor(info);
    final id = await _ref.read(purchasesServiceProvider).appUserId();
    if (id != null) _analytics.identify(id);

    _analytics.setSuperProps({
      'app_version': info.version,
      'ios_version': info.osVersion,
    });
    final installed = await usage.installedAt();
    _analytics.setUserProps({
      'first_open_date': installed.toIso8601String().substring(0, 10),
      'ios_major': iosMajor,
      'files_made_total': await usage.lifetimeConversions(),
      'ringtones_made_total': await usage.ringtonesSaved(),
      'notifications_enabled': await _ref
          .read(trialReminderProvider)
          .notificationsAllowed(),
    });

    _syncPrefs();
    await _syncEntitlement();
    _syncSession();
    _syncTheme();
    _subs
      ..add(_ref.listen(preferencesProvider, (_, _) => _syncPrefs()))
      ..add(
        _ref.listen(
          entitlementProvider,
          (_, _) => unawaited(_syncEntitlement()),
        ),
      )
      ..add(
        _ref.listen(
          paywallProvider.select((s) => s.memory.sessions),
          (_, _) => _syncSession(),
        ),
      );
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    if (_observing) WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangePlatformBrightness() => _syncTheme();

  void _syncPrefs() {
    final p = _ref.read(personalizationProvider);
    final props = {
      'goal': AnalyticsValues.goal(p.goal),
      'frequency': AnalyticsValues.frequency(p.frequency),
    };
    _analytics
      ..setSuperProps(props)
      ..setUserProps(props);
  }

  Future<void> refreshEntitlement() => _syncEntitlement();

  Future<void> _syncEntitlement() async {
    final entitlement = _ref.read(entitlementProvider);
    final last = await _ref.read(usageStoreProvider).lastPlanKind();
    final props = {
      'is_pro': entitlement.isPro,
      'plan': AnalyticsValues.plan(entitlement, lastKind: last),
    };
    _analytics
      ..setSuperProps(props)
      ..setUserProps(props);
  }

  void _syncSession() => _analytics.setSuperProps({
    'session_number': _ref.read(paywallProvider).memory.sessions,
  });

  void _syncTheme() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _analytics.setSuperProps({
      'theme': brightness == Brightness.dark ? 'dark' : 'light',
    });
  }

  /// After each `task_completed`.
  Future<void> updateTotals() async {
    final usage = _ref.read(usageStoreProvider);
    _analytics.setUserProps({
      'files_made_total': await usage.lifetimeConversions(),
      'ringtones_made_total': await usage.ringtonesSaved(),
    });
  }

  void notificationsEnabled(bool enabled) =>
      _analytics.setUserProps({'notifications_enabled': enabled});
}

final analyticsSyncProvider = Provider<AnalyticsSync>((ref) {
  final sync = AnalyticsSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});
