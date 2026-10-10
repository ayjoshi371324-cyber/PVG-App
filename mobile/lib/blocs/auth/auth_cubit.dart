import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/auth/auth_state.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/services/auth_service.dart';
import 'package:ridepool_app/services/token_storage_service.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    AuthService? authService,
    TokenStorageService? tokenStorage,
  })  : _authService = authService ?? MockAuthService(),
        _tokenStorage = tokenStorage ?? SharedPreferencesTokenStorageService(),
        super(const AuthInitial());

  final AuthService _authService;
  final TokenStorageService _tokenStorage;

  Future<void> restoreSession() async {
    try {
      final tokens = await _tokenStorage.getTokens();
      final user = await _tokenStorage.getUser();

      if (tokens != null && user != null) {
        if (!tokens.isExpired) {
          emit(Authenticated(user: user, tokens: tokens));
          return;
        } else {
          // Token expired, attempt refresh
          try {
            final refreshedTokens = await _authService.refreshToken(tokens.refreshToken);
            await _tokenStorage.saveTokens(refreshedTokens);
            emit(Authenticated(user: user, tokens: refreshedTokens));
            return;
          } catch (_) {
            await _tokenStorage.clear();
          }
        }
      }
      emit(const Unauthenticated());
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading(message: 'Signing in...'));
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      await _tokenStorage.saveTokens(response.tokens);
      await _tokenStorage.saveUser(response.user);
      emit(Authenticated(user: response.user, tokens: response.tokens));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> loginAsDemo(UserRole role) async {
    emit(const AuthLoading(message: 'Logging in as demo account...'));
    String email;
    switch (role) {
      case UserRole.passenger:
        email = MockAuthService.demoPassenger.email;
        break;
      case UserRole.driver:
        email = MockAuthService.demoDriver.email;
        break;
      case UserRole.ops:
        email = MockAuthService.demoOps.email;
        break;
    }

    try {
      final response = await _authService.login(
        email: email,
        password: 'password123',
      );
      await _tokenStorage.saveTokens(response.tokens);
      await _tokenStorage.saveUser(response.user);
      emit(Authenticated(user: response.user, tokens: response.tokens));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> registerPassenger(RegisterPassengerRequest request) async {
    emit(const AuthLoading(message: 'Creating passenger account...'));
    try {
      final response = await _authService.registerPassenger(request);
      await _tokenStorage.saveTokens(response.tokens);
      await _tokenStorage.saveUser(response.user);
      emit(Authenticated(user: response.user, tokens: response.tokens));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> registerDriver(RegisterDriverRequest request) async {
    emit(const AuthLoading(message: 'Verifying vehicle and onboarding driver...'));
    try {
      final response = await _authService.registerDriver(request);
      await _tokenStorage.saveTokens(response.tokens);
      await _tokenStorage.saveUser(response.user);
      emit(Authenticated(user: response.user, tokens: response.tokens));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> refreshToken() async {
    final currentState = state;
    if (currentState is! Authenticated) return;

    try {
      final newTokens = await _authService.refreshToken(currentState.tokens.refreshToken);
      await _tokenStorage.saveTokens(newTokens);
      emit(Authenticated(user: currentState.user, tokens: newTokens));
    } catch (e) {
      emit(AuthError('Failed to refresh token: $e'));
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    emit(const Unauthenticated());
  }
}
