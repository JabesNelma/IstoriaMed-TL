import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/pasien_schema.dart';
import '../../data/local/prescription_schema.dart';
import '../../logic/prescription_bloc/prescription_bloc.dart';
import '../../logic/prescription_bloc/prescription_event.dart';
import '../../logic/prescription_bloc/prescription_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_indicator.dart';
import 'prescription_detail_screen.dart';

/// Resep & Obat list for one patient. Read from the local store through the
/// existing PrescriptionRepository (Patient -> Visit -> Prescription), so it
/// renders fully offline.
class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key, required this.pasien});

  final Pasien pasien;

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<PrescriptionBloc>()
        .add(LoadPatientPrescriptions(_patientKey));
  }

  String get _patientKey =>
      widget.pasien.remoteId ?? widget.pasien.id.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep & Aimoruk')),
      body: BlocBuilder<PrescriptionBloc, PrescriptionState>(
        builder: (context, state) {
          if (state is PrescriptionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PrescriptionError) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(state.message, style: AppTextStyles.error),
              ],
            );
          }
          final prescriptions = state is PrescriptionListLoaded
              ? state.prescriptions
              : const <Prescription>[];
          if (prescriptions.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                AppCard(
                  child: Text(
                    'Seidauk iha rese ba pasiente ida nee.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final prescription in prescriptions) ...[
                AppCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PrescriptionDetailScreen(
                        prescription: prescription,
                        pasien: widget.pasien,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dateLabel(prescription),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Rese', style: AppTextStyles.sectionTitle),
                      Text(
                        '${prescription.items.length} aimoruk',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StatusIndicator(status: prescription.syncStatus),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }

  String _dateLabel(Prescription prescription) {
    final date = prescription.prescribedAt;
    if (date == null) return 'Data la iha';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
