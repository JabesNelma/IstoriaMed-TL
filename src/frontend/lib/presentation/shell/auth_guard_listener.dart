import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_bloc/auth_bloc.dart';

/// Shared guard for every authenticated screen: the moment the session state
/// leaves AUTHENTICATED (logout, or a future expiry handler), the user is sent
/// to /login with the whole navigation stack cleared, so back can never return
/// to an authenticated screen.
class AuthGuardListener extends StatelessWidget {
  const AuthGuardListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthLoginFailure) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (_) => false);
        }
      },
      child: child,
    );
  }
}
