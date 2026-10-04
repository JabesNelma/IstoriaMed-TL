import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_bloc/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import 'auth_guard_listener.dart';

/// Patient-facing shell. The backend does not issue the PATIENT role yet, so
/// every page below is an explicit placeholder — nothing here claims to load
/// or send patient data.
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final session = state is AuthAuthenticated ? state.session : null;
    return AuthGuardListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('IstoriaMed-TL')),
        body: IndexedStack(
          index: _index,
          children: [
            _PatientHome(identifier: session?.loginIdentifier ?? ''),
            const _PlaceholderPage(
                title: 'Riwayat Medis',
                message: 'Seidauk disponivel iha versiu ida-ne\'e.'),
            const _PlaceholderPage(
                title: 'Resep',
                message: 'Seidauk disponivel iha versiu ida-ne\'e.'),
            const _ProfileTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.history_outlined), label: 'Riwayat'),
            NavigationDestination(
                icon: Icon(Icons.medication_outlined), label: 'Resep'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _PatientHome extends StatelessWidget {
  const _PatientHome({required this.identifier});

  final String identifier;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Selamat datang,', style: AppTextStyles.caption),
        Text(identifier, style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.lg),
        const AppMenuItem(
          icon: Icons.history_outlined,
          title: 'Riwayat Medis',
          subtitle: 'Seidauk disponivel iha APK',
          enabled: false,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppMenuItem(
          icon: Icons.medication_outlined,
          title: 'Resep',
          subtitle: 'Seidauk disponivel iha APK',
          enabled: false,
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final session = state is AuthAuthenticated ? state.session : null;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session?.loginIdentifier ?? '—',
                  style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Text('User ID: ${session?.userId ?? '—'}',
                  style: AppTextStyles.caption),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Logout',
          icon: Icons.logout,
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
      ],
    );
  }
}
