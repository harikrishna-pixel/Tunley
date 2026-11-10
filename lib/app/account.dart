import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/account/account_api.dart';
import '../core/account/token_store.dart';
import '../core/analytics/analytics.dart';
import '../core/analytics/events.dart';
import '../core/engine/audio_engine.dart';
import '../core/library/app_database.dart';
import '../core/rules/account_rules.dart';
import 'config.dart';
import 'monetization.dart';
import 'state.dart';

/// Local demo backend kept for the app lifetime so sign-up → sign-in works.
final _demoAccountApiProvider = Provider<DemoAccountApi>((ref) {
  final days = ref.watch(appConfigProvider).referral.friendDays;
  return DemoAccountApi(friendDays: days);
});

final accountApiProvider = Provider<AccountApi>((ref) {
  final config = ref.watch(appConfigProvider).referral;
  final base = config.apiBaseUrl;
  if (base != null) return HttpAccountApi(baseUrl: base, appId: config.appId);
  // TODO(question #25): real Marberx API URL. Until then, local demo so
  // create / sign-in / redeem work without a generic server error.
  return ref.watch(_demoAccountApiProvider);
});

/// Overridden in `main` with [SecureTokenStore].
final tokenStoreProvider = Provider<TokenStore>((_) => MemoryTokenStore());

class AccountState {
  const AccountState({this.user, this.stats, this.restoring = false});

  final AccountUser? user;
  final ReferralStats? stats;
  final bool restoring;

  bool get signedIn => user != null;
}

/// Optional account, only for inviters (`12` §1). Never needed to convert,
/// buy or restore.
class AccountController extends Notifier<AccountState> {
  static const _seenKey = 'account_seen';

  @override
  AccountState build() {
    unawaited(Future.microtask(_restore));
    return const AccountState(restoring: true);
  }

  AccountApi get _api => ref.read(accountApiProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);
  Analytics get _analytics => ref.read(analyticsProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  void _set(AccountState next) {
    if (ref.mounted) state = next;
  }

  static const _userKey = 'account_user';

  Future<void> _restore() async {
    if (await _tokens.read() == null) {
      _set(const AccountState());
      return;
    }
    final cached = await _db.readValue(_userKey);
    if (cached != null && cached.isNotEmpty) {
      _set(
        AccountState(
          user: AccountUser.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
          ),
        ),
      );
    }
    try {
      await refresh();
    } on AccountException {
      // Offline or server down: keep the cached account; screens retry.
      if (!state.signedIn) _set(const AccountState());
    }
  }

  Future<void> _cache(AccountUser user) => _db.writeValue(
    _userKey,
    jsonEncode({
      'id': user.id,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'email': user.email,
      'verified': user.verified,
      'referral_code': user.referralCode,
      'reward_days': user.rewardDays,
    }),
  );

  /// `email_verified` / `referral_rewarded` arrive from the server; the app
  /// notices them on the next `/me`.
  Future<void> _noticeChanges(AccountUser user) async {
    final raw = await _db.readValue(_seenKey);
    final seen = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    if (seen != null && seen['id'] == user.id) {
      if (seen['verified'] == false && user.verified) {
        _analytics.emailVerified();
      }
      if (user.rewardDays > (seen['rewardDays'] as int? ?? 0)) {
        _analytics.referralRewarded();
      }
    }
    await _db.writeValue(
      _seenKey,
      jsonEncode({
        'id': user.id,
        'verified': user.verified,
        'rewardDays': user.rewardDays,
      }),
    );
  }

  /// Runs [call] with a fresh access token; refreshes once on 401 and signs
  /// out silently if that fails.
  Future<T> _authorized<T>(Future<T> Function(String access) call) async {
    final tokens = await _tokens.read();
    if (tokens == null) throw const AccountException(AccountError.unauthorized);
    try {
      return await call(tokens.access);
    } on AccountException catch (e) {
      if (e.error != AccountError.unauthorized) rethrow;
    }
    final fresh = await (_refreshing ??= _refresh(tokens)
        .whenComplete(() => _refreshing = null));
    return call(fresh.access);
  }

  /// One refresh at a time: refresh tokens are single-use.
  Future<AuthTokens>? _refreshing;

  Future<AuthTokens> _refresh(AuthTokens tokens) async {
    final current = await _tokens.read();
    if (current != null && current.access != tokens.access) return current;
    try {
      final fresh = await _api.refresh(tokens.refresh);
      await _tokens.write(fresh);
      return fresh;
    } on AccountException catch (e) {
      if (e.error == AccountError.unauthorized) await signOut();
      rethrow;
    }
  }

  Future<void> _start(AuthSession session) async {
    await _tokens.write(session.tokens);
    await _noticeChanges(session.user);
    await _cache(session.user);
    _set(AccountState(user: session.user));
    await ref.read(purchasesServiceProvider).logIn(session.user.id);
    unawaited(refreshStats().catchError((Object _) {}));
  }

