import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/entitlements/paywall_memory.dart';
import '../core/entitlements/purchases.dart';
import '../core/rules/free_limit.dart';
import '../core/rules/paywall_triggers.dart';
import 'batch.dart';
import 'config.dart';
import 'state.dart';

T _mustOverride<T>(String name) =>
    throw StateError('$name must be overridden at startup.');

final purchasesServiceProvider = Provider<PurchasesService>(
  (_) => _mustOverride('purchasesService'),
);

final paywallStoreProvider = Provider<PaywallStore>(
  (_) => _mustOverride('paywallStore'),
);

/// Live entitlement; starts from the cache so Pro works offline.
class EntitlementController extends Notifier<Entitlement> {
  StreamSubscription<Entitlement>? _sub;

  @override
  Entitlement build() {
    final service = ref.watch(purchasesServiceProvider);
    _sub?.cancel();
    _sub = service.changes.listen((next) {
      state = next;
      ref.read(paywallProvider.notifier).cachePro(next.isPro);
    });
    ref.onDispose(() => _sub?.cancel());
    final current = service.current;
    final cached = ref.read(paywallStoreProvider).read().cachedPro;
    return current.isPro || !cached ? current : const Entitlement(isPro: true);
  }
}

final entitlementProvider =
    NotifierProvider<EntitlementController, Entitlement>(
      EntitlementController.new,
    );

/// Where a paywall was opened from. Only some count as unrequested (`05` §2).
enum PaywallSource {
  onboarding,
  proChip,
  settings,
  result,
  limit,
  feature,
  upsell,
  removeAds,
}

class PaywallSession {
  const PaywallSession({
    required this.memory,
    this.unrequested = 0,
    this.previousWasPaywall = false,
    this.afterError = false,
    this.errorThisSession = false,
    this.paywallThisSession = false,
  });

  final PaywallMemory memory;
  final int unrequested;
  final bool previousWasPaywall;
  final bool afterError;

  /// Sticky for the whole session; rating (26) never follows either.
  final bool errorThisSession;
  final bool paywallThisSession;

  PaywallSession copyWith({
    PaywallMemory? memory,
    int? unrequested,
    bool? previousWasPaywall,
    bool? afterError,
    bool? errorThisSession,
    bool? paywallThisSession,
  }) {
    return PaywallSession(
      memory: memory ?? this.memory,
      unrequested: unrequested ?? this.unrequested,
      previousWasPaywall: previousWasPaywall ?? this.previousWasPaywall,
      afterError: afterError ?? this.afterError,
      errorThisSession: errorThisSession ?? this.errorThisSession,
      paywallThisSession: paywallThisSession ?? this.paywallThisSession,
    );
  }
}

/// Applies `PaywallTriggers` with real state and remembers what was shown.
class PaywallController extends Notifier<PaywallSession> {
  @override
  PaywallSession build() =>
      PaywallSession(memory: ref.watch(paywallStoreProvider).read());

  Future<void> _remember(PaywallMemory memory) async {
    state = state.copyWith(memory: memory);
    await ref.read(paywallStoreProvider).write(memory);
  }

  /// Call once per cold launch.
  Future<void> startSession() =>
      _remember(state.memory.copyWith(sessions: state.memory.sessions + 1));

  Future<void> cachePro(bool isPro) =>
      _remember(state.memory.copyWith(cachedPro: isPro));

  void noteError() =>
      state = state.copyWith(afterError: true, errorThisSession: true);

  /// A new task started: the "after an error / paywall" guards reset.
  void noteTask() =>
      state = state.copyWith(afterError: false, previousWasPaywall: false);

  void noteClosed() => state = state.copyWith(
    previousWasPaywall: true,
    paywallThisSession: true,
  );

