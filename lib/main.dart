import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/account.dart';
import 'app/analytics_sync.dart';
import 'app/batch.dart';
import 'core/account/token_store.dart';
import 'core/diagnostics/crash_reporter.dart';
import 'core/analytics/analytics.dart';
import 'core/analytics/events.dart';
import 'app/config.dart';
import 'app/monetization.dart';
import 'app/router.dart';
import 'app/state.dart';
import 'core/engine/audio_engine.dart';
import 'core/entitlements/paywall_memory.dart';
import 'core/entitlements/purchases.dart';
import 'core/entitlements/storekit_purchases.dart';
import 'core/library/app_database.dart';
import 'core/library/app_paths.dart';
import 'core/library/picked_store.dart';
import 'core/library/preferences_store.dart';
import 'core/library/usage_store.dart';
import 'core/notifications/trial_reminder.dart';
import 'features/paywall/checkout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final crashes = await createCrashReporter();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashes.record(details.exception, details.stack, fatal: true);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    crashes.record(error, stack, fatal: true);
    return true;
  };
  _registerCodecLicences();
  final config = await AppConfig.load();
  final paths = AppPaths.fromSystem();
  final db = AppDatabase.file(paths.databaseFile);
  final freeLimit = await UsageStore(db).readFreeLimit(DateTime.now());
  final sharedPrefs = await SharedPreferences.getInstance();
  final prefsStore = PreferencesStore(sharedPrefs);
  final pickedStore = PickedStore(sharedPrefs, paths);
  final purchases = _purchasesService();
  await purchases.init();
  final reminder = LocalTrialReminder();
  final analytics = await createAnalytics(
    euResidency: config.analyticsEuResidency,
  );

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      appPathsProvider.overrideWithValue(paths),
      appDatabaseProvider.overrideWithValue(db),
      initialFreeLimitProvider.overrideWithValue(freeLimit),
      preferencesStoreProvider.overrideWithValue(prefsStore),
      pickedStoreProvider.overrideWithValue(pickedStore),
      purchasesServiceProvider.overrideWithValue(purchases),
      paywallStoreProvider.overrideWithValue(PaywallStore(sharedPrefs)),
      trialReminderProvider.overrideWithValue(reminder),
      analyticsProvider.overrideWithValue(analytics),
      tokenStoreProvider.overrideWithValue(SecureTokenStore()),
    ],
  );
  final router = createRouter(
    onboarded: container.read(preferencesProvider).onboardingDone,
  );
  await reminder.init(
    onOpened: () => router.push('/trial-reminder', extra: 'push'),
    onBatchOpened: () => router.go('/files'),
  );
  await container.read(paywallProvider.notifier).startSession();
  await container.read(freeLimitProvider.notifier).refresh();
  unawaited(container.read(analyticsSyncProvider).start());
  analytics.appOpened(
    source: await reminder.openedFromReminder ? 'notification' : 'icon',
  );
  unawaited(() async {
    try {
      final engine = container.read(audioEngineProvider);
      final restored = <SourceFile>[];
      for (final entry in pickedStore.read()) {
        if (!await File(entry.path).exists()) continue;
        try {
          final info = await engine.inspect(entry.path);
          final thumb =
              info.hasVideo ? await engine.thumbnail(entry.path) : null;
          restored.add(
            SourceFile(
              path: entry.path,
              name: entry.name.isEmpty
                  ? entry.path.split('/').last
                  : entry.name,
              info: info,
              thumbnailPath: thumb,
            ),
          );
        } on Object {
          // Drop unreadable leftovers.
        }
      }
      if (restored.isEmpty) return;
      container.read(pickedSourcesProvider.notifier).replaceAll(restored);
      await pickedStore.write([
        for (final s in restored) (path: s.path, name: s.name),
      ]);
    } on Object {
      // Keep going if a leftover can't be inspected.
    }
  }());

  DateTime? backgroundedAt;
  AppLifecycleListener(
    onPause: () => backgroundedAt = DateTime.now(),
    onResume: () {
      container.read(freeLimitProvider.notifier).refresh();
      container.read(batchProvider.notifier).resumeIfPaused();
      final away = backgroundedAt;
      if (away != null &&
          DateTime.now().difference(away) >= const Duration(minutes: 30)) {
        analytics.appOpened(source: 'icon');
      }
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TunelyApp(router: router),
    ),
  );

  unawaited(
    container
        .read(audioEngineProvider)
        .cleanTemp(olderThanHours: config.tempMaxAgeHours)
        .catchError((_) {}),
  );
}

/// StoreKit products from App Store Connect (or `Tunely.storekit` in debug).
PurchasesService _purchasesService() => StoreKitPurchases();

/// LAME (LGPL) and libogg/libvorbis (BSD) on Settings › Licences.
void _registerCodecLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (package, asset) in [
      ('LAME', 'assets/licenses/lame.txt'),
      ('libogg, libvorbis', 'assets/licenses/vorbis.txt'),
    ]) {
      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks([package], text);
    }
  });
}
