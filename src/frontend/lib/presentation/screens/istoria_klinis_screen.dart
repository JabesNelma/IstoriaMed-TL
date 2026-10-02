import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/istoria_schema.dart';
import '../../logic/istoria_bloc/istoria_bloc.dart';
import '../../logic/istoria_bloc/istoria_event.dart';
import '../../logic/istoria_bloc/istoria_state.dart';
import '../widgets/status_indicator.dart';

class IstoriaKlinisScreen extends StatefulWidget {
  const IstoriaKlinisScreen({super.key});

  @override
  State<IstoriaKlinisScreen> createState() => _IstoriaKlinisScreenState();
}

class _IstoriaKlinisScreenState extends State<IstoriaKlinisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientId = TextEditingController();
  final _tenantId = TextEditingController(text: 'klinika-lokal');
  final _subjective = TextEditingController();
  final _objective = TextEditingController();
  final _assessment = TextEditingController();
  final _plan = TextEditingController();
  final _icd = TextEditingController();
  final _disease = TextEditingController();
  String _status = 'Pending';

  @override
  void dispose() {
    _patientId.dispose();
    _tenantId.dispose();
    _subjective.dispose();
    _objective.dispose();
    _assessment.dispose();
    _plan.dispose();
    _icd.dispose();
    _disease.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final record = IstoriaKlinis()
      ..pasienId = _patientId.text.trim()
      ..tenantId = _tenantId.text.trim()
      ..keluhanSubjektif = _subjective.text.trim()
      ..pemeriksaanObjektif = _objective.text.trim()
      ..analisisAsesmen = _assessment.text.trim()
      ..rencanaTindakan = _plan.text.trim()
      ..kodeIcd10 = _icd.text.trim()
      ..namaPenyakitLokal = _disease.text.trim()
      ..syncStatus = 'Pending';
    context.read<IstoriaBloc>().add(CreateIstoria(record));
  }

  Widget _soapField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
        validator: (value) => value == null || value.trim().isEmpty ? '$label tenke prenxe.' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IstoriaBloc, IstoriaState>(
      listener: (context, state) {
        if (state is IstoriaSuccess) {
          setState(() => _status = state.record.syncStatus);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.record.syncStatus == 'Synced'
                ? 'Istoria klinis sinkronizadu ho susesu!'
                : 'Istoria klinis rai lokal; sinkronizasaun sei kontinua.')),
          );
        }
        if (state is IstoriaError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final history = state is IstoriaHistoryLoaded ? state.records : const <IstoriaKlinis>[];
        final loading = state is IstoriaLoading;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Istoria Klinis', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Rejista konsultasaun SOAP no haree istoria pasiente, mesak ho ka la iha internet.'),
            const SizedBox(height: 16),
            StatusIndicator(status: _status),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patientId,
              decoration: const InputDecoration(labelText: 'ID pasiente (user_id)'),
              validator: (value) => value == null || value.trim().isEmpty ? 'ID pasiente tenke prenxe.' : null,
              onEditingComplete: () => context.read<IstoriaBloc>().add(FetchPasienHistory(_patientId.text.trim())),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenantId,
              decoration: const InputDecoration(labelText: 'ID klinika / tenant'),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SOAP', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _soapField('S - Keluhan subjektivu', _subjective),
                  _soapField('O - Pemeriksaun objetivu', _objective),
                  _soapField('A - Analiza no asesmentu', _assessment),
                  _soapField('P - Planu asaun', _plan),
                  TextFormField(
                    controller: _icd,
                    decoration: const InputDecoration(
                      labelText: 'Buka ICD-10 (kode)',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _disease,
                    decoration: const InputDecoration(labelText: 'Naran moras lokal'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: loading ? null : _save,
                    icon: loading
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Rai Istoria Klinis'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Istoria Pasiente', style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Sinkroniza kua',
                      onPressed: () => context.read<IstoriaBloc>().add(const SyncPendingIstoria()),
                      icon: const Icon(Icons.sync),
                    ),
                    IconButton(
                      tooltip: 'Lee istoria',
                      onPressed: _patientId.text.trim().isEmpty
                          ? null
                          : () => context.read<IstoriaBloc>().add(FetchPasienHistory(_patientId.text.trim())),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Seidauk iha istoria klinis iha cache.'),
              ),
            ...history.map(
              (record) => Card(
                child: ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(record.namaPenyakitLokal.isEmpty ? 'Konsultasaun' : record.namaPenyakitLokal),
                  subtitle: Text('${record.kodeIcd10} - ${record.keluhanSubjektif}'),
                  trailing: StatusIndicator(status: record.syncStatus),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
