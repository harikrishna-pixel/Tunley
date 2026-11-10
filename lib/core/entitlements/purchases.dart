import 'dart:async';

/// Plans from `07`. Product IDs live in App Store Connect.
enum PlanKind { yearly, weekly, lifetime, exit, winBack }

/// App Store Connect product IDs for the Flutter paywall.
/// Prefixed IDs are canonical; short IDs are accepted if the dashboard
/// was set up with them first.
abstract final class ProductIds {
  static const weekly = 'com.marberx.audioconverter.pro.weekly';
  static const yearly = 'com.marberx.audioconverter.pro.yearly';
  static const lifetime = 'com.marberx.audioconverter.pro.lifetime';
  static const exit = 'com.marberx.audioconverter.pro.yearly.exit';

  static const weeklyShort = 'audioconverter.pro.weekly';
  static const yearlyShort = 'audioconverter.pro.yearly';
  static const lifetimeShort = 'audioconverter.pro.lifetime';
  static const exitShort = 'audioconverter.pro.yearly.exit';

  static const all = {
    weekly,
    yearly,
    lifetime,
    exit,
    weeklyShort,
    yearlyShort,
    lifetimeShort,
    exitShort,
  };

  static String canonical(PlanKind kind) => switch (kind) {
    PlanKind.weekly => weekly,
    PlanKind.yearly || PlanKind.winBack => yearly,
    PlanKind.lifetime => lifetime,
    PlanKind.exit => exit,
  };

  static List<String> aliases(PlanKind kind) => switch (kind) {
    PlanKind.weekly => const [weekly, weeklyShort],
    PlanKind.yearly || PlanKind.winBack => const [yearly, yearlyShort],
    PlanKind.lifetime => const [lifetime, lifetimeShort],
    PlanKind.exit => const [exit, exitShort],
  };
}

/// One purchasable plan with the store's own localized prices.
class StorePlan {
  const StorePlan({
    required this.kind,
    required this.productId,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.trialDays,
    this.introPrice,
    this.introPriceString,
    this.introEligible = false,
  });

  final PlanKind kind;
  final String productId;
  final double price;
  final String priceString;
  final String currencyCode;

  /// Free-trial length when the product has one (yearly: 3).
  final int? trialDays;

  /// Paid introductory or win-back price for the first period.
  final double? introPrice;
  final String? introPriceString;

  /// From `checkTrialOrIntroductoryPriceEligibility` before every paywall.
  final bool introEligible;

  /// Free trial is Yearly only (`07`); Weekly / Lifetime never show trial copy.
  bool get showsTrial =>
      kind == PlanKind.yearly && trialDays != null && introEligible;
}

enum OfferingId { main, exit, winBack }

class Entitlement {
  const Entitlement({
    required this.isPro,
    this.productId,
    this.isTrial = false,
    this.willRenew = false,
    this.expiresAt,
    this.trialStartedAt,
    this.lapsedAt,
    this.managementUrl,
  });

  static const free = Entitlement(isPro: false);

  final bool isPro;
  final String? productId;
  final bool isTrial;
  final bool willRenew;
  final DateTime? expiresAt;
  final DateTime? trialStartedAt;

  /// When a former subscription ended (P8 win-back).
  final DateTime? lapsedAt;
  final String? managementUrl;

  bool get isLifetime => isPro && expiresAt == null;
}

enum PurchaseOutcome {
  success,
  cancelled,
  pending,
  failed,
  offline,
  unavailable,
}

enum RestoreOutcome { restored, none, offline, failed }

/// The app's only door to purchases. StoreKit in production.
abstract class PurchasesService {
  Entitlement get current;
  Stream<Entitlement> get changes;

  Future<void> init();
  Future<List<StorePlan>> plans(OfferingId offering);
  Future<PurchaseOutcome> purchase(StorePlan plan);
  Future<RestoreOutcome> restore();

  /// Optional analytics id. StoreKit has none; Pro stays with the Apple ID.
  Future<String?> appUserId();

  /// Optional account link. StoreKit ignores this; Pro stays with the Apple ID.
  Future<void> logIn(String accountId);

