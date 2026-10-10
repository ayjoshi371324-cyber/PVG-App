import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';

enum UserRole {
  passenger,
  driver,
  ops;

  String get displayName {
    switch (this) {
      case UserRole.passenger:
        return 'Passenger';
      case UserRole.driver:
        return 'Driver';
      case UserRole.ops:
        return 'Fleet Operations';
    }
  }
}

class AuthTokenPair extends Equatable {
  const AuthTokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory AuthTokenPair.fromJson(Map<String, dynamic> json) {
    return AuthTokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.vehicleTier,
    this.licensePlate,
    this.driverLicenseNumber,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;

  // Driver specifics
  final VehicleTier? vehicleTier;
  final String? licensePlate;
  final String? driverLicenseNumber;

  bool get isDriver => role == UserRole.driver;
  bool get isPassenger => role == UserRole.passenger;
  bool get isOps => role == UserRole.ops;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'vehicle_tier': vehicleTier?.name,
        'license_plate': licensePlate,
        'driver_license_number': driverLicenseNumber,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.passenger,
    );

    final tierStr = json['vehicle_tier'] as String?;
    final tier = tierStr != null
        ? VehicleTier.values.firstWhere(
            (t) => t.name == tierStr,
            orElse: () => VehicleTier.car,
          )
        : null;

    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: role,
      vehicleTier: tier,
      licensePlate: json['license_plate'] as String?,
      driverLicenseNumber: json['driver_license_number'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        vehicleTier,
        licensePlate,
        driverLicenseNumber,
      ];
}

class RegisterPassengerRequest extends Equatable {
  const RegisterPassengerRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  final String name;
  final String email;
  final String password;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'passenger',
      };

  @override
  List<Object?> get props => [name, email, password, phone];
}

class RegisterDriverRequest extends Equatable {
  const RegisterDriverRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    required this.vehicleTier,
    required this.licensePlate,
    required this.driverLicenseNumber,
  });

  final String name;
  final String email;
  final String password;
  final String? phone;
  final VehicleTier vehicleTier;
  final String licensePlate;
  final String driverLicenseNumber;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'driver',
        'vehicle_tier': vehicleTier.name,
        'license_plate': licensePlate,
        'driver_license_number': driverLicenseNumber,
      };

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        phone,
        vehicleTier,
        licensePlate,
        driverLicenseNumber,
      ];
}

class AuthResponse extends Equatable {
  const AuthResponse({
    required this.user,
    required this.tokens,
  });

  final AuthUser user;
  final AuthTokenPair tokens;

  @override
  List<Object?> get props => [user, tokens];
}
