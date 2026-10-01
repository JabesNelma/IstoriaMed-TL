import 'package:equatable/equatable.dart';

import '../../data/local/istoria_schema.dart';

sealed class IstoriaState extends Equatable {
  const IstoriaState();

  @override
  List<Object?> get props => const [];
}

final class IstoriaInitial extends IstoriaState {
  const IstoriaInitial();
}

final class IstoriaLoading extends IstoriaState {
  const IstoriaLoading();
}

final class IstoriaSuccess extends IstoriaState {
  const IstoriaSuccess(this.record);

  final IstoriaKlinis record;

  @override
  List<Object?> get props => [record.id, record.syncStatus];
}

final class IstoriaHistoryLoaded extends IstoriaState {
  const IstoriaHistoryLoaded(this.records);

  final List<IstoriaKlinis> records;

  @override
  List<Object?> get props => [records];
}

final class IstoriaError extends IstoriaState {
  const IstoriaError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
