import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/demo_seed.dart';
import '../../data/local/istoria_schema.dart';
import '../../data/local/medication.dart';
import '../../data/local/pasien_schema.dart';
import '../../data/local/prescription_schema.dart';
import '../../data/session/demo_mode.dart';
import '../../logic/prescription_bloc/prescription_bloc.dart';
import '../../logic/prescription_bloc/prescription_event.dart';
import '../../logic/prescription_bloc/prescription_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import 'prescription_detail_screen.dart';

/// New prescription form. Always opened from a visit detail screen, so the
/// patient and clinical visit context is fixed — a prescription can never be
/// created without its visit. Items follow the existing [PrescriptionItem]
/// model fields only.
class PrescriptionFormScreen extends StatefulWidget {
  const PrescriptionFormScreen({
    super.key,
    required this.pasien,
    required this.visit,
  });

  final Pasien pasien;
  final IstoriaKlinis visit;

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final List<PrescriptionItem> _items = [];
  List<Medication>? _catalog;
  String? _catalogMessage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final repository = context.read<PrescriptionBloc>().repository;
      final catalog = await repository.medications();
      if (mounted) setState(() => _catalog = catalog);
    } catch (_) {
      // The catalog is server owned reference data and has no offline cache
      // yet. In demo mode a clearly synthetic catalogue keeps the flow
      // reviewable; otherwise the development state is stated explicitly.
      if (kDemoMode) {
        if (mounted) setState(() => _catalog = demoMedications);
      } else {
        if (mounted) {
          setState(() => _catalogMessage =
              'Katalog aimoruk seidauk disponivel offline. Presiza koneksaun ba servidor.');
        }
      }
    }
  }

  String get _visitKey =>
      widget.visit.remoteId ?? widget.visit.id.toString();

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rese presiza minimal ida aimoruk.'),
      ));
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final prescription = Prescription()
      ..visitId = _visitKey
      ..prescribedAt = DateTime.now()
      ..items = List<PrescriptionItem>.from(_items);
    context.read<PrescriptionBloc>().add(CreatePrescription(prescription));
  }

  Future<void> _addOrEditItem({PrescriptionItem? existing}) async {
    final catalog = _catalog;
    if (catalog == null || catalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_catalogMessage ??
            'Katalog aimoruk seidauk disponivel. Presiza koneksaun ba servidor.'),
      ));
      return;
    }
    final result = await showDialog<PrescriptionItem>(
      context: context,
      builder: (_) => _ItemEditorDialog(catalog: catalog, existing: existing),
    );
    if (result == null) return;
    setState(() {
      if (existing != null) {
        _items[_items.indexOf(existing)] = result;
      } else {
        _items.add(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visitDate = widget.visit.tanggalKunjungan;
    final visitDateLabel = visitDate == null
        ? '—'
        : '${visitDate.day.toString().padLeft(2, '0')}/'
            '${visitDate.month.toString().padLeft(2, '0')}/'
            '${visitDate.year}';
    return Scaffold(
      appBar: AppBar(title: const Text('Rese Foun')),
      body: BlocListener<PrescriptionBloc, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionSaved) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => PrescriptionDetailScreen(
                  prescription: state.prescription,
                  pasien: widget.pasien,
                ),
              ),
            );
          } else if (state is PrescriptionError) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pasiente', style: AppTextStyles.caption),
                  Text(widget.pasien.namaLengkap,
                      style: AppTextStyles.sectionTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Kunjungan', style: AppTextStyles.caption),
                  Text(visitDateLabel, style: AppTextStyles.sectionTitle),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aimoruk', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: AppSpacing.sm),
                  if (_catalogMessage != null)
                    Text(_catalogMessage!, style: AppTextStyles.error)
                  else
                    AppButton(
                      label: 'Tau Aimoruk',
                      icon: Icons.add,
                      onPressed: () => _addOrEditItem(),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in _items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.medicationName ?? 'Aimoruk',
                              style: AppTextStyles.body,
                            ),
                            Text(
                              'Doze: ${item.dose} | Frekuensia: ${item.frequency}',
                              style: AppTextStyles.caption,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _addOrEditItem(existing: item),
                                  child: const Text('Hadia'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _items.remove(item)),
                                  child: const Text('Hasai'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<PrescriptionBloc, PrescriptionState>(
              buildWhen: (previous, current) => current is PrescriptionLoading,
              builder: (context, state) {
                final loading = _saving || state is PrescriptionLoading;
                return AppButton(
                  label: 'Rai Rese',
                  icon: Icons.save_outlined,
                  loading: loading,
                  onPressed: loading ? null : _save,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditorDialog extends StatefulWidget {
  const _ItemEditorDialog({required this.catalog, this.existing});

  final List<Medication> catalog;
  final PrescriptionItem? existing;

  @override
  State<_ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<_ItemEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dose;
  late final TextEditingController _frequency;
  late final TextEditingController _duration;
  late final TextEditingController _quantity;
  late final TextEditingController _instructions;
  Medication? _medication;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _dose = TextEditingController(text: existing?.dose ?? '');
    _frequency = TextEditingController(text: existing?.frequency ?? '');
    _duration = TextEditingController(text: existing?.duration ?? '');
    _quantity = TextEditingController(
        text: existing == null || existing.quantity == 0
            ? ''
            : existing.quantity.toString());
    _instructions =
        TextEditingController(text: existing?.instructions ?? '');
    if (existing != null) {
      _medication = widget.catalog
          .where((medication) => medication.medicationId == existing.medicationId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _dose.dispose();
    _frequency.dispose();
    _duration.dispose();
    _quantity.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _submit() {
    final medication = _medication;
    final quantity = int.tryParse(_quantity.text.trim());
    if (medication == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hili aimoruk ida husi katalog.'),
      ));
      return;
    }
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kuantidade tenki numero boot liu husi zero.'),
      ));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      PrescriptionItem()
        ..medicationId = medication.medicationId
        ..medicationName = medication.name
        ..medicationStrength = medication.strength
        ..dose = _dose.text.trim()
        ..frequency = _frequency.text.trim()
        ..duration =
            _duration.text.trim().isEmpty ? null : _duration.text.trim()
        ..quantity = quantity
        ..instructions = _instructions.text.trim().isEmpty
            ? null
            : _instructions.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tau Aimoruk' : 'Hadia Aimoruk'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              DropdownButtonFormField<Medication>(
                initialValue: _medication,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Aimoruk'),
                items: [
                  for (final medication in widget.catalog)
                    DropdownMenuItem(
                      value: medication,
                      child: Text(medication.label,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (medication) => setState(() => _medication = medication),
              ),
              AppTextField(
                controller: _dose,
                label: 'Doze *',
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Doze presiza' : null,
              ),
              AppTextField(
                controller: _frequency,
                label: 'Frekuensia *',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Frekuensia presiza'
                    : null,
              ),
              AppTextField(
                controller: _duration,
                label: 'Durasaun',
              ),
              AppTextField(
                controller: _quantity,
                label: 'Kuantidade *',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    int.tryParse(value?.trim() ?? '') == null
                        ? 'Kuantidade tenki numero'
                        : null,
              ),
              AppTextField(
                controller: _instructions,
                label: 'Intrusaun',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kansela'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Tau')),
      ],
    );
  }
}
