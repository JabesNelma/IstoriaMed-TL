import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sync/sync_service.dart';
import '../../repositories/prescription_repository.dart';
import 'prescription_event.dart';
import 'prescription_state.dart';

class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  PrescriptionBloc(this.repository, this.syncService)
      : super(const PrescriptionInitial()) {
    on<LoadPatientPrescriptions>(_loadForPatient);
    on<CreatePrescription>(_create);
  }

  final PrescriptionRepository repository;
  final SyncService syncService;

  Future<void> _loadForPatient(
    LoadPatientPrescriptions event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(const PrescriptionLoading());
    try {
      emit(PrescriptionListLoaded(await repository.forPatient(event.patientId)));
    } catch (_) {
      emit(const PrescriptionError('Dadus rese la konsege maka.'));
    }
  }

  Future<void> _create(
    CreatePrescription event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(const PrescriptionLoading());
    try {
      final saved = await repository.create(event.prescription);
      emit(PrescriptionSaved(saved));
      // One synchronization pathway: the local write is always completed by
      // the queue, never by a separate direct API call.
      await syncService.syncPending();
    } catch (_) {
      emit(const PrescriptionError('Rese la konsege rai lokal.'));
    }
  }
}
