import 'package:equatable/equatable.dart';

import '../../data/local/prescription_schema.dart';

sealed class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads every prescription of one patient (through the visit relationship).
final class LoadPatientPrescriptions extends PrescriptionEvent {
  const LoadPatientPrescriptions(this.patientId);

  final String patientId;

  @override
  List<Object?> get props => [patientId];
}

/// Creates one prescription inside a clinical visit context. The repository
/// writes the record and its queue entry atomically; sync follows separately.
final class CreatePrescription extends PrescriptionEvent {
  const CreatePrescription(this.prescription);

  final Prescription prescription;

  @override
  List<Object?> get props => [prescription.remoteId];
}
