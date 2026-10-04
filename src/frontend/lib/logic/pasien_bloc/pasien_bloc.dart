import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sync/sync_service.dart';
import '../../repositories/pasien_repository.dart';
import 'pasien_event.dart';
import 'pasien_state.dart';

class PasienBloc extends Bloc<PasienEvent, PasienState> {
  PasienBloc(this.repository, this.syncService) : super(const PasienInitial()) {
    on<RegisterPasien>(_register);
    on<LoadPasienList>(_loadList);
    on<SyncPendingPasien>(_sync);
  }

  PasienBloc.testing()
      : repository = null,
        syncService = null,
        super(const PasienInitial()) {
    on<RegisterPasien>((event, emit) {});
    on<LoadPasienList>((event, emit) {});
    on<SyncPendingPasien>((event, emit) {});
  }

  final PasienRepository? repository;
  final SyncService? syncService;

  Future<void> _loadList(
    LoadPasienList event,
    Emitter<PasienState> emit,
  ) async {
    final activeRepository = repository;
    if (activeRepository == null) return;
    try {
      emit(PasienListLoaded(
        await activeRepository.findAll(query: event.query),
        query: event.query,
      ));
    } catch (_) {
      emit(const PasienError('Dadus pasiente la konsege maka.'));
    }
  }

  Future<void> _register(
    RegisterPasien event,
    Emitter<PasienState> emit,
  ) async {
    emit(const PasienLoading());
    final activeRepository = repository;
    if (activeRepository == null) return;
    try {
      emit(PasienSuccess(await activeRepository.register(event.pasien)));
      // One synchronization pathway: the local write is always completed by the
      // queue, never by a separate direct API call.
      await syncService?.syncPending();
    } on DuplicatePasienException {
      emit(const PasienError(
          'Pasiente ho Numeru KTP neba rejistradu tiha ona lokal.'));
    } catch (_) {
      emit(const PasienError('Rejistu lokal la konsege. Favor koko tanba fali.'));
    }
  }

  Future<void> _sync(
    SyncPendingPasien event,
    Emitter<PasienState> emit,
  ) async {
    final activeSyncService = syncService;
    if (activeSyncService == null) return;
    try {
      await activeSyncService.syncPending();
    } catch (_) {
      emit(const PasienError('Sinkronizasaun seidauk konsege. Dados hela lokal.'));
    }
  }
}
