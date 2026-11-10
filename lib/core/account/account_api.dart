import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../rules/account_rules.dart';

/// What can go wrong talking to the Marberx auth/referral API (`12` §8).
enum AccountError {
  offline,
  server,
  validation,
  emailExists,
  invalidCredentials,
  rateLimited,
  unauthorized,
  wrongPassword,
  invalidCode,
  deviceUsed,
  selfReferral,
  capReached,
}

class AccountException implements Exception {
  const AccountException(this.error, {this.fields = const {}});

  final AccountError error;

  /// Server-side field errors (validation), keyed by field name.
  final Map<String, String> fields;

  @override
  String toString() => 'AccountException($error)';
}

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

class AccountUser {
  const AccountUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.verified,
    required this.referralCode,
    this.rewardDays = 0,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool verified;
  final String referralCode;

  /// Free Pro days earned from invites.
  final int rewardDays;

  String get initials {
    final f = firstName.isEmpty ? '' : firstName[0];
    final l = lastName.isEmpty ? '' : lastName[0];
    return (f + l).toUpperCase();
  }

  factory AccountUser.fromJson(Map<String, dynamic> j) => AccountUser(
    id: '${j['id']}',
    firstName: j['first_name'] as String? ?? '',
    lastName: j['last_name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    verified: j['verified'] as bool? ?? false,
    referralCode: j['referral_code'] as String? ?? '',
    rewardDays: (j['reward_days'] as num?)?.toInt() ?? 0,
  );
}

class AuthSession {
  const AuthSession({required this.tokens, required this.user});

  final AuthTokens tokens;
  final AccountUser user;
}

class ReferralStats {
  const ReferralStats({
    required this.joined,
    required this.earnedDays,
    required this.pending,
    this.capReached = false,
  });

  /// Qualified + rewarded friends.
  final int joined;
  final int earnedDays;

  /// Redeemed but not yet qualified, or waiting for email verification.
  final int pending;
  final bool capReached;

  static const empty = ReferralStats(joined: 0, earnedDays: 0, pending: 0);
}

class RedeemResult {
  const RedeemResult({
    required this.inviterFirstName,
    required this.proUntil,
    this.alreadyPro = false,
  });

  final String inviterFirstName;
  final DateTime proUntil;
  final bool alreadyPro;
}

/// The endpoints in `12` §2. Every call carries `app_id`.
abstract class AccountApi {
  Future<AuthSession> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String deviceId,
  });

  Future<AuthSession> logIn({required String email, required String password});
  Future<AuthTokens> refresh(String refreshToken);

  /// Always succeeds for any email (no account enumeration).
  Future<void> forgot(String email);
  Future<void> resendVerification(String access);
  Future<AccountUser> me(String access);
  Future<void> changePassword(
    String access, {
    required String current,
    required String next,
  });
  Future<String> randomCode(String access);
  Future<void> deleteAccount(String access, {required String password});

  /// The friend, without an account.
  Future<RedeemResult> redeem({
    required String code,
    required String appUserId,
    required String? deviceCheckToken,
  });

  /// After the friend's first successful conversion.
  Future<void> qualify({required String appUserId});
  Future<ReferralStats> stats(String access);
}

/// JSON over HTTPS with `dart:io`.
// TODO(question #25): confirm paths and payloads against the Marberx API.
class HttpAccountApi implements AccountApi {
  HttpAccountApi({required this.baseUrl, required this.appId});

