import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import 'core/sync/sync_service.dart';
import 'data/remote/api_client.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'logic/istoria_bloc/istoria_bloc.dart';
import 'logic/pasien_bloc/pasien_bloc.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/unsupported_role_screen.dart';
import 'presentation/shell/patient_shell.dart';
import 'presentation/shell/staff_shell.dart';
import 'presentation/theme/app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/istoria_repository.dart';
import 'repositories/pasien_repository.dart';

/// Composition root: wires the existing repositories/blocs plus the new
/// session stack into one widget tree. Used by main() and by the tests.
Widget buildIstoriaMedApp({
  required Isar isar,
  required ApiClient apiClient,
  required AuthRepository authRepository,
}) {
  final pasienRepository = PasienRepository(isar: isar, apiClient: apiClient);
  final istoriaRepository = IstoriaRepository(isar: isar, apiClient: apiClient);
  final syncService = SyncService(isar: isar, apiClient: apiClient);
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: pasienRepository),
      RepositoryProvider.value(value: istoriaRepository),
      RepositoryProvider.value(value: syncService),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(authRepository)
            ..add(const AuthBootstrapRequested()),
        ),
        BlocProvider(
          create: (_) =>
              PasienBloc(pasienRepository, syncService),
        ),
        BlocProvider(
          create: (_) =>
              IstoriaBloc(istoriaRepository, syncService),
        ),
      ],
      child: const IstoriaMedApp(),
    ),
  );
}

class IstoriaMedApp extends StatelessWidget {
  const IstoriaMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IstoriaMed-TL',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // One consistent routing system: named routes, splash as entry point,
      // role router deciding the shell. Deep links into protected routes are
      // caught by AuthGuardListener inside each shell.
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/staff': (_) => const StaffShell(),
        '/patient': (_) => const PatientShell(),
        '/unsupported-role': (_) => const UnsupportedRoleScreen(),
      },
    );
  }
}
