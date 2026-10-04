import 'package:equatable/equatable.dart';

import '../../data/local/prescription_schema.dart';

sealed class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => const [];
}

final class PrescriptionInitial extends PrescriptionState {
  const PrescriptionInitial();
}

final class PrescriptionLoading extends PrescriptionState {
  const PrescriptionLoading();
}

final class PrescriptionListLoaded extends PrescriptionState {
  const PrescriptionListLoaded(this.prescriptions);

  final List<Prescription> prescriptions;

  @override
  List<Object?> get props => [prescriptions];
}

final class PrescriptionSaved extends PrescriptionState {
  const PrescriptionSaved(this.prescription);

  final Prescription prescription;

  @override
  List<Object?> get props => [prescription.id, prescription.syncStatus];
}

final class PrescriptionError extends PrescriptionState {
  const PrescriptionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
