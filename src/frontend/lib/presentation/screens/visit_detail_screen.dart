import 'package:flutter/material.dart';

import '../../data/local/istoria_schema.dart';
import '../../data/local/pasien_schema.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_indicator.dart';

/// Read-only clinical visit detail: SOAP + ICD-10 for one visit of one
/// patient. Data comes straight from the record the caller already holds
/// (local store), so it renders even fully offline.
class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({
    super.key,
    required this.record,
    required this.pasien,
  });

  final IstoriaKlinis record;
  final Pasien pasien;

  String get _date {
    final date = record.tanggalKunjungan;
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhu Kunjungan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_date, style: AppTextStyles.caption),
                Text(
                  record.namaPenyakitLokal.isEmpty
                      ? 'Konsultasaun'
                      : record.namaPenyakitLokal,
                  style: AppTextStyles.appTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                    'Pasiente: ${pasien.namaLengkap}  |  '
                    'MRN: ${pasien.medicalRecordNumber ?? '-'}',
                    style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                StatusIndicator(status: record.syncStatus),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _soapSection('Subjective', record.keluhanSubjektif),
          _soapSection('Objective', record.pemeriksaanObjektif),
          _soapSection('Assessment', record.analisisAsesmen),
          _soapSection('Plan', record.rencanaTindakan),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diagnoze', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Text('ICD-10: ${record.kodeIcd10}', style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _soapSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              body.isEmpty ? '—' : body,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
