import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:intl/intl.dart';

import 'purchases.dart';

/// StoreKit paywall (`in_app_purchase`). Prices and trial eligibility come
/// from App Store Connect / the local `Tunely.storekit` file.
class StoreKitPurchases implements PurchasesService {
  StoreKitPurchases({InAppPurchase? store})
    : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final _changes = StreamController<Entitlement>.broadcast();
  final Map<String, ProductDetails> _products = {};
  final Map<String, SKProductWrapper> _sk1 = {};
  Entitlement _current = Entitlement.free;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PurchaseOutcome>? _pending;
  String? _winBackOfferId;
  final _demo = DemoPurchasesService();
  var _usingDemo = false;

  @override
  Entitlement get current => _usingDemo ? _demo.current : _current;

  @override
  Stream<Entitlement> get changes => _changes.stream;

  @override
  Future<String?> appUserId() async => null;

  @override
  Future<void> logIn(String accountId) async {}

  @override
  Future<void> init() async {
    _sub ??= _store.purchaseStream.listen(_onPurchases, onError: (_) {});
    _demo.changes.listen((next) {
      if (_usingDemo) _changes.add(next);
    });
    await _refreshEntitlement();
  }

  @override
  Future<List<StorePlan>> plans(OfferingId offering) async {
    if (_usingDemo) return _demo.plans(offering);
    try {
      if (await _store.isAvailable()) {
        await _loadProducts();
        final loaded = await _fromStore(offering);
        final usable =
            offering != OfferingId.main ||
            loaded.any((plan) => plan.kind == PlanKind.yearly);
        if (loaded.isNotEmpty && usable) return loaded;
        // Partial / empty store response (common with `flutter run`, which
        // does not attach the Xcode StoreKit config): use demo in debug.
        if (kDebugMode) {
          _usingDemo = true;
          return await _demo.plans(offering);
        }
        return loaded;
      }
    } on Object {
      // Simulator without StoreKit config: show local plans in debug.
    }
    if (kDebugMode) {
      _usingDemo = true;
      return _demo.plans(offering);
    }
    return const [];
  }

  Future<List<StorePlan>> _fromStore(OfferingId offering) async {
    return switch (offering) {
      OfferingId.main => [
        ?await _plan(PlanKind.yearly),
        ?await _plan(PlanKind.weekly),
        ?await _plan(PlanKind.lifetime),
      ],
      OfferingId.exit => [?await _plan(PlanKind.exit)],
      OfferingId.winBack => [?await _winBack()],
    };
  }

  @override
  Future<PurchaseOutcome> purchase(StorePlan plan) async {
    if (_usingDemo) return _demo.purchase(plan);
    final product = _products[plan.productId];
    if (product == null) return PurchaseOutcome.unavailable;
    if (!await _store.isAvailable()) return PurchaseOutcome.offline;
    if (_pending != null) return PurchaseOutcome.failed;

    final pending = Completer<PurchaseOutcome>();
    _pending = pending;
    try {
      final param = plan.kind == PlanKind.winBack && _winBackOfferId != null
          ? Sk2PurchaseParam(
              productDetails: product,
              winBackOfferId: _winBackOfferId,
            )
          : PurchaseParam(productDetails: product);
      final ok = await _store.buyNonConsumable(purchaseParam: param);
      if (!ok) {
        _pending = null;
        return PurchaseOutcome.unavailable;
      }
      return await pending.future;
    } on PlatformException catch (error) {
      _pending = null;
      return _fromException(error);
    } on Object {
      _pending = null;
      return PurchaseOutcome.failed;
    }
  }

  @override
  Future<RestoreOutcome> restore() async {
    if (_usingDemo) return _demo.restore();
    try {
      // Do not gate on isAvailable() — it can be false while online and
      // wrongly show the offline dialog. Always ask StoreKit, then report
      // restored / none from current entitlements.
      try {
        await SK2Transaction.restorePurchases();
      } on Object {
        // Fall through to the plugin restore.
      }
      try {
        await _store.restorePurchases();
      } on Object {
        // Entitlements below still decide the result.
      }
      await _refreshEntitlement();
      return _current.isPro ? RestoreOutcome.restored : RestoreOutcome.none;
    } on PlatformException catch (error) {
      await _refreshEntitlement();
      if (_current.isPro) return RestoreOutcome.restored;
      return _offline(error) ? RestoreOutcome.offline : RestoreOutcome.failed;
    } on Object {
      await _refreshEntitlement();
      if (_current.isPro) return RestoreOutcome.restored;
      return RestoreOutcome.failed;
    }
  }

