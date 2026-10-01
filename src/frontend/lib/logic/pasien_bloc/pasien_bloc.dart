import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/pasien_repository.dart';
import 'pasien_event.dart';
import 'pasien_state.dart';

class PasienBloc extends Bloc<PasienEvent, PasienState> {
  PasienBloc(this.repository) : super(const PasienInitial()) {
    on<RegisterPasien>(_register);
    on<SyncPendingPasien>(_sync);
  }

  PasienBloc.testing()
      : repository = null,
        super(const PasienInitial()) {
    on<RegisterPasien>((event, emit) {});
    on<SyncPendingPasien>((event, emit) {});
  }

  final PasienRepository? repository;

  Future<void> _register(
    RegisterPasien event,
    Emitter<PasienState> emit,
  ) async {
    emit(const PasienLoading());
    try {
      final activeRepository = repository;
      if (activeRepository == null) return;
      emit(PasienSuccess(await activeRepository.register(event.pasien)));
    } catch (_) {
      emit(const PasienError('Rejistu lokal la konsege. Favor koko tanba fali.'));
    }
  }

  Future<void> _sync(
    SyncPendingPasien event,
    Emitter<PasienState> emit,
  ) async {
    try {
      await repository?.syncPending();
    } catch (_) {
      emit(const PasienError('Sinkronizasaun seidauk konsege. Dados hela lokal.'));
    }
  }
}
