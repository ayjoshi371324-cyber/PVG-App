import 'dart:convert';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStorageService {
  Future<void> saveTokens(AuthTokenPair tokens);
  Future<void> saveUser(AuthUser user);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<AuthTokenPair?> getTokens();
  Future<AuthUser?> getUser();
  Future<void> clear();
}

class SharedPreferencesTokenStorageService implements TokenStorageService {
  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyExpiresAt = 'auth_expires_at';
  static const _keyUser = 'auth_user_json';

  @override
  Future<void> saveTokens(AuthTokenPair tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, tokens.accessToken);
    await prefs.setString(_keyRefreshToken, tokens.refreshToken);
    await prefs.setString(_keyExpiresAt, tokens.expiresAt.toIso8601String());
  }

  @override
  Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  @override
  Future<AuthTokenPair?> getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_keyAccessToken);
    final refresh = prefs.getString(_keyRefreshToken);
    final expiresStr = prefs.getString(_keyExpiresAt);

    if (access == null || refresh == null || expiresStr == null) return null;

    try {
      return AuthTokenPair(
        accessToken: access,
        refreshToken: refresh,
        expiresAt: DateTime.parse(expiresStr),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson == null) return null;

    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return AuthUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyExpiresAt);
    await prefs.remove(_keyUser);
  }
}

class MemoryTokenStorageService implements TokenStorageService {
  AuthTokenPair? _tokens;
  AuthUser? _user;

  @override
  Future<void> saveTokens(AuthTokenPair tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> saveUser(AuthUser user) async {
    _user = user;
  }

  @override
  Future<String?> getAccessToken() async {
    return _tokens?.accessToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _tokens?.refreshToken;
  }

  @override
  Future<AuthTokenPair?> getTokens() async {
    return _tokens;
  }

  @override
  Future<AuthUser?> getUser() async {
    return _user;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
    _user = null;
  }
}
