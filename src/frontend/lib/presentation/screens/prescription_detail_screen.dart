import 'package:flutter/material.dart';

import '../../data/local/pasien_schema.dart';
import '../../data/local/prescription_schema.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_indicator.dart';

/// Read-only prescription detail. Renders straight from the local record the
/// caller already holds — no network round trip, works fully offline.
class PrescriptionDetailScreen extends StatelessWidget {
  const PrescriptionDetailScreen({
    super.key,
    required this.prescription,
    required this.pasien,
  });

  final Prescription prescription;
  final Pasien pasien;

  String get _dateLabel {
    final date = prescription.prescribedAt;
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhu Rese')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel, style: AppTextStyles.caption),
                Text('Rese', style: AppTextStyles.appTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pasiente: ${pasien.namaLengkap}  |  '
                  'MRN: ${pasien.medicalRecordNumber ?? '-'}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusIndicator(status: prescription.syncStatus),
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
                if (prescription.items.isEmpty)
                  const Text(
                      'Rese nee laiha item aimoruk.', style: AppTextStyles.body)
                else
                  for (final item in prescription.items) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.medicationName?.isNotEmpty == true
                                ? item.medicationName!
                                : 'Aimoruk',
                            style: AppTextStyles.body,
                          ),
                          if (item.medicationStrength?.isNotEmpty == true)
                            Text(item.medicationStrength!,
                                style: AppTextStyles.caption),
                          Text('Doze: ${item.dose}', style: AppTextStyles.caption),
                          Text('Frekuensia: ${item.frequency}',
                              style: AppTextStyles.caption),
                          if (item.duration?.isNotEmpty == true)
                            Text('Durasaun: ${item.duration}',
                                style: AppTextStyles.caption),
                          Text('Kuantidade: ${item.quantity}',
                              style: AppTextStyles.caption),
                          if (item.route?.isNotEmpty == true)
                            Text('Dalai: ${item.route}',
                                style: AppTextStyles.caption),
                          if (item.instructions?.isNotEmpty == true)
                            Text('Intrusaun: ${item.instructions}',
                                style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                if (prescription.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Notas: ${prescription.notes}',
                      style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