  final String baseUrl;
  final String appId;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 15);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? access,
    AccountError on401 = AccountError.unauthorized,
  }) async {
    try {
      final request = await _client.openUrl(method, Uri.parse('$baseUrl$path'));
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (access != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $access');
      }
      request.write(jsonEncode({'app_id': appId, ...?body}));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final text = await response.transform(utf8.decoder).join();
      final json = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      final status = response.statusCode;
      if (status >= 200 && status < 300) return json;
      final code = json['error'] as String?;
      throw switch (status) {
        401 => AccountException(on401),
        403 when code == 'wrong_password' => const AccountException(
          AccountError.wrongPassword,
        ),
        409 => const AccountException(AccountError.emailExists),
        422 => AccountException(
          AccountError.validation,
          fields: {
            for (final e
                in (json['fields'] as Map<String, dynamic>? ?? {}).entries)
              e.key: '${e.value}',
          },
        ),
        429 => const AccountException(AccountError.rateLimited),
        400 => AccountException(switch (code) {
          'device_used' => AccountError.deviceUsed,
          'self_referral' => AccountError.selfReferral,
          'cap_reached' => AccountError.capReached,
          _ => AccountError.invalidCode,
        }),
        _ => const AccountException(AccountError.server),
      };
    } on AccountException {
      rethrow;
    } on SocketException {
      throw const AccountException(AccountError.offline);
    } on TimeoutException {
      throw const AccountException(AccountError.offline);
    } on HandshakeException {
      throw const AccountException(AccountError.offline);
    } on FormatException {
      throw const AccountException(AccountError.server);
    }
  }

  AuthSession _session(Map<String, dynamic> j) => AuthSession(
    tokens: AuthTokens(
      access: j['access_token'] as String,
      refresh: j['refresh_token'] as String,
    ),
    user: AccountUser.fromJson(j['user'] as Map<String, dynamic>),
  );

  @override
  Future<AuthSession> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String deviceId,
  }) async => _session(
    await _send(
      'POST',
      '/auth/signup',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'device_id': deviceId,
      },
    ),
  );

  @override
  Future<AuthSession> logIn({
    required String email,
    required String password,
  }) async => _session(
    await _send(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      on401: AccountError.invalidCredentials,
    ),
  );

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final j = await _send(
      'POST',
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return AuthTokens(
      access: j['access_token'] as String,
      refresh: j['refresh_token'] as String? ?? refreshToken,
    );
  }

  @override
  Future<void> forgot(String email) async =>
      _send('POST', '/auth/forgot', body: {'email': email});

  @override
  Future<void> resendVerification(String access) async =>
      _send('POST', '/auth/verify/resend', access: access);

  @override
  Future<AccountUser> me(String access) async =>
      AccountUser.fromJson(await _send('GET', '/me', access: access));

  @override
  Future<void> changePassword(
    String access, {
    required String current,
    required String next,
  }) async => _send(
    'POST',
    '/me/password',
    access: access,
    body: {'current_password': current, 'new_password': next},
  );

  @override
  Future<String> randomCode(String access) async =>
      (await _send('POST', '/referral/code/random', access: access))['code']
          as String;

  @override
  Future<void> deleteAccount(String access, {required String password}) async =>
      _send('DELETE', '/me', access: access, body: {'password': password});

  @override
  Future<RedeemResult> redeem({
    required String code,
    required String appUserId,
    required String? deviceCheckToken,
  }) async {
    final j = await _send(
      'POST',
      '/referral/redeem',
      body: {
        'code': code,
        'app_user_id': appUserId,
        'devicecheck_token': deviceCheckToken,
      },
    );
    return RedeemResult(
      inviterFirstName: j['inviter_first_name'] as String? ?? '',
      proUntil: DateTime.parse(j['pro_until'] as String),
      alreadyPro: j['already_pro'] as bool? ?? false,
    );
  }

  @override
  Future<void> qualify({required String appUserId}) async =>
      _send('POST', '/referral/qualify', body: {'app_user_id': appUserId});

  @override
  Future<ReferralStats> stats(String access) async {
    final j = await _send('GET', '/referral/stats', access: access);
    return ReferralStats(
      joined: (j['friends_joined'] as num?)?.toInt() ?? 0,
      earnedDays: (j['days_earned'] as num?)?.toInt() ?? 0,
      pending: (j['pending'] as num?)?.toInt() ?? 0,
      capReached: j['cap_reached'] as bool? ?? false,
    );
  }
}

/// In-memory stand-in for debug builds without an API URL and for tests.
/// Behaves like `12`: generic sign-in errors, lockout after 5 failures,
/// one redemption per device, no self-referral.
class DemoAccountApi implements AccountApi {
  DemoAccountApi({this.friendDays = 7, math.Random? random})
    : _random = random ?? math.Random() {
    // Known code for local testing when no friend has signed up yet.
    _users['demo@tunely.app'] = _DemoUser(
      id: 'demo',
      firstName: 'Alex',
      lastName: 'Friend',
      email: 'demo@tunely.app',
      password: 'DemoPass1!',
      code: 'DEMOCODE',
    )..verified = true;
  }

  final int friendDays;
  final math.Random _random;
  final Map<String, _DemoUser> _users = {};
  final Map<String, String> _tokens = {};
  final Set<String> _usedDevices = {};
  final Map<String, String> _redeemedBy = {};
  int _failures = 0;
  bool offline = false;

