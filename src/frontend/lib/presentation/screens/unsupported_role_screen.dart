import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_bloc/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

/// Shown when the logged-in account has no role the APK supports. There is no
/// silent fallback: the session stays but the user gets a safe explanation and
/// the only way forward is logout.
class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthBloc>().state;
    final identifier =
        session is AuthAuthenticated ? session.session.loginIdentifier : '';
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.no_accounts_outlined,
                  size: 64, color: AppColors.muted),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Parsing rola la suportadu',
                textAlign: TextAlign.center,
                style: AppTextStyles.appTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Kontu "$identifier" iha rola nebe aplikasaun mobil ida-ne\'e '
                'la suporta. Favor kontakta administrador fasilidade.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Sai (Logout)',
                icon: Icons.logout,
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
