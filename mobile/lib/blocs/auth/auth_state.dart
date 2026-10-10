import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/auth_models.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading({this.message});
  final String? message;

  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  const Authenticated({
    required this.user,
    required this.tokens,
  });

  final AuthUser user;
  final AuthTokenPair tokens;

  @override
  List<Object?> get props => [user, tokens];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