  Future<void> _net() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (offline) throw const AccountException(AccountError.offline);
  }

  _DemoUser _auth(String access) {
    final email = _tokens[access];
    final user = email == null ? null : _users[email];
    if (user == null) throw const AccountException(AccountError.unauthorized);
    return user;
  }

  final Map<String, String> _refreshTokens = {};

  AuthTokens _tokensFor(String email) {
    final access = 'a${_random.nextInt(1 << 30)}';
    final refresh = 'r${_random.nextInt(1 << 30)}';
    _tokens[access] = email;
    _refreshTokens[refresh] = email;
    return AuthTokens(access: access, refresh: refresh);
  }

  AuthSession _issue(_DemoUser user) =>
      AuthSession(tokens: _tokensFor(user.email), user: user.toUser());

  /// Test hook: expire every access token (refresh still works).
  void expireTokens() => _tokens.clear();

  /// Test hook: refresh tokens stop working too.
  void revokeRefresh() => _refreshTokens.clear();

  /// Test hook: mark an email verified.
  void verify(String email) => _users[email.toLowerCase()]?.verified = true;

  @override
  Future<AuthSession> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String deviceId,
  }) async {
    await _net();
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) {
      throw const AccountException(AccountError.emailExists);
    }
    var code = ReferralCode.suggest(firstName, random: _random);
    while (_users.values.any((u) => u.code == code)) {
      code = ReferralCode.suggest(firstName, random: _random);
    }
    final user = _DemoUser(
      id: 'u${_users.length + 1}',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: key,
      password: password,
      code: code,
    );
    _users[key] = user;
    return _issue(user);
  }

  @override
  Future<AuthSession> logIn({
    required String email,
    required String password,
  }) async {
    await _net();
    if (_failures >= 5) throw const AccountException(AccountError.rateLimited);
    final user = _users[email.trim().toLowerCase()];
    if (user == null || user.password != password) {
      _failures++;
      throw const AccountException(AccountError.invalidCredentials);
    }
    _failures = 0;
    return _issue(user);
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    await _net();
    final email = _refreshTokens.remove(refreshToken);
    if (email == null) throw const AccountException(AccountError.unauthorized);
    return _tokensFor(email);
  }

  @override
  Future<void> forgot(String email) => _net();

  @override
  Future<void> resendVerification(String access) async {
    await _net();
    _auth(access);
  }

  @override
  Future<AccountUser> me(String access) async {
    await _net();
    return _auth(access).toUser();
  }

  @override
  Future<void> changePassword(
    String access, {
    required String current,
    required String next,
  }) async {
    await _net();
    final user = _auth(access);
    if (user.password != current) {
      throw const AccountException(AccountError.wrongPassword);
    }
    user.password = next;
  }

  @override
  Future<String> randomCode(String access) async {
    await _net();
    final user = _auth(access);
    user.code = ReferralCode.suggest('', random: _random);
    return user.code;
  }

  @override
  Future<void> deleteAccount(String access, {required String password}) async {
    await _net();
    final user = _auth(access);
    if (user.password != password) {
      throw const AccountException(AccountError.wrongPassword);
    }
    _users.remove(user.email);
    _tokens.removeWhere((_, email) => email == user.email);
    _refreshTokens.removeWhere((_, email) => email == user.email);
  }

  @override
  Future<RedeemResult> redeem({
    required String code,
    required String appUserId,
    required String? deviceCheckToken,
  }) async {
    await _net();
    final inviter = _users.values
        .where((u) => u.code == ReferralCode.normalize(code))
        .firstOrNull;
    if (inviter == null) throw const AccountException(AccountError.invalidCode);
    final device = deviceCheckToken ?? appUserId;
    if (_usedDevices.contains(device) || _redeemedBy.containsKey(appUserId)) {
      throw const AccountException(AccountError.deviceUsed);
    }
    _usedDevices.add(device);
    _redeemedBy[appUserId] = inviter.email;
    inviter.pending++;
    return RedeemResult(
      inviterFirstName: inviter.firstName,
      proUntil: DateTime.now().add(Duration(days: friendDays)),
    );
  }

  @override
  Future<void> qualify({required String appUserId}) async {
    await _net();
    final inviter = _users[_redeemedBy.remove(appUserId)];
    if (inviter == null) return;
    inviter.pending = math.max(0, inviter.pending - 1);
    inviter.joined++;
    if (inviter.verified) inviter.rewardDays += friendDays;
  }

  @override
  Future<ReferralStats> stats(String access) async {
    await _net();
    final u = _auth(access);
    return ReferralStats(
      joined: u.joined,
      earnedDays: u.rewardDays,
      pending: u.pending,
    );
  }
}

class _DemoUser {
  _DemoUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.code,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  String password;
  String code;
  bool verified = false;
  int rewardDays = 0;
  int joined = 0;
  int pending = 0;

  AccountUser toUser() => AccountUser(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    verified: verified,
    referralCode: code,
    rewardDays: rewardDays,
  );
}
