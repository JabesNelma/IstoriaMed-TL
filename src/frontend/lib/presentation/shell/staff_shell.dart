import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_bloc/auth_bloc.dart';
import '../../data/session/auth_session.dart';
import '../screens/pasien_list_screen.dart';
import '../screens/sync_center_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import 'auth_guard_listener.dart';

/// Healthcare staff shell (DOCTOR, NURSE, MIDWIFE, PHARMACY). Menu permission
/// per role is a later phase; for now every staff role sees the same shell.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
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
            _StaffHome(
              session: session,
              onOpenTab: (index) => setState(() => _index = index),
            ),
            const PasienListScreen(),
            const SyncCenterScreen(),
            const _ProfileTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.person_add_alt_1), label: 'Pasien'),
            NavigationDestination(
                icon: Icon(Icons.sync_outlined), label: 'Sync'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _StaffHome extends StatelessWidget {
  const _StaffHome({required this.session, required this.onOpenTab});

  final AuthSession? session;
  final void Function(int) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final identifier = session?.loginIdentifier ?? '';
    final facility = session?.primaryMembership?.facilityId ?? '—';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Selamat datang,', style: AppTextStyles.caption),
        Text(identifier, style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        Text('Fasilitas: $facility', style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.lg),
        AppMenuItem(
          icon: Icons.person_add_alt_1,
          title: 'Pasien',
          subtitle: 'Rejistu no buka pasiente',
          onTap: () => onOpenTab(1),
        ),
        const SizedBox(height: AppSpacing.md),
        // Clinical visits always live in the patient context (Pasien -> pasiente
        // -> Kunjungan Foun / Riwayat Kunjungan), so there is no visits menu.
        AppMenuItem(
          icon: Icons.sync_outlined,
          title: 'Sinkronisasi',
          subtitle: 'Haree dadus pendentes no sinkroniza',
          onTap: () => onOpenTab(2),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final session = state is AuthAuthenticated ? state.session : null;
    final memberships = session?.memberships ?? const <AppMembership>[];
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
        Text('Fasilitas / Rola', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        for (final membership in memberships) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(membership.role, style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Facility: ${membership.facilityId}\nTenant: ${membership.tenantId}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
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