  /// Debug / widget-test only. Production callers no-op unless overridden.
  Future<void> setDebugPro(bool enabled) async {}
}

/// Nothing to sell (tests, or the store is unreachable).
class UnavailablePurchasesService implements PurchasesService {
  @override
  Entitlement get current => Entitlement.free;

  @override
  Stream<Entitlement> get changes => const Stream.empty();

  @override
  Future<void> init() async {}

  @override
  Future<List<StorePlan>> plans(OfferingId offering) async => const [];

  @override
  Future<PurchaseOutcome> purchase(StorePlan plan) async =>
      PurchaseOutcome.unavailable;

  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.offline;

  @override
  Future<String?> appUserId() async => null;

  @override
  Future<void> logIn(String accountId) async {}

  @override
  Future<void> setDebugPro(bool enabled) async {}
}

/// Widget-test stand-in. The running app uses StoreKit (`StoreKitPurchases`).
class DemoPurchasesService implements PurchasesService {
  DemoPurchasesService({this.trialEligible = true});

  final bool trialEligible;
  final _changes = StreamController<Entitlement>.broadcast();
  Entitlement _current = Entitlement.free;

  @override
  Future<String?> appUserId() async => r'$RCAnonymousID:demo';

  String? loggedInAs;

  @override
  Future<void> logIn(String accountId) async => loggedInAs = accountId;

  @override
  Entitlement get current => _current;

  @override
  Stream<Entitlement> get changes => _changes.stream;

  @override
  Future<void> init() async {}

  @override
  Future<List<StorePlan>> plans(OfferingId offering) async {
    // Intended US prices from 07; real builds read them from the store.
    return switch (offering) {
      OfferingId.main => [
        StorePlan(
          kind: PlanKind.yearly,
          productId: ProductIds.yearly,
          price: 29.99,
          priceString: r'$29.99',
          currencyCode: 'USD',
          trialDays: 3,
          introEligible: trialEligible,
        ),
        const StorePlan(
          kind: PlanKind.weekly,
          productId: ProductIds.weekly,
          price: 4.99,
          priceString: r'$4.99',
          currencyCode: 'USD',
        ),
        const StorePlan(
          kind: PlanKind.lifetime,
          productId: ProductIds.lifetime,
          price: 39.99,
          priceString: r'$39.99',
          currencyCode: 'USD',
        ),
      ],
      OfferingId.exit => [
        StorePlan(
          kind: PlanKind.exit,
          productId: ProductIds.exit,
          price: 29.99,
          priceString: r'$29.99',
          currencyCode: 'USD',
          introPrice: 14.99,
          introPriceString: r'$14.99',
          introEligible: trialEligible,
        ),
      ],
      OfferingId.winBack => const [
        StorePlan(
          kind: PlanKind.winBack,
          productId: ProductIds.yearly,
          price: 29.99,
          priceString: r'$29.99',
          currencyCode: 'USD',
          introPrice: 17.99,
          introPriceString: r'$17.99',
          introEligible: true,
        ),
      ],
    };
  }

  @override
  Future<PurchaseOutcome> purchase(StorePlan plan) async {
    final now = DateTime.now();
    final trial = plan.showsTrial;
    _current = Entitlement(
      isPro: true,
      productId: plan.productId,
      isTrial: trial,
      willRenew: plan.kind != PlanKind.lifetime,
      trialStartedAt: trial ? now : null,
      expiresAt: switch (plan.kind) {
        PlanKind.lifetime => null,
        PlanKind.weekly => now.add(const Duration(days: 7)),
        _ => now.add(Duration(days: trial ? plan.trialDays! : 365)),
      },
    );
    _changes.add(_current);
    return PurchaseOutcome.success;
  }

  @override
  Future<RestoreOutcome> restore() async =>
      _current.isPro ? RestoreOutcome.restored : RestoreOutcome.none;

  @override
  Future<void> setDebugPro(bool enabled) async {
    if (enabled) {
      final plans = await this.plans(OfferingId.main);
      final life = plans.firstWhere((p) => p.kind == PlanKind.lifetime);
      await purchase(life);
    } else {
      _current = Entitlement.free;
      _changes.add(_current);
    }
  }
}
