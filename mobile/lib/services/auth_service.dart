import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';

abstract class AuthService {
  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  Future<AuthResponse> registerPassenger(RegisterPassengerRequest request);

  Future<AuthResponse> registerDriver(RegisterDriverRequest request);

  Future<AuthTokenPair> refreshToken(String refreshToken);

  Future<AuthUser?> getCurrentUser(String accessToken);
}

class MockAuthService implements AuthService {
  // Pre-configured demo accounts
  static const demoPassenger = AuthUser(
    id: 'usr-demo-pax-1',
    name: 'Pooja Sharma',
    email: 'passenger@ridepool.ai',
    phone: '+91 98234 56789',
    role: UserRole.passenger,
  );

  static const demoDriver = AuthUser(
    id: 'usr-demo-drv-1',
    name: 'Santosh Tambe',
    email: 'driver@ridepool.ai',
    phone: '+91 98901 23456',
    role: UserRole.driver,
    vehicleTier: VehicleTier.car,
    licensePlate: 'MH 12 RN 8842',
    driverLicenseNumber: 'DL-MH12-2022-9842',
  );

  static const demoOps = AuthUser(
    id: 'usr-demo-ops-1',
    name: 'Fleet Controller',
    email: 'ops@ridepool.ai',
    phone: '+91 98000 11223',
    role: UserRole.ops,
  );

  final Map<String, AuthUser> _usersByEmail = {
    demoPassenger.email: demoPassenger,
    demoDriver.email: demoDriver,
    demoOps.email: demoOps,
  };

  AuthTokenPair _generateTokens(String userId, UserRole role) {
    final now = DateTime.now();
    // Deterministic mock JWT payload simulation
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': userId,
      'role': role.name,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': (now.millisecondsSinceEpoch ~/ 1000) + 3600,
    })));
    final sig = base64Url.encode(utf8.encode('mock_signature_${now.millisecondsSinceEpoch}'));
    final accessToken = '$header.$payload.$sig';

    final refreshToken = 'rf_${userId}_${now.millisecondsSinceEpoch}';

    return AuthTokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: now.add(const Duration(hours: 1)),
    );
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final normalized = email.trim().toLowerCase();
    final user = _usersByEmail[normalized];

    if (user != null) {
      final tokens = _generateTokens(user.id, user.role);
      return AuthResponse(user: user, tokens: tokens);
    }

    // Default fallback for any valid-looking login in mock mode
    final role = normalized.contains('driver') ? UserRole.driver : UserRole.passenger;
    final fallbackUser = AuthUser(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first,
      email: normalized,
      role: role,
      vehicleTier: role == UserRole.driver ? VehicleTier.car : null,
      licensePlate: role == UserRole.driver ? 'MH 12 RN 8842' : null,
      driverLicenseNumber: role == UserRole.driver ? 'DL-MH12-2022-9842' : null,
    );

    _usersByEmail[normalized] = fallbackUser;
    final tokens = _generateTokens(fallbackUser.id, fallbackUser.role);
    return AuthResponse(user: fallbackUser, tokens: tokens);
  }

  @override
  Future<AuthResponse> registerPassenger(RegisterPassengerRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = AuthUser(
      id: 'usr-pax-${DateTime.now().millisecondsSinceEpoch}',
      name: request.name,
      email: request.email.trim().toLowerCase(),
      phone: request.phone,
      role: UserRole.passenger,
    );

    _usersByEmail[user.email] = user;
    final tokens = _generateTokens(user.id, user.role);
    return AuthResponse(user: user, tokens: tokens);
  }

  @override
  Future<AuthResponse> registerDriver(RegisterDriverRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = AuthUser(
      id: 'usr-drv-${DateTime.now().millisecondsSinceEpoch}',
      name: request.name,
      email: request.email.trim().toLowerCase(),
      phone: request.phone,
      role: UserRole.driver,
      vehicleTier: request.vehicleTier,
      licensePlate: request.licensePlate,
      driverLicenseNumber: request.driverLicenseNumber,
    );

    _usersByEmail[user.email] = user;
    final tokens = _generateTokens(user.id, user.role);
    return AuthResponse(user: user, tokens: tokens);
  }

  @override
  Future<AuthTokenPair> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _generateTokens('usr-refreshed', UserRole.passenger);
  }

  @override
  Future<AuthUser?> getCurrentUser(String accessToken) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return demoPassenger;
  }
}

class HttpAuthService implements AuthService {
  HttpAuthService({
    this.baseUrl = 'http://localhost:8000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = AuthTokenPair.fromJson(data['tokens'] as Map<String, dynamic>);
      return AuthResponse(user: user, tokens: tokens);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  @override
  Future<AuthResponse> registerPassenger(RegisterPassengerRequest request) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register/passenger'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = AuthTokenPair.fromJson(data['tokens'] as Map<String, dynamic>);
      return AuthResponse(user: user, tokens: tokens);
    } else {
      throw Exception('Passenger registration failed: ${response.body}');
    }
  }

  @override
  Future<AuthResponse> registerDriver(RegisterDriverRequest request) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register/driver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = AuthTokenPair.fromJson(data['tokens'] as Map<String, dynamic>);
      return AuthResponse(user: user, tokens: tokens);
    } else {
      throw Exception('Driver registration failed: ${response.body}');
    }
  }

  @override
  Future<AuthTokenPair> refreshToken(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokenPair.fromJson(data);
    } else {
      throw Exception('Token refresh failed: ${response.body}');
    }
  }

  @override
  Future<AuthUser?> getCurrentUser(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    }
    return null;
  }
}
