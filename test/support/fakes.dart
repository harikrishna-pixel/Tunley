import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/app/account.dart';
import 'package:tunely/app/ads.dart';
import 'package:tunely/core/account/account_api.dart';
import 'package:tunely/core/account/token_store.dart';
import 'package:tunely/app/config.dart';
import 'package:tunely/core/ads/ads_service.dart';
import 'package:tunely/core/analytics/analytics.dart';
import 'package:tunely/app/state.dart';
import 'package:tunely/core/engine/audio_engine.dart';
import 'package:tunely/core/library/app_database.dart';
import 'package:tunely/core/library/app_paths.dart';
import 'package:tunely/core/library/preferences_store.dart';
import 'package:tunely/app/monetization.dart';
import 'package:tunely/core/entitlements/paywall_memory.dart';
import 'package:tunely/core/entitlements/purchases.dart';
import 'package:tunely/core/notifications/trial_reminder.dart';
import 'package:tunely/features/paywall/checkout.dart';
import 'package:tunely/core/rules/free_limit.dart';

AppConfig loadConfig() {
  final json = jsonDecode(
    File('assets/config/app_config.json').readAsStringSync(),
  );
  return AppConfig.fromJson(json as Map<String, dynamic>);
}

MediaInfo fakeInfo({
  String path = '/tmp/clip.mov',
  double seconds = 42,
  bool hasAudio = true,
  bool hasVideo = true,
  int bytes = 86 * 1024 * 1024,
}) {
  return MediaInfo(
    path: path,
    bytes: bytes,
    durationSec: seconds,
    hasAudio: hasAudio,
    hasVideo: hasVideo,
    isProtected: false,
    isLocal: true,
    sourceBitrate: 256,
    sampleRate: 44100,
    channels: 2,
    container: 'mov',
  );
}

/// Writes a real output file so "output exists" checks pass.
class FakeEngine implements AudioEngine {
  FakeEngine(this.outputDir);

  final Directory outputDir;
  EngineErrorCode? failWith;

  /// Inputs that fail with [failPathsWith] (batch tests).
  final Set<String> failPaths = {};
  EngineErrorCode failPathsWith = EngineErrorCode.decode;
  bool deleteOutput = false;
  final _progress = StreamController<ProgressEvent>.broadcast();
  final List<ConvertRequest> requests = [];

  @override
  Future<ConvertResult> convert(String jobId, ConvertRequest request) async {
    requests.add(request);
    _progress.add(ProgressEvent(jobId: jobId, fraction: 0.5));
    await Future<void>.delayed(Duration.zero);
    if (failWith != null) throw EngineException(failWith!);
    if (failPaths.contains(request.inputs.first)) {
      throw EngineException(failPathsWith);
    }
    final ext = request.format.name;
    final file = File('${outputDir.path}/Library/${request.outputName}.$ext');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List.filled(1000, 1));
    if (deleteOutput) await file.delete();
    return ConvertResult(
      jobId: jobId,
      outputPath: file.path,
      outputBytes: 1000,
      seconds: 30,
    );
  }

  void emit(String jobId, double fraction) =>
      _progress.add(ProgressEvent(jobId: jobId, fraction: fraction));

  @override
  Stream<ProgressEvent> progress(String jobId) =>
      _progress.stream.where((e) => e.jobId == jobId);

  @override
  Future<void> cancel(String jobId) async =>
      failWith = EngineErrorCode.cancelled;

  @override
  Future<int> freeBytes() async => 10 * 1024 * 1024 * 1024;

  @override
  Future<MediaInfo> inspect(String path) async => fakeInfo(path: path);

  @override
  Future<List<double>> waveform(String path, {int buckets = 48}) async =>
      List.filled(buckets, 0.5);

  @override
  Future<String?> thumbnail(String path, {int maxPixels = 300}) async => null;

  @override
  Future<Set<OutFormat>> availableFormats() async => OutFormat.values.toSet();

  List<String> picked = const [];
  int? lastPickMax;

  @override
  Future<List<String>> pickVideos({int maxCount = 1}) async {
    lastPickMax = maxCount;
    return picked.take(maxCount).toList();
  }

  @override
  Future<String?> pickFolder() async => null;

  @override
  Future<String?> bookmarkedFolderName(String bookmarkId) async => null;

  @override
  Future<bool> bookmarkedFolderIsICloud(String bookmarkId) async => true;

  @override
  Future<String> copyToBookmarkedFolder(String path, String bookmarkId) async =>
      path.split('/').last;

  @override
  Future<void> cleanTemp({int olderThanHours = 24}) async {}

  final List<String> openedUrls = [];
  String osVersion = '26.0';

  @override
  Future<bool> openUrl(String url) async {
    openedUrls.add(url);
    return true;
  }

  bool continuedStarted = false;

  @override
  Future<bool> startContinuedBatch(String title) async =>
      continuedStarted = osVersion.startsWith('26');

  @override
  Future<void> updateContinuedBatch(
    int completed,
    int total,
    String subtitle,
  ) async {}

  @override
  Future<void> finishContinuedBatch({required bool success}) async =>
      continuedFinished = success;

  bool? continuedFinished;

  /// Already answered, so app-level tests don't get 44 at launch.
  String tracking = 'authorized';
  int trackingRequests = 0;
  final List<String> storePages = [];

  @override
  Future<String> trackingStatus() async => tracking;

  @override
  Future<String> requestTracking() async {
    trackingRequests++;
    return tracking = 'denied';
  }

  String? deviceToken = 'device-token-1';

  @override
  Future<String?> deviceCheckToken() async => deviceToken;

  @override
  Future<bool> openAppStorePage(String appStoreId) async {
    storePages.add(appStoreId);
    return true;
  }

  @override
  Future<AppInfo> appInfo() async =>
      AppInfo(version: '1.0.0', build: '1', osVersion: osVersion);
}

