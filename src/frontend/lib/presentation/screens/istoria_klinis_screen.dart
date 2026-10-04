import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/istoria_schema.dart';
import '../../data/local/pasien_schema.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/istoria_bloc/istoria_bloc.dart';
import '../../logic/istoria_bloc/istoria_event.dart';
import '../../logic/istoria_bloc/istoria_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'visit_detail_screen.dart';

/// New clinical visit form. Always opened from a patient profile, so the
/// patient context is fixed and never re-selected here. SOAP + ICD-10 follow
/// the existing `IstoriaKlinis` model — no invented fields.
class IstoriaKlinisScreen extends StatefulWidget {
  const IstoriaKlinisScreen({super.key, required this.pasien});

  final Pasien pasien;

  @override
  State<IstoriaKlinisScreen> createState() => _IstoriaKlinisScreenState();
}

class _IstoriaKlinisScreenState extends State<IstoriaKlinisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjective = TextEditingController();
  final _objective = TextEditingController();
  final _assessment = TextEditingController();
  final _plan = TextEditingController();
  final _icd = TextEditingController();
  final _disease = TextEditingController();
  DateTime _visitDate = DateTime.now();
  bool _navigated = false;

  @override
  void dispose() {
    _subjective.dispose();
    _objective.dispose();
    _assessment.dispose();
    _plan.dispose();
    _icd.dispose();
    _disease.dispose();
    super.dispose();
  }

  Future<void> _chooseVisitDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _visitDate,
      helpText: 'Hili data kunjungan',
      cancelText: 'Kansela',
      confirmText: 'Hili',
    );
    if (selected != null) setState(() => _visitDate = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // Tenant comes from the authenticated session's membership, exactly like
    // the sync payload expects; it is never typed by the user.
    final authState = context.read<AuthBloc>().state;
    final session =
        authState is AuthAuthenticated ? authState.session : null;
    final tenantId = session?.primaryMembership?.tenantId ?? 'klinika-lokal';
    final record = IstoriaKlinis()
      ..pasienId = widget.pasien.remoteId ?? widget.pasien.id.toString()
      ..tenantId = tenantId
      ..keluhanSubjektif = _subjective.text.trim()
      ..pemeriksaanObjektif = _objective.text.trim()
      ..analisisAsesmen = _assessment.text.trim()
      ..rencanaTindakan = _plan.text.trim()
      ..kodeIcd10 = _icd.text.trim()
      ..namaPenyakitLokal = _disease.text.trim()
      ..tanggalKunjungan = _visitDate
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
        validator: (value) =>
            value == null || value.trim().isEmpty ? '$label tenke prenxe.' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pasien = widget.pasien;
    return BlocConsumer<IstoriaBloc, IstoriaState>(
      listener: (context, state) {
        if (state is IstoriaSuccess && !_navigated) {
          _navigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => VisitDetailScreen(
                record: state.record,
                pasien: pasien,
              ),
            ),
          );
        }
        if (state is IstoriaError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is IstoriaLoading;
        return Scaffold(
          appBar: AppBar(title: const Text('Kunjungan Foun')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pasiente', style: AppTextStyles.caption),
                      Text(
                        pasien.namaLengkap,
                        style: AppTextStyles.sectionTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('MRN: ${pasien.medicalRecordNumber ?? '-'}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Data kunjungan'),
                  subtitle: Text(
                      '${_visitDate.day.toString().padLeft(2, '0')}/'
                      '${_visitDate.month.toString().padLeft(2, '0')}/'
                      '${_visitDate.year}'),
                  trailing: FilledButton.tonal(
                    onPressed: loading ? null : _chooseVisitDate,
                    child: const Text('Hili'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('SOAP', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                _soapField('S - Keluhan subjektivu', _subjective),
                _soapField('O - Pemeriksaun objetivu', _objective),
                _soapField('A - Analiza no asesmentu', _assessment),
                _soapField('P - Planu asaun', _plan),
                TextFormField(
                  controller: _icd,
                  decoration: const InputDecoration(
                    labelText: 'Diagnoze / ICD-10 (kode)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kode ICD-10 tenke prenxe.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _disease,
                  decoration:
                      const InputDecoration(labelText: 'Naran moras lokal'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Naran moras tenke prenxe.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: loading ? null : _save,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('Rai Kunjungan'),
                ),
                // Room for the bottom inset so the keyboard never hides the
                // save button while typing the plan field.
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}
