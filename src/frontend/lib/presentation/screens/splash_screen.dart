import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/session/auth_session.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../theme/app_theme.dart';

/// Entry point of the app. Shows the brand, waits for the session state to
/// resolve (a local Isar read — no network call, no duplicate API traffic),
/// then routes once. A cancelled-on-dispose fallback timer prevents an
/// infinite splash if the session state never resolves.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _fallbackTimeout = Duration(seconds: 4);
  Timer? _fallback;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _fallback = Timer(_fallbackTimeout, _goToLogin);
  }

  @override
  void dispose() {
    _fallback?.cancel();
    super.dispose();
  }

  void _goToLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _navigate(BuildContext context, AuthState state) {
    if (_navigated) return;
    if (state is AuthAuthenticated) {
      _navigated = true;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(routeForRole(state.session), (_) => false);
    } else if (state is AuthUnauthenticated || state is AuthLoginFailure) {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) => _navigate(context, state),
      builder: (context, state) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('IstoriaMed-TL', style: AppTextStyles.appTitle),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Sistem Rekam Medis\nTimor-Leste',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Loading...', style: AppTextStyles.caption),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Maps an authenticated session to its shell route. Unknown roles must never
/// silently fall back to any home — they land on the unsupported-role screen.
String routeForRole(AuthSession session) {
  return switch (session.roleGroup) {
    RoleGroup.staff => '/staff',
    RoleGroup.patient => '/patient',
    RoleGroup.unsupported => '/unsupported-role',
  };
}
