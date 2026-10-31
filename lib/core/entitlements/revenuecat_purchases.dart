import 'dart:async';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'purchases.dart';

/// RevenueCat with an anonymous app user ID (`07`). Entitlement "pro";
/// offerings "default", "exit", "winback".
class RevenueCatPurchases implements PurchasesService {
  RevenueCatPurchases(this.apiKey);

  final String apiKey;
  static const _entitlement = 'pro';
  final _changes = StreamController<Entitlement>.broadcast();
  Entitlement _current = Entitlement.free;
  final Map<String, Package> _packages = {};

  @override
  Entitlement get current => _current;

  @override
  Future<void> logIn(String accountId) async {
    try {
      final result = await Purchases.logIn(accountId);
      _update(result.customerInfo);
    } on PlatformException {
      // Rewards follow on the next launch.
    }
  }

  @override
  Future<String?> appUserId() async {
    try {
      return await Purchases.appUserID;
    } on PlatformException {
      return null;
    }
  }

  @override
  Stream<Entitlement> get changes => _changes.stream;

  @override
  Future<void> init() async {
    await Purchases.configure(PurchasesConfiguration(apiKey));
    Purchases.addCustomerInfoUpdateListener(_update);
    try {
      _update(await Purchases.getCustomerInfo());
    } on PlatformException {
      // Offline: keep the cached entitlement until the next update.
    }
  }

  void _update(CustomerInfo info) {
    final pro = info.entitlements.all[_entitlement];
    final active = pro?.isActive ?? false;
    _current = Entitlement(
      isPro: active,
      productId: pro?.productIdentifier,
      isTrial: active && pro?.periodType == PeriodType.trial,
      willRenew: pro?.willRenew ?? false,
      expiresAt: DateTime.tryParse(pro?.expirationDate ?? ''),
      trialStartedAt: active && pro?.periodType == PeriodType.trial
          ? DateTime.tryParse(pro?.latestPurchaseDate ?? '')
          : null,
      lapsedAt: !active && pro != null
          ? DateTime.tryParse(pro.expirationDate ?? '')
          : null,
      managementUrl: info.managementURL,
    );
    _changes.add(_current);
  }

  @override
  Future<List<StorePlan>> plans(OfferingId offering) async {
    final Offerings offerings;
    try {
      offerings = await Purchases.getOfferings();
    } on PlatformException {
      return const [];
    }
    final id = switch (offering) {
      OfferingId.main => 'default',
      OfferingId.exit => 'exit',
      OfferingId.winBack => 'winback',
    };
    final packages = offerings.all[id]?.availablePackages ?? const <Package>[];
    if (packages.isEmpty) return const [];

    final eligibility =
        await Purchases.checkTrialOrIntroductoryPriceEligibility([
          for (final p in packages) p.storeProduct.identifier,
        ]);
    final plans = <StorePlan>[];
    for (final package in packages) {
      final product = package.storeProduct;
      final kind = _kind(offering, package);
      if (kind == null) continue;
      _packages[_key(kind, product.identifier)] = package;
      final intro = product.introductoryPrice;
      final eligible =
          eligibility[product.identifier]?.status ==
          IntroEligibilityStatus.introEligibilityStatusEligible;
      final isFreeTrial = intro != null && intro.price == 0;
      String? winBackPrice;
      double? winBackValue;
      if (kind == PlanKind.winBack) {
        final offers = await Purchases.getEligibleWinBackOffersForPackage(
          package,
        );
        if (offers.isEmpty) continue;
        winBackPrice = offers.first.priceString;
        winBackValue = offers.first.price;
      }
      plans.add(
        StorePlan(
          kind: kind,
          productId: product.identifier,
          price: product.price,
          priceString: product.priceString,
          currencyCode: product.currencyCode,
          trialDays: isFreeTrial ? _days(intro) : null,
          introPrice: winBackValue ?? (isFreeTrial ? null : intro?.price),
          introPriceString:
              winBackPrice ?? (isFreeTrial ? null : intro?.priceString),
          introEligible: kind == PlanKind.winBack || eligible,
        ),
      );
    }
    return plans;
  }

  PlanKind? _kind(OfferingId offering, Package package) {
    if (offering == OfferingId.exit) return PlanKind.exit;
    if (offering == OfferingId.winBack) return PlanKind.winBack;
    return switch (package.packageType) {
      PackageType.annual => PlanKind.yearly,
      PackageType.weekly => PlanKind.weekly,
      PackageType.lifetime => PlanKind.lifetime,
      _ => null,
    };
  }

  int _days(IntroductoryPrice intro) => switch (intro.periodUnit) {
    PeriodUnit.day => intro.periodNumberOfUnits,
    PeriodUnit.week => intro.periodNumberOfUnits * 7,
    PeriodUnit.month => intro.periodNumberOfUnits * 30,
    PeriodUnit.year => intro.periodNumberOfUnits * 365,
    _ => intro.periodNumberOfUnits,
  };

  String _key(PlanKind kind, String productId) => '${kind.name}:$productId';

  @override
  Future<PurchaseOutcome> purchase(StorePlan plan) async {
    final package = _packages[_key(plan.kind, plan.productId)];
    if (package == null) return PurchaseOutcome.unavailable;
    try {
      WinBackOffer? winBack;
      if (plan.kind == PlanKind.winBack) {
        final offers = await Purchases.getEligibleWinBackOffersForPackage(
          package,
        );
        winBack = offers.isEmpty ? null : offers.first;
      }
      final result = await Purchases.purchase(
        PurchaseParams.package(package, winBackOffer: winBack),
      );
      _update(result.customerInfo);
      return _current.isPro ? PurchaseOutcome.success : PurchaseOutcome.failed;
    } on PlatformException catch (error) {
      return switch (PurchasesErrorHelper.getErrorCode(error)) {
        PurchasesErrorCode.purchaseCancelledError => PurchaseOutcome.cancelled,
        PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
        PurchasesErrorCode.networkError => PurchaseOutcome.offline,
        _ => PurchaseOutcome.failed,
      };
    }
  }

  @override
  Future<RestoreOutcome> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _update(info);
      return _current.isPro ? RestoreOutcome.restored : RestoreOutcome.none;
    } on PlatformException catch (error) {
      return PurchasesErrorHelper.getErrorCode(error) ==
              PurchasesErrorCode.networkError
          ? RestoreOutcome.offline
          : RestoreOutcome.failed;
    }
  }
}
