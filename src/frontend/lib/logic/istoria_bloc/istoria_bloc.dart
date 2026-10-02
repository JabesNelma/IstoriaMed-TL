import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sync/sync_service.dart';
import '../../repositories/istoria_repository.dart';
import 'istoria_event.dart';
import 'istoria_state.dart';

class IstoriaBloc extends Bloc<IstoriaEvent, IstoriaState> {
  IstoriaBloc(this.repository, this.syncService) : super(const IstoriaInitial()) {
    on<CreateIstoria>(_create);
    on<FetchPasienHistory>(_fetchHistory);
    on<SyncPendingIstoria>(_sync);
  }

  IstoriaBloc.testing()
      : repository = null,
        syncService = null,
        super(const IstoriaInitial()) {
    on<CreateIstoria>((event, emit) {});
    on<FetchPasienHistory>((event, emit) {});
    on<SyncPendingIstoria>((event, emit) {});
  }

  final IstoriaRepository? repository;
  final SyncService? syncService;

  Future<void> _create(
    CreateIstoria event,
    Emitter<IstoriaState> emit,
  ) async {
    emit(const IstoriaLoading());
    final activeRepository = repository;
    if (activeRepository == null) return;
    try {
      emit(IstoriaSuccess(await activeRepository.create(event.istoria)));
      await syncService?.syncPending();
    } catch (_) {
      emit(const IstoriaError('Istoria klinis la bele rejistu lokal.'));
    }
  }

  Future<void> _fetchHistory(
    FetchPasienHistory event,
    Emitter<IstoriaState> emit,
  ) async {
    emit(const IstoriaLoading());
    final activeRepository = repository;
    if (activeRepository == null) return;
    try {
      emit(IstoriaHistoryLoaded(await activeRepository.history(event.pasienId)));
    } catch (_) {
      emit(const IstoriaError('Istoria pasiente la bele lee.'));
    }
  }

  Future<void> _sync(
    SyncPendingIstoria event,
    Emitter<IstoriaState> emit,
  ) async {
    final activeSyncService = syncService;
    if (activeSyncService == null) return;
    try {
      await activeSyncService.syncPending();
    } catch (_) {
      emit(const IstoriaError('Sinkronizasaun istoria klinis la konsege.'));
    }
  }
}