class MemoryPreferencesStore implements PreferencesStore {
  MemoryPreferencesStore([UserPrefs? initial])
    : value = initial ?? UserPrefs.initial.copyWith(onboardingDone: true);

  UserPrefs value;

  @override
  UserPrefs read() => value;

  @override
  Future<void> write(UserPrefs prefs) async => value = prefs;
}

class MemoryPaywallStore implements PaywallStore {
  PaywallMemory value = const PaywallMemory();

  @override
  PaywallMemory read() => value;

  @override
  Future<void> write(PaywallMemory memory) async => value = memory;
}

class FakeTrialReminder implements TrialReminder {
  bool allowed = true;

  /// Current system state; null follows [allowed].
  bool? granted;
  DateTime? scheduledAt;
  bool cancelled = false;

  @override
  Future<void> init({
    required void Function() onOpened,
    void Function()? onBatchOpened,
  }) async {}

  final batchNotifications = <String>[];
  int permissionRequests = 0;

  @override
  Future<void> notifyBatchDone({
    required String title,
    required String body,
  }) async => batchNotifications.add(body);

  @override
  Future<bool> get openedFromReminder async => false;

  @override
  Future<bool> notificationsAllowed() async => granted ?? allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    granted = allowed;
    return allowed;
  }

  @override
  Future<void> schedule(
    DateTime at, {
    required String title,
    required String body,
  }) async => scheduledAt = at;

  @override
  Future<void> cancel() async => cancelled = true;
}

/// Records everything; analytics never leaves unit tests (`08` › QA).
class FakeAnalytics implements Analytics {
  final List<(String, Map<String, Object?>)> events = [];
  final Map<String, Object?> superProps = {};
  final Map<String, Object?> userProps = {};
  String? distinctId;

  List<String> get names => [for (final e in events) e.$1];

  Map<String, Object?> last(String name) =>
      events.lastWhere((e) => e.$1 == name).$2;

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) =>
      events.add((event, properties));

  @override
  void setUserProps(Map<String, Object?> properties) =>
      userProps.addAll(properties);

  @override
  void setSuperProps(Map<String, Object?> properties) =>
      superProps.addAll(properties);

  @override
  void identify(String id) => distinctId = id;

  @override
  void reset() => distinctId = null;
}

class FakeAds implements AdsService {
  bool loaded = true;
  bool rewardOnShow = true;
  int interstitials = 0;
  int rewardeds = 0;

  @override
  String get provider => 'fake';

  @override
  Future<bool> init() async => true;

  @override
  Future<void> load(AdFormat format) async {}

  @override
  bool isReady(AdFormat format) => loaded;

  @override
  Future<bool> showInterstitial() async {
    if (!loaded) return false;
    interstitials++;
    return true;
  }

  @override
  Future<bool> showRewarded({required void Function() onReward}) async {
    if (!loaded) return false;
    rewardeds++;
    if (rewardOnShow) onReward();
    return true;
  }
}

/// Container with an in-memory database and a temp app container.
ProviderContainer testContainer({
  AudioEngine? engine,
  DateTime? today,
  PreferencesStore? prefs,
  PurchasesService? purchases,
  PaywallStore? paywall,
  TrialReminder? reminder,
  AdsService? ads,
  Analytics? analytics,
  AccountApi? accountApi,
  TokenStore? tokens,
}) {
  final dir = Directory.systemTemp.createTempSync('tunely_test');
  final day = FreeLimit.dayKeyFor(today ?? DateTime.now());
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(loadConfig()),
      appPathsProvider.overrideWithValue(AppPaths(dir.path)),
      appDatabaseProvider.overrideWithValue(AppDatabase.memory()),
      initialFreeLimitProvider.overrideWithValue(
        FreeLimitSnapshot(
          usedToday: 0,
          rewardedToday: 0,
          dayKey: day,
          maxDayKey: day,
        ),
      ),
      preferencesStoreProvider.overrideWithValue(
        prefs ?? MemoryPreferencesStore(),
      ),
      purchasesServiceProvider.overrideWithValue(
        purchases ?? DemoPurchasesService(),
      ),
      paywallStoreProvider.overrideWithValue(paywall ?? MemoryPaywallStore()),
      trialReminderProvider.overrideWithValue(reminder ?? FakeTrialReminder()),
      adsServiceProvider.overrideWithValue(ads ?? FakeAds()),
      analyticsProvider.overrideWithValue(analytics ?? FakeAnalytics()),
      accountApiProvider.overrideWithValue(accountApi ?? DemoAccountApi()),
      tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
      if (engine != null) audioEngineProvider.overrideWithValue(engine),
    ],
  );
  return container;
}
