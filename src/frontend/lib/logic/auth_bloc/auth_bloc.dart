import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/session/auth_session.dart';
import '../../repositories/auth_repository.dart';

/// The shells a demo (preview) session may enter.
enum DemoRoleGroup { staff, patient }

/// Session state machine for the whole app.
///
/// UNKNOWN          — bootstrap still reading the local store.
/// AUTHENTICATED    — a session exists and the API client carries its token.
/// UNAUTHENTICATED  — no session (never logged in, logged out, or login failed).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthUnknown()) {
    on<AuthBootstrapRequested>(_bootstrap);
    on<AuthLoginSubmitted>(_login);
    on<AuthLogoutRequested>(_logout);
    on<AuthDemoLoginRequested>(_demoLogin);
  }

  final AuthRepository _repository;

  Future<void> _bootstrap(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    final session = await _repository.restore();
    emit(session == null
        ? const AuthUnauthenticated()
        : AuthAuthenticated(session));
  }

  Future<void> _login(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthAuthenticating());
    try {
      final session = await _repository.login(
        loginIdentifier: event.loginIdentifier,
        password: event.password,
      );
      emit(AuthAuthenticated(session));
    } on AuthFailure catch (failure) {
      emit(AuthLoginFailure(failure.message));
    }
  }

  Future<void> _logout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  /// UI/UX preview path (kDemoMode): emits an authenticated state with a
  /// synthetic session. No repository call, nothing saved, nothing sent —
  /// logging out afterwards simply returns to the login screen.
  Future<void> _demoLogin(
    AuthDemoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      AuthAuthenticated(
        AuthSession.demo(
          role: event.roleGroup == DemoRoleGroup.patient ? 'PATIENT' : 'DOCTOR',
        ),
      ),
    );
  }
}

sealed class AuthEvent {
  const AuthEvent();
}

class AuthBootstrapRequested extends AuthEvent {
  const AuthBootstrapRequested();
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.loginIdentifier, required this.password});

  final String loginIdentifier;
  final String password;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Dev-preview only (kDemoMode): enter a shell without credentials.
class AuthDemoLoginRequested extends AuthEvent {
  const AuthDemoLoginRequested(this.roleGroup);

  final DemoRoleGroup roleGroup;
}

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Session state is not known yet (splash is deciding where to go).
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Login request in flight; the submit button stays disabled.
class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

/// Login failed; the user stays on the login screen with a readable message.
class AuthLoginFailure extends AuthState {
  const AuthLoginFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
