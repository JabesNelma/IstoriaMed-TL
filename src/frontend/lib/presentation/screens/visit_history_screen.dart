import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/istoria_schema.dart';
import '../../data/local/pasien_schema.dart';
import '../../logic/istoria_bloc/istoria_bloc.dart';
import '../../logic/istoria_bloc/istoria_event.dart';
import '../../logic/istoria_bloc/istoria_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_indicator.dart';
import 'visit_detail_screen.dart';

/// Full visit history of one patient. Reads through the existing
/// IstoriaBloc/IstoriaRepository (online read-through with local fallback).
class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key, required this.pasien});

  final Pasien pasien;

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  late final String _patientKey;

  @override
  void initState() {
    super.initState();
    _patientKey = widget.pasien.remoteId ?? widget.pasien.id.toString();
    context.read<IstoriaBloc>().add(FetchPasienHistory(_patientKey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Kunjungan')),
      body: BlocConsumer<IstoriaBloc, IstoriaState>(
        listener: (context, state) {
          if (state is IstoriaError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is IstoriaLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.sm),
                  Text('Maka riwayat...'),
                ],
              ),
            );
          }
          if (state is IstoriaError) {
            return const Center(
              child: Text(
                'Riwayat kunjungan la konsege maka.',
                style: AppTextStyles.error,
              ),
            );
          }
          final records = state is IstoriaHistoryLoaded
              ? state.records
              : const <IstoriaKlinis>[];
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'Seidauk iha riwayat kunjungan.',
                style: AppTextStyles.body,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context
                .read<IstoriaBloc>()
                .add(FetchPasienHistory(_patientKey)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _VisitCard(
                record: records[index],
                pasien: widget.pasien,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.record, required this.pasien});

  final IstoriaKlinis record;
  final Pasien pasien;

  String get _date {
    final date = record.tanggalKunjungan;
    if (date == null) return 'Data la iha';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              VisitDetailScreen(record: record, pasien: pasien),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_date, style: AppTextStyles.caption),
                Text(
                  record.namaPenyakitLokal.isEmpty
                      ? 'Konsultasaun'
                      : record.namaPenyakitLokal,
                  style: AppTextStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('ICD-10: ${record.kodeIcd10}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusIndicator(status: record.syncStatus),
        ],
      ),
    );
  }
}
