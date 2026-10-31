import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_api.dart';

/// Access + refresh tokens. Only ever in the Keychain (`12` §7).
abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  static const _access = 'tunely.account.access';
  static const _refresh = 'tunely.account.refresh';
  static const _options = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final _storage = const FlutterSecureStorage();

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _access, iOptions: _options);
    final refresh = await _storage.read(key: _refresh, iOptions: _options);
    if (access == null || refresh == null) return null;
    return AuthTokens(access: access, refresh: refresh);
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(
      key: _access,
      value: tokens.access,
      iOptions: _options,
    );
    await _storage.write(
      key: _refresh,
      value: tokens.refresh,
      iOptions: _options,
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access, iOptions: _options);
    await _storage.delete(key: _refresh, iOptions: _options);
  }
}

class MemoryTokenStore implements TokenStore {
  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async => tokens = null;
}
