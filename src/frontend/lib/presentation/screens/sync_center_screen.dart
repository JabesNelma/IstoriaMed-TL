import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_types.dart';
import '../../data/local/sync_operation_schema.dart';
import '../../logic/sync_bloc/sync_bloc.dart';
import '../../logic/sync_bloc/sync_event.dart';
import '../../logic/sync_bloc/sync_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

/// Sync Center: reads the existing persistent queue and calls the existing
/// SyncService. There is no connectivity detection in the app yet, so the
/// status line only reports what the queue itself can truthfully tell.
class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(const LoadSyncStatus());
  }

  Future<void> _manualSync() async {
    context.read<SyncBloc>().add(const ManualSyncRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state is SyncFailureMessage) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is SyncRunning) {
          return const Center(child: CircularProgressIndicator());
        }
        final loaded = state is SyncStatusLoaded ? state : null;
        if (state is SyncStatusUnavailable) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Text(state.message, style: AppTextStyles.error),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<SyncBloc>().add(const LoadSyncStatus()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _statusCard(loaded),
              const SizedBox(height: AppSpacing.md),
              if (loaded?.lastReport != null) ...[
                _reportCard(loaded!.lastReport!),
                const SizedBox(height: AppSpacing.md),
              ],
              AppButton(
                label: 'Sinkroniza Agora',
                icon: Icons.sync,
                onPressed: _manualSync,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Hein Sinkronizasaun', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              if (loaded == null ||
                  (loaded.pending.isEmpty && loaded.failed.isEmpty))
                const AppCard(
                  child: Text(
                    'La iha operasaun hein. Dadus lokal hotu hela sinkroniza tiha ona.',
                    style: AppTextStyles.caption,
                  ),
                )
              else ...[
                for (final operation in loaded.pending)
                  _OperationCard(
                    operation: operation,
                    onRetry: operation.status == SyncStatus.failed
                        ? () => context.read<SyncBloc>().add(
                            RetryFailedOperationRequested(operation.operationId))
                        : null,
                  ),
                for (final operation in loaded.failed)
                  _OperationCard(
                    operation: operation,
                    onRetry: () => context.read<SyncBloc>().add(
                        RetryFailedOperationRequested(operation.operationId)),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  /// Status is derived only from queue state the app genuinely knows. No
  /// Online/Offline claim: connectivity detection is not implemented yet.
  Widget _statusCard(SyncStatusLoaded? loaded) {
    final waiting = loaded?.waitingCount ?? 0;
    final failed = loaded?.failed.length ?? 0;
    String label;
    Color color;
    if (failed > 0) {
      label = 'Iha problema sinkronizasaun';
      color = Colors.red.shade800;
    } else if (waiting > 0) {
      label = 'Dadus hein sinkronizasaun';
      color = Colors.orange.shade900;
    } else {
      label = 'Dadus hotu sinkroniza tiha ona';
      color = Colors.green.shade800;
    }
    final lastSyncedAt = loaded?.lastSyncedAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: AppTextStyles.caption),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(label, style: AppTextStyles.body)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Dadus hein: $waiting', style: AppTextStyles.body),
          if (lastSyncedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ikus sinkroniza: '
              '${lastSyncedAt.day.toString().padLeft(2, '0')}/'
              '${lastSyncedAt.month.toString().padLeft(2, '0')}/'
              '${lastSyncedAt.year} '
              '${lastSyncedAt.hour.toString().padLeft(2, '0')}:'
              '${lastSyncedAt.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _reportCard(SyncRunReport report) {
    return AppCard(
      child: Text(
        'Sinkronizasaun remata: ${report.synced} susesu, '
        '${report.failed} falha, ${report.pending} sei hela.',
        style: AppTextStyles.caption,
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.operation, this.onRetry});

  final SyncOperation operation;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = operation.status == SyncStatus.failed;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _entityLabel(operation.entityType),
                    style: AppTextStyles.body,
                  ),
                ),
                _statusChip(operation.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(_createdAtLabel(), style: AppTextStyles.caption),
            if (failed && operation.lastError?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Alasan: ${operation.lastError}',
                  style: AppTextStyles.caption),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Koko Fali',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final isFailed = status == SyncStatus.failed;
    final isSyncing = status == SyncStatus.syncing;
    return Chip(
      label: Text(
        isFailed
            ? 'FALHA'
            : isSyncing
                ? 'SINKRONIZA...'
                : 'HEIN',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: isFailed
          ? Colors.red.shade50
          : isSyncing
              ? Colors.blue.shade50
              : Colors.orange.shade50,
      visualDensity: VisualDensity.compact,
    );
  }

  String _entityLabel(String entityType) => switch (entityType) {
        SyncEntityType.patient => 'Pasiente',
        SyncEntityType.clinicalVisit => 'Kunjungan Klinis',
        SyncEntityType.prescription => 'Rese',
        _ => entityType,
      };

  String _createdAtLabel() {
    final date = operation.createdAt;
    return 'Kria: '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
