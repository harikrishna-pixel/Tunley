import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// The only way features send analytics (`08`). Swap the provider (Amplitude,
/// PostHog…) by adding one class that implements this and returning it from
/// `createAnalytics`. Never put file names, paths or personal data in
/// properties.
abstract class Analytics {
  void track(String event, [Map<String, Object?> properties = const {}]);

  /// Profile properties (`08` › User properties).
  void setUserProps(Map<String, Object?> properties);

  /// Sent with every event (`08` › Rules).
  void setSuperProps(Map<String, Object?> properties);

  /// `distinct_id` = RevenueCat `appUserID`.
  void identify(String id);
  void reset();
}

Map<String, Object> _clean(Map<String, Object?> properties) => {
  for (final e in properties.entries)
    if (e.value != null) e.key: e.value!,
};

/// Mixpanel: no automatic events, IP not used for geolocation, US or EU
/// residency from `app_config.json`.
class MixpanelAnalytics implements Analytics {
  MixpanelAnalytics._(this._mixpanel);

  final Mixpanel _mixpanel;

  static Future<MixpanelAnalytics> create(
    String token, {
    required bool euResidency,
  }) async {
    final mixpanel = await Mixpanel.init(
      token,
      trackAutomaticEvents: false,
      serverURL: euResidency ? 'https://api-eu.mixpanel.com' : null,
    );
    mixpanel.setUseIpAddressForGeolocation(false);
    return MixpanelAnalytics._(mixpanel);
  }

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    _mixpanel.track(event, properties: _clean(properties));
  }

  @override
  void setUserProps(Map<String, Object?> properties) {
    final people = _mixpanel.getPeople();
    for (final e in _clean(properties).entries) {
      people.set(e.key, e.value);
    }
  }

  @override
  void setSuperProps(Map<String, Object?> properties) {
    _mixpanel.registerSuperProperties(_clean(properties));
  }

  @override
  void identify(String id) => _mixpanel.identify(id);

  @override
  void reset() => _mixpanel.reset();
}

/// In-memory list for the Component gallery. Console printing is off so
/// `flutter run` stays quiet until Mixpanel is wired later.
class DebugAnalytics implements Analytics {
  DebugAnalytics({this.log = false});

  final bool log;
  final events = ValueNotifier<List<(String, Map<String, Object>)>>(const []);
  final Map<String, Object> superProps = {};
  final Map<String, Object> userProps = {};
  String? distinctId;

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    final clean = _clean(properties);
    events.value = [(event, clean), ...events.value.take(199)];
    if (log) debugPrint('analytics: $event $clean');
  }

  @override
  void setUserProps(Map<String, Object?> properties) =>
      userProps.addAll(_clean(properties));

  @override
  void setSuperProps(Map<String, Object?> properties) =>
      superProps.addAll(_clean(properties));

  @override
  void identify(String id) => distinctId = id;

  @override
  void reset() {
    distinctId = null;
    superProps.clear();
    userProps.clear();
  }
}

/// Tunely-Dev token for debug builds, Tunely for release, from
/// `--dart-define`. Without a token, events stay local.
Future<Analytics> createAnalytics({required bool euResidency}) async {
  const dev = String.fromEnvironment('MIXPANEL_TOKEN_DEV');
  const prod = String.fromEnvironment('MIXPANEL_TOKEN');
  final token = kReleaseMode ? prod : dev;
  if (token.isEmpty) return DebugAnalytics();
  try {
    return await MixpanelAnalytics.create(token, euResidency: euResidency);
  } on Object {
    return DebugAnalytics();
  }
}

/// Overridden in `main` with `createAnalytics`.
final analyticsProvider = Provider<Analytics>((_) => DebugAnalytics());
