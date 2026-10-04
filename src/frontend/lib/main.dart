import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/sync/sync_service.dart';
import 'data/local/local_database.dart';
import 'data/remote/api_client.dart';
import 'data/session/session_store.dart';
import 'repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isar = await LocalDatabase.open();
  final apiClient = ApiClient();
  final authRepository = ApiClientAuthRepository(apiClient, SessionStore(isar));
  final syncService = SyncService(isar: isar, apiClient: apiClient);

  // Startup drain of the persistent queue: whatever survived the last process
  // is retried, and an interrupted SYNCING operation is recovered.
  unawaited(syncService.syncPending());

  runApp(buildIstoriaMedApp(
    isar: isar,
    apiClient: apiClient,
    authRepository: authRepository,
  ));
}