  Future<String> _deviceId() async {
    final id = await ref.read(purchasesServiceProvider).appUserId();
    if (id != null) return id;
    final stored = await _db.readValue('device_id');
    if (stored != null) return stored;
    final random = math.Random.secure();
    final made = List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    await _db.writeValue('device_id', made);
    return made;
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _analytics.signupStarted();
    try {
      final session = await _api.signUp(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
        deviceId: await _deviceId(),
      );
      await _start(session);
      _analytics.signupCompleted();
    } on AccountException catch (e) {
      _analytics.signupFailed(error: _errorName(e.error));
      rethrow;
    }
  }

  Future<void> logIn({required String email, required String password}) async {
    try {
      await _start(await _api.logIn(email: email.trim(), password: password));
      _analytics.loginCompleted();
    } on AccountException catch (e) {
      _analytics.loginFailed(error: _errorName(e.error));
      rethrow;
    }
  }

  /// Tokens go; the app and Pro keep working.
  Future<void> signOut() async {
    await _tokens.clear();
    await _db.writeValue(_userKey, '');
    _set(const AccountState());
  }

  Future<void> forgot(String email) async {
    await _api.forgot(email.trim());
    _analytics.passwordResetRequested();
  }

  Future<void> resendVerification() => _authorized(_api.resendVerification);

  Future<void> refresh() async {
    final user = await _authorized(_api.me);
    await _noticeChanges(user);
    await _cache(user);
    if (ref.mounted) _set(AccountState(user: user, stats: state.stats));
  }

  Future<void> refreshStats() async {
    final stats = await _authorized(_api.stats);
    if (ref.mounted) _set(AccountState(user: state.user, stats: stats));
  }

  Future<void> useRandomCode() async {
    await _authorized(_api.randomCode);
    await refresh();
  }

  Future<void> changePassword({
    required String current,
    required String next,
  }) =>
      _authorized((a) => _api.changePassword(a, current: current, next: next));

  /// In-app deletion (Apple 5.1.1(v)). Files and the App Store subscription
  /// are not affected.
  Future<void> deleteAccount(String password) async {
    await _authorized((a) => _api.deleteAccount(a, password: password));
    _analytics.accountDeleted();
    await _db.writeValue(_seenKey, '{}');
    await signOut();
  }

  String _errorName(AccountError e) => switch (e) {
    AccountError.emailExists => 'email_exists',
    AccountError.validation => 'validation',
    AccountError.offline => 'network',
    AccountError.invalidCredentials => 'invalid_credentials',
    AccountError.rateLimited => 'rate_limited',
    _ => 'server',
  };
}

final accountProvider = NotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

enum RedeemSource { deepLink, manual }

/// The friend side (no account): redeem once, qualify after the first file.
class ReferralController extends Notifier<void> {
  static const _redeemedKey = 'referral_redeemed';
  static const _qualifiedKey = 'referral_qualified';

  @override
  void build() {}

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<bool> get redeemed async => await _db.readValue(_redeemedKey) == '1';

  Future<RedeemResult> redeem(
    String code, {
    required RedeemSource source,
  }) async {
    final analytics = ref.read(analyticsProvider);
    final sourceName = source == RedeemSource.deepLink ? 'deep_link' : 'manual';
    try {
      final appUserId =
          await ref.read(purchasesServiceProvider).appUserId() ?? '';
      final result = await ref
          .read(accountApiProvider)
          .redeem(
            code: ReferralCode.normalize(code),
            appUserId: appUserId,
            deviceCheckToken: await ref
                .read(audioEngineProvider)
                .deviceCheckToken(),
          );
      await _db.writeValue(_redeemedKey, '1');
      analytics.inviteCodeRedeemed(source: sourceName, result: 'success');
      return result;
    } on AccountException catch (e) {
      final result = switch (e.error) {
        AccountError.deviceUsed => 'device_used',
        AccountError.capReached => 'cap',
        AccountError.invalidCode || AccountError.selfReferral => 'invalid',
        _ => null,
      };
      if (result != null) {
        analytics.inviteCodeRedeemed(source: sourceName, result: result);
      }
      rethrow;
    }
  }

  /// After the friend's first successful conversion or ringtone.
  Future<void> qualifyIfNeeded() async {
    if (!await redeemed) return;
    if (await _db.readValue(_qualifiedKey) == '1') return;
    final appUserId = await ref.read(purchasesServiceProvider).appUserId();
    if (appUserId == null) return;
    try {
      await ref.read(accountApiProvider).qualify(appUserId: appUserId);
      await _db.writeValue(_qualifiedKey, '1');
      ref.read(analyticsProvider).referralQualified();
    } on AccountException {
      // Retried after the next successful file.
    }
  }
}

final referralProvider = NotifierProvider<ReferralController, void>(
  ReferralController.new,
);

/// A code from a universal link, waiting for screen 53.
class PendingInviteCode extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

final pendingInviteCodeProvider = NotifierProvider<PendingInviteCode, String?>(
  PendingInviteCode.new,
);
