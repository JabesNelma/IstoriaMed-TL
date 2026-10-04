import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/data/local/session_schema.dart';
import 'package:frontend/data/remote/api_client.dart';
import 'package:frontend/data/session/auth_session.dart';
import 'package:frontend/repositories/auth_repository.dart';
import 'package:isar/isar.dart';

import 'support/isar_test_support.dart';

/// Deterministic auth repository for routing tests: no network involved.
/// `loginResponse == null` simulates invalid credentials.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginResponse, this.restoredSession});

  Map<String, dynamic>? loginResponse;
  AuthSession? restoredSession;
  bool logoutCalled = false;

  @override
  Future<AuthSession> login({
    required String loginIdentifier,
    required String password,
  }) async {
    final response = loginResponse;
    if (response == null) {
      throw const AuthFailure('Login falha. Login identifier ka password la loos.');
    }
    return AuthSession.fromLoginResponse(response);
  }

  @override
  Future<AuthSession?> restore() => Future.value(restoredSession);

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

Map<String, dynamic> _loginResponse({required String role}) => {
      'access_token': 'token-for-testing-only',
      'token_type': 'Bearer',
      'expires_in': '15m',
      'user': {
        'user_id': 'user-1',
        'login_identifier': 'staff@example.tl',
        'memberships': [
          {'facility_id': 'facility-1', 'tenant_id': 'tenant-1', 'role': role},
        ],
      },
    };

void main() {
  setUpAll(initializeIsarForTests);

  late Directory directory;
  late Isar isar;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('istoria-auth-');
    isar = await Isar.open(
      [AppSessionSchema],
      directory: directory.path,
      name: 'istoria_auth_test',
    );
  });

  tearDown(() async {
    if (isar.isOpen) await isar.close(deleteFromDisk: true);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  Future<void> pumpApp(
    WidgetTester tester,
    FakeAuthRepository authRepository,
  ) async {
    await tester.pumpWidget(buildIstoriaMedApp(
      isar: isar,
      apiClient: ApiClient(baseUrl: 'http://localhost:1/api'),
      authRepository: authRepository,
    ));
    // Splash resolves after the bootstrap microtask; a few fixed pumps are
    // enough for the listener navigation to fire and land on the target
    // screen. pumpAndSettle is avoided while the splash spinner is alive.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> loginAs(WidgetTester tester, String identifier) async {
    await tester.enterText(find.byType(TextFormField).at(0), identifier);
    await tester.enterText(find.byType(TextFormField).at(1), 'correct-horse-battery');
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
  }

  testWidgets('Case 1: fresh app -> splash -> login', (tester) async {
    await pumpApp(tester, FakeAuthRepository(restoredSession: null));
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('IstoriaMed-TL'), findsWidgets);
  });

  testWidgets('Case 2: valid staff login -> staff home', (tester) async {
    final repository = FakeAuthRepository(
      loginResponse: _loginResponse(role: 'DOCTOR'),
    );
    await pumpApp(tester, repository);
    await loginAs(tester, 'staff@example.tl');

    expect(find.text('Selamat datang,'), findsOneWidget);
    expect(find.text('Fasilitas: facility-1'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('Case 2b: restored staff session -> splash routes straight to staff home',
      (tester) async {
    final repository = FakeAuthRepository(
      restoredSession:
          AuthSession.fromLoginResponse(_loginResponse(role: 'NURSE')),
    );
    await pumpApp(tester, repository);
    expect(find.text('Selamat datang,'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
  });

  testWidgets('Case 3: valid patient login -> patient home', (tester) async {
    final repository = FakeAuthRepository(
      loginResponse: _loginResponse(role: 'PATIENT'),
    );
    await pumpApp(tester, repository);
    await loginAs(tester, 'pasien@example.tl');

    expect(find.text('Selamat datang,'), findsOneWidget);
    expect(find.text('Riwayat Medis'), findsWidgets);
    expect(find.text('Fasilitas: facility-1'), findsNothing);
  });

  testWidgets('Case 4: logout clears the stack back to login', (tester) async {
    final repository = FakeAuthRepository(
      loginResponse: _loginResponse(role: 'DOCTOR'),
    );
    await pumpApp(tester, repository);
    await loginAs(tester, 'staff@example.tl');

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(repository.logoutCalled, isTrue);
    expect(find.text('LOGIN'), findsOneWidget);
    // Back must not return to the authenticated shell.
    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigatorState.canPop(), isFalse);
  });

  testWidgets('Case 5: invalid login stays on login with a readable error',
      (tester) async {
    final repository = FakeAuthRepository(loginResponse: null);
    await pumpApp(tester, repository);
    await loginAs(tester, 'staff@example.tl');

    expect(find.text('Login falha. Login identifier ka password la loos.'),
        findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Selamat datang,'), findsNothing);
  });

  testWidgets('Case 6: unsupported role lands on the safe error screen',
      (tester) async {
    final repository = FakeAuthRepository(
      loginResponse: _loginResponse(role: 'SUPER_ADMIN'),
    );
    await pumpApp(tester, repository);
    await loginAs(tester, 'admin@example.tl');

    expect(find.text('Parsing rola la suportadu'), findsOneWidget);
    expect(find.text('Selamat datang,'), findsNothing);
  });

  testWidgets('Case 7 (kDemoMode): preview buttons enter staff and patient shells '
      'without credentials', (tester) async {
    await pumpApp(tester, FakeAuthRepository(restoredSession: null));

    await tester.tap(find.text('Lihat UI Staf'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang,'), findsOneWidget);
    expect(find.text('Fasilitas: demo-fasilitas'), findsOneWidget);

    // Demo logout returns to login (nothing was persisted).
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);

    await tester.ensureVisible(find.text('Lihat UI Pasien'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat UI Pasien'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Medis'), findsWidgets);
  });
}
