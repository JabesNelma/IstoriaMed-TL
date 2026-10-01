import 'package:equatable/equatable.dart';

import '../../data/local/pasien_schema.dart';

sealed class PasienEvent extends Equatable {
  const PasienEvent();

  @override
  List<Object?> get props => const [];
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
