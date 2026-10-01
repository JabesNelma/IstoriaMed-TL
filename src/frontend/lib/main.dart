import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/sync/sync_service.dart';
import 'data/local/local_database.dart';
import 'data/remote/api_client.dart';
import 'logic/istoria_bloc/istoria_bloc.dart';
import 'logic/pasien_bloc/pasien_bloc.dart';
import 'presentation/screens/istoria_klinis_screen.dart';
import 'presentation/screens/register_pasien_screen.dart';
import 'repositories/istoria_repository.dart';
import 'repositories/pasien_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isar = await LocalDatabase.open();
  final apiClient = ApiClient();
  final pasienRepository = PasienRepository(isar: isar, apiClient: apiClient);
  final istoriaRepository = IstoriaRepository(isar: isar, apiClient: apiClient);
  final syncService = SyncService(
    pasienRepository: pasienRepository,
    istoriaRepository: istoriaRepository,
  );

  Timer.periodic(const Duration(minutes: 1), (_) => syncService.synchronize());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: pasienRepository),
        RepositoryProvider.value(value: istoriaRepository),
      ],
      child: const IstoriaMedApp(),
    ),
  );
}

class IstoriaMedApp extends StatelessWidget {
  const IstoriaMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PasienBloc(context.read<PasienRepository>()),
        ),
        BlocProvider(
          create: (context) => IstoriaBloc(context.read<IstoriaRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'IstoriaMed-TL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff116466)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const IstoriaMedHome(),
      ),
    );
  }
}

class IstoriaMedHome extends StatefulWidget {
  const IstoriaMedHome({super.key});

  @override
  State<IstoriaMedHome> createState() => _IstoriaMedHomeState();
}

class _IstoriaMedHomeState extends State<IstoriaMedHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IstoriaMed-TL')),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          RegisterPasienScreen(),
          IstoriaKlinisScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_1),
            label: 'Pasiente Foun',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'Istoria Klinis',
          ),
        ],
      ),
    );
  }
}
