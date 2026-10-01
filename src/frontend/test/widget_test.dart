import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/logic/pasien_bloc/pasien_bloc.dart';
import 'package:frontend/presentation/screens/register_pasien_screen.dart';

void main() {
  testWidgets('formulario rejistu pasiente hatudu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PasienBloc.testing(),
          child: const Scaffold(body: RegisterPasienScreen()),
        ),
      ),
    );

    expect(find.text('Rejistu Pasiente Foun'), findsOneWidget);
    expect(find.text('Numeru KTP'), findsOneWidget);
    expect(find.text('Scan Fingerprint (Simulasaun)'), findsOneWidget);
  });
}
