import 'dart:async';

/// Plans from `07`. Product IDs live in App Store Connect / RevenueCat.
enum PlanKind { yearly, weekly, lifetime, exit, winBack }

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

  bool get showsTrial => trialDays != null && introEligible;
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

/// The app's only door to purchases. RevenueCat in production.
abstract class PurchasesService {
  Entitlement get current;
  Stream<Entitlement> get changes;

  Future<void> init();
  Future<List<StorePlan>> plans(OfferingId offering);
  Future<PurchaseOutcome> purchase(StorePlan plan);
  Future<RestoreOutcome> restore();

  /// RevenueCat's (anonymous) `appUserID`; Mixpanel `distinct_id` (`08`).
  Future<String?> appUserId();

  /// Links invite rewards to the account (RevenueCat `logIn`). Never called
  /// on sign-out: Pro stays tied to the Apple ID (`12` §1.5).
  Future<void> logIn(String accountId);
}

/// Release build without a RevenueCat key: nothing to sell, never fake prices.
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
}

/// Debug-only stand-in when no RevenueCat key is set, so paywalls can be
/// reviewed in the simulator. Release builds never use it.
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
          productId: 'tunely.pro.yearly',
          price: 29.99,
          priceString: r'$29.99',
          currencyCode: 'USD',
          trialDays: 3,
          introEligible: trialEligible,
        ),
        const StorePlan(
          kind: PlanKind.weekly,
          productId: 'tunely.pro.weekly',
          price: 4.99,
          priceString: r'$4.99',
          currencyCode: 'USD',
        ),
        const StorePlan(
          kind: PlanKind.lifetime,
          productId: 'tunely.pro.lifetime',
          price: 39.99,
          priceString: r'$39.99',
          currencyCode: 'USD',
        ),
      ],
      OfferingId.exit => [
        StorePlan(
          kind: PlanKind.exit,
          productId: 'tunely.pro.yearly.exit',
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
          productId: 'tunely.pro.yearly',
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
}
