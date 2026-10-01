import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/istoria_repository.dart';
import 'istoria_event.dart';
import 'istoria_state.dart';

class IstoriaBloc extends Bloc<IstoriaEvent, IstoriaState> {
  IstoriaBloc(this.repository) : super(const IstoriaInitial()) {
    on<CreateIstoria>(_create);
    on<FetchPasienHistory>(_fetchHistory);
  }

  final IstoriaRepository repository;

  Future<void> _create(
    CreateIstoria event,
    Emitter<IstoriaState> emit,
  ) async {
    emit(const IstoriaLoading());
    try {
      emit(IstoriaSuccess(await repository.create(event.istoria)));
    } catch (_) {
      emit(const IstoriaError('Istoria klinis la bele rejistu lokal.'));
    }
  }

  Future<void> _fetchHistory(
    FetchPasienHistory event,
    Emitter<IstoriaState> emit,
  ) async {
    emit(const IstoriaLoading());
    try {
      emit(IstoriaHistoryLoaded(await repository.history(event.pasienId)));
    } catch (_) {
      emit(const IstoriaError('Istoria pasiente la bele lee.'));
    }
  }
}
