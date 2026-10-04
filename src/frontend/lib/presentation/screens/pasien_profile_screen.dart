import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/istoria_schema.dart';
import '../../data/local/pasien_schema.dart';
import '../../logic/istoria_bloc/istoria_bloc.dart';
import '../../logic/istoria_bloc/istoria_event.dart';
import '../../logic/istoria_bloc/istoria_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/status_indicator.dart';
import 'istoria_klinis_screen.dart';
import 'visit_detail_screen.dart';
import 'visit_history_screen.dart';

/// Patient profile: the navigation hub for this patient's clinical data.
/// Everything shown comes from the local store; no backend round trip is
/// required to open it.
class PasienProfileScreen extends StatefulWidget {
  const PasienProfileScreen({super.key, required this.pasien});

  final Pasien pasien;

  @override
  State<PasienProfileScreen> createState() => _PasienProfileScreenState();
}

class _PasienProfileScreenState extends State<PasienProfileScreen> {
  late String _patientKey;

  @override
  void initState() {
    super.initState();
    // Visits are linked to the patient's device-reserved identifier (the same
    // key the sync queue and the backend use).
    _patientKey = widget.pasien.remoteId ?? widget.pasien.id.toString();
    context.read<IstoriaBloc>().add(FetchPasienHistory(_patientKey));
  }

  void _reload() =>
      context.read<IstoriaBloc>().add(FetchPasienHistory(_patientKey));

  Future<void> _newVisit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IstoriaKlinisScreen(pasien: widget.pasien),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisitHistoryScreen(pasien: widget.pasien),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final pasien = widget.pasien;
    final birthDate = '${pasien.tanggalLahir.day.toString().padLeft(2, '0')}/'
        '${pasien.tanggalLahir.month.toString().padLeft(2, '0')}/'
        '${pasien.tanggalLahir.year}';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pasien')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    pasien.namaLengkap.isNotEmpty
                        ? pasien.namaLengkap[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pasien.namaLengkap,
                        style: AppTextStyles.appTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('MRN: ${pasien.medicalRecordNumber ?? '-'}',
                          style: AppTextStyles.caption),
                      StatusIndicator(status: pasien.localStatus),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informasaun Pasiente', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                _infoRow('Data moris', birthDate),
                _infoRow('Jéneru', pasien.jenisKelamin),
                _infoRow('Fatin moris',
                    pasien.tempatLahir.isEmpty ? '—' : pasien.tempatLahir),
                _infoRow('Numeru KTP', pasien.noKtp ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _VisitSection(
            patientKey: _patientKey,
            onOpenHistory: _openHistory,
            onOpenVisit: (record) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VisitDetailScreen(
                  record: record,
                  pasien: pasien,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resep / Aimoruk', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Seidauk iha data rese. (Fase tuak mai.)',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Kunjungan Foun',
            icon: Icons.add,
            onPressed: _newVisit,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitSection extends StatelessWidget {
  const _VisitSection({
    required this.patientKey,
    required this.onOpenHistory,
    required this.onOpenVisit,
  });

  final String patientKey;
  final VoidCallback onOpenHistory;
  final void Function(IstoriaKlinis) onOpenVisit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Riwayat Kunjungan', style: AppTextStyles.sectionTitle),
              TextButton(onPressed: onOpenHistory, child: const Text('Haree hotu')),
            ],
          ),
          BlocBuilder<IstoriaBloc, IstoriaState>(
            buildWhen: (previous, current) =>
                current is IstoriaHistoryLoaded ||
                current is IstoriaLoading ||
                current is IstoriaError,
            builder: (context, state) {
              if (state is IstoriaLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is IstoriaError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Istoria kunjungan la konsege maka.',
                      style: AppTextStyles.error),
                );
              }
              final records = state is IstoriaHistoryLoaded
                  ? state.records
                  : const <IstoriaKlinis>[];
              if (records.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Seidauk iha riwayat kunjungan.',
                      style: AppTextStyles.caption),
                );
              }
              final preview = records.take(3).toList();
              return Column(
                children: [
                  for (final record in preview)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_note,
                          color: AppColors.primary),
                      title: Text(
                        record.namaPenyakitLokal.isEmpty
                            ? 'Konsultasaun'
                            : record.namaPenyakitLokal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_visitDate(record)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.muted),
                      onTap: () => onOpenVisit(record),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _visitDate(IstoriaKlinis record) {
    final date = record.tanggalKunjungan;
    if (date == null) return 'Data la iha';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