  PaywallContext contextFor(
    PaywallTrigger trigger, {
    bool closingP1 = false,
    int lifetimeFiles = 0,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final config = ref.read(appConfigProvider);
    final entitlement = ref.read(entitlementProvider);
    final memory = state.memory;
    final limit = ref.read(freeLimitProvider);
    final today = FreeLimit.dayKeyFor(moment);
    final trial = entitlement.isTrial && entitlement.expiresAt != null;
    return PaywallContext(
      trigger: trigger,
      isPro: entitlement.isPro,
      busy:
          ref.read(jobProvider.notifier).isRunning ||
          ref.read(batchProvider.notifier).isRunning,
      afterError: state.afterError,
      duringOnboardingQuestions: false,
      unrequestedThisSession: state.unrequested,
      maxUnrequestedPerSession: config.maxUnrequestedPaywallsPerSession,
      previousWasPaywall: state.previousWasPaywall,
      closingP1: closingP1,
      frequency: ref.read(personalizationProvider).frequency,
      p1AlreadyShown: memory.p1Shown,
      conversionsToday: limit.dayKey == today ? limit.usedToday : 0,
      p4ShownToday: memory.p4DayKey == today,
      sessionsSinceP4: memory.p4Session == null
          ? 1 << 20
          : memory.sessions - memory.p4Session!,
      lifetimeFiles: lifetimeFiles,
      heavyUserFiles: config.heavyUserFiles,
      p5AlreadyShown: memory.p5Shown,
      exitOfferEverShown: memory.exitEverShown,
      inTrial: trial,
      trialDay2:
          trial &&
          !moment.isBefore(
            entitlement.expiresAt!.subtract(const Duration(hours: 24)),
          ),
      p7AlreadyShown:
          memory.p7TrialKey != null &&
          memory.p7TrialKey == entitlement.trialStartedAt?.toIso8601String(),
      lapsedAt: entitlement.isPro ? null : entitlement.lapsedAt,
      lastWinBackAt: memory.lastWinBackAt,
      now: moment,
      winBackAfterDays: config.winBackAfterDays,
      winBackCooldownDays: config.winBackCooldownDays,
    );
  }

  bool canShow(
    PaywallTrigger trigger, {
    bool closingP1 = false,
    int lifetimeFiles = 0,
  }) => PaywallTriggers.canShow(
    contextFor(trigger, closingP1: closingP1, lifetimeFiles: lifetimeFiles),
  );

  /// Records an unrequested or capped paywall as shown.
  Future<void> markShown(PaywallTrigger trigger, {DateTime? now}) async {
    final moment = now ?? DateTime.now();
    final memory = state.memory;
    const counted = {
      PaywallTrigger.p1,
      PaywallTrigger.p4,
      PaywallTrigger.p5,
      PaywallTrigger.p8,
    };
    state = state.copyWith(
      paywallThisSession: true,
      unrequested: counted.contains(trigger)
          ? state.unrequested + 1
          : state.unrequested,
    );
    final entitlement = ref.read(entitlementProvider);
    final minutes = ref.read(appConfigProvider).exitOfferMinutes;
    await _remember(switch (trigger) {
      PaywallTrigger.p1 => memory.copyWith(p1Shown: true),
      PaywallTrigger.p4 => memory.copyWith(
        p4DayKey: FreeLimit.dayKeyFor(moment),
        p4Session: memory.sessions,
      ),
      PaywallTrigger.p5 => memory.copyWith(p5Shown: true),
      PaywallTrigger.p6 => memory.copyWith(
        exitShownAt: moment,
        exitEndsAt: moment.add(Duration(minutes: minutes)),
      ),
      PaywallTrigger.p7 => memory.copyWith(
        p7TrialKey: entitlement.trialStartedAt?.toIso8601String(),
      ),
      PaywallTrigger.p8 => memory.copyWith(lastWinBackAt: moment),
      _ => memory,
    });
  }

  Future<void> finishExitOffer() =>
      _remember(state.memory.copyWith(exitDone: true));

  /// The exit offer was shown but the app closed before a choice; its real
  /// timer is still running.
  bool get exitOfferResumable {
    final memory = state.memory;
    final ends = memory.exitEndsAt;
    return memory.exitEverShown &&
        !memory.exitDone &&
        ends != null &&
        ends.isAfter(DateTime.now()) &&
        !ref.read(entitlementProvider).isPro;
  }
}

final paywallProvider = NotifierProvider<PaywallController, PaywallSession>(
  PaywallController.new,
);