  @override
  Future<void> setDebugPro(bool enabled) async {
    if (!kDebugMode) return;
    _usingDemo = true;
    await _demo.setDebugPro(enabled);
    if (!enabled) {
      _usingDemo = false;
      _changes.add(_current);
    }
  }

  Future<void> _loadProducts() async {
    _products.clear();
    try {
      final sk2 = await SK2Product.products(ProductIds.all.toList());
      for (final product in sk2) {
        _products[product.id] = AppStoreProduct2Details.fromSK2Product(product);
      }
    } on Object {
      // Fall through to the plugin query.
    }
    if (_products.isEmpty) {
      final response = await _store.queryProductDetails(ProductIds.all);
      _products.addEntries(
        response.productDetails.map((product) => MapEntry(product.id, product)),
      );
    }
    try {
      final sk1 = await SKRequestMaker().startProductRequest(
        ProductIds.all.toList(),
      );
      _sk1
        ..clear()
        ..addEntries(
          sk1.products.map(
            (product) => MapEntry(product.productIdentifier, product),
          ),
        );
    } on Object {
      // SK2 products still work; intro metadata may be missing.
    }
  }

  Future<StorePlan?> _plan(PlanKind kind) async {
    final ids = ProductIds.aliases(kind);
    final id = ids.firstWhere(
      (candidate) => _products.containsKey(candidate),
      orElse: () => ProductIds.canonical(kind),
    );
    final product = _products[id];
    if (product == null) return null;
    SKProductDiscountWrapper? intro = _sk1[id]?.introductoryPrice;
    if (intro == null) {
      for (final alias in ids) {
        intro = _sk1[alias]?.introductoryPrice;
        if (intro != null) break;
      }
    }
    final eligible = intro != null && await _introEligible(id);
    // Free trial belongs on Yearly only; Weekly never gets trial copy.
    final trial =
        kind == PlanKind.yearly &&
        intro != null &&
        intro.paymentMode == SKProductDiscountPaymentMode.freeTrail;
    final paidIntro =
        (kind == PlanKind.exit || kind == PlanKind.winBack) &&
        intro != null &&
        intro.paymentMode != SKProductDiscountPaymentMode.freeTrail;
    return StorePlan(
      kind: kind,
      productId: id,
      price: product.rawPrice,
      priceString: product.price,
      currencyCode: product.currencyCode,
      trialDays: trial && eligible ? _trialDays(intro) : null,
      introPrice: paidIntro && eligible ? _amount(intro.price) : null,
      introPriceString: paidIntro && eligible
          ? _format(product, _amount(intro.price))
          : null,
      introEligible: (trial || paidIntro) && eligible,
    );
  }

  Future<StorePlan?> _winBack() async {
    final product =
        _products[ProductIds.yearly] ?? _products[ProductIds.yearlyShort];
    if (product is! AppStoreProduct2Details) return null;
    final offers =
        product.sk2Product.subscription?.promotionalOffers ?? const [];
    for (final offer in offers) {
      final offerId = offer.id;
      if (offer.type != SK2SubscriptionOfferType.winBack || offerId == null) {
        continue;
      }
      try {
        if (!await SK2Product.isWinBackOfferEligible(
          ProductIds.yearly,
          offerId,
        )) {
          continue;
        }
      } on Object {
        continue;
      }
      _winBackOfferId = offerId;
      return StorePlan(
        kind: PlanKind.winBack,
        productId: ProductIds.yearly,
        price: product.rawPrice,
        priceString: product.price,
        currencyCode: product.currencyCode,
        introPrice: offer.price,
        introPriceString: _format(product, offer.price),
        introEligible: true,
      );
    }
    return null;
  }

