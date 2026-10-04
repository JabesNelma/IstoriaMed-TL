import 'package:equatable/equatable.dart';

import '../../data/local/pasien_schema.dart';

sealed class PasienEvent extends Equatable {
  const PasienEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the local patient catalogue, optionally filtered by a case
/// insensitive name/MRN/KTP search. Local data only — no remote call.
final class LoadPasienList extends PasienEvent {
  const LoadPasienList([this.query = '']);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class RegisterPasien extends PasienEvent {
  const RegisterPasien(this.pasien);

  final Pasien pasien;

  @override
  List<Object?> get props => [pasien.id, pasien.noKtp];
}

final class SyncPendingPasien extends PasienEvent {
  const SyncPendingPasien();
}
