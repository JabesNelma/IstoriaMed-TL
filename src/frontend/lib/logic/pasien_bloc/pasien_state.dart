import 'package:equatable/equatable.dart';

import '../../data/local/pasien_schema.dart';

sealed class PasienState extends Equatable {
  const PasienState();

  @override
  List<Object?> get props => const [];
}

final class PasienInitial extends PasienState {
  const PasienInitial();
}

final class PasienLoading extends PasienState {
  const PasienLoading();
}

final class PasienSuccess extends PasienState {
  const PasienSuccess(this.pasien);

  final Pasien pasien;

  @override
  List<Object?> get props => [pasien.id, pasien.localStatus];
}

final class PasienError extends PasienState {
  const PasienError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