  Future<bool> _introEligible(String id) async {
    try {
      return await SK2Product.isIntroductoryOfferEligible(id);
    } on Object {
      // StoreKit configuration in the simulator still has the intro.
      return true;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } on Object {
          // Finish on the next launch.
        }
      }
      final outcome = switch (purchase.status) {
        PurchaseStatus.purchased ||
        PurchaseStatus.restored => PurchaseOutcome.success,
        PurchaseStatus.canceled => PurchaseOutcome.cancelled,
        PurchaseStatus.pending => PurchaseOutcome.pending,
        PurchaseStatus.error => _fromError(purchase.error),
      };
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _refreshEntitlement();
      }
      final pending = _pending;
      if (pending != null &&
          purchase.status != PurchaseStatus.restored &&
          !pending.isCompleted) {
        _pending = null;
        pending.complete(outcome);
      }
    }
  }

  Future<void> _refreshEntitlement() async {
    try {
      final active = await SK2Transaction.currentEntitlements();
      DateTime? lapsed;
      if (active.isEmpty) {
        lapsed = _latestExpiry(await SK2Transaction.transactions());
      }
      _current = _fromTransactions(active, lapsedAt: lapsed);
    } on Object {
      // Keep the last known entitlement while offline.
    }
    _changes.add(_current);
  }

  Entitlement _fromTransactions(
    List<SK2Transaction> active, {
    DateTime? lapsedAt,
  }) {
    SK2Transaction? lifetime;
    SK2Transaction? sub;
    for (final tx in active) {
      if (tx.productId == ProductIds.lifetime) {
        lifetime = tx;
      } else if (ProductIds.all.contains(tx.productId)) {
        sub = tx;
      }
    }
    if (lifetime != null) {
      return Entitlement(isPro: true, productId: lifetime.productId);
    }
    if (sub != null) {
      final start = _date(sub.purchaseDate);
      final end = _date(sub.expirationDate);
      final trial =
          start != null &&
          end != null &&
          end.difference(start) <= const Duration(days: 4);
      return Entitlement(
        isPro: true,
        productId: sub.productId,
        isTrial: trial,
        willRenew: true,
        expiresAt: end,
        trialStartedAt: trial ? start : null,
      );
    }
    return Entitlement(isPro: false, lapsedAt: lapsedAt);
  }

  DateTime? _latestExpiry(List<SK2Transaction> all) {
    DateTime? latest;
    for (final tx in all) {
      final end = _date(tx.expirationDate);
      if (end == null || end.isAfter(DateTime.now())) continue;
      if (latest == null || end.isAfter(latest)) latest = end;
    }
    return latest;
  }

  static int _trialDays(SKProductDiscountWrapper intro) {
    final units =
        intro.subscriptionPeriod.numberOfUnits * intro.numberOfPeriods;
    return switch (intro.subscriptionPeriod.unit) {
      SKSubscriptionPeriodUnit.day => units,
      SKSubscriptionPeriodUnit.week => units * 7,
      SKSubscriptionPeriodUnit.month => units * 30,
      SKSubscriptionPeriodUnit.year => units * 365,
    };
  }

  static double _amount(String raw) =>
      double.tryParse(raw.replaceAll(',', '.')) ?? 0;

  static String _format(ProductDetails product, double amount) {
    return NumberFormat.simpleCurrency(name: product.currencyCode)
        .format(amount);
  }

  static DateTime? _date(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final ms = int.tryParse(raw);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.tryParse(raw);
  }

  static PurchaseOutcome _fromError(IAPError? error) {
    final code = '${error?.code ?? ''} ${error?.message ?? ''}'.toLowerCase();
    if (code.contains('cancel')) return PurchaseOutcome.cancelled;
    if (code.contains('network') || code.contains('offline')) {
      return PurchaseOutcome.offline;
    }
    return PurchaseOutcome.failed;
  }

  static PurchaseOutcome _fromException(PlatformException error) {
    final code = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (code.contains('cancel')) return PurchaseOutcome.cancelled;
    if (_offline(error)) return PurchaseOutcome.offline;
    return PurchaseOutcome.failed;
  }

  static bool _offline(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    // Only clear connectivity failures — not generic StoreKit errors.
    return code == 'storekit_network_error' ||
        code == 'billing_unavailable' ||
        message.contains('network connection was lost') ||
        message.contains('the internet connection appears to be offline') ||
        message.contains('not connected to the internet');
  }
}
