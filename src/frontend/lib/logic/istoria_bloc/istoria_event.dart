import 'package:equatable/equatable.dart';

import '../../data/local/istoria_schema.dart';

sealed class IstoriaEvent extends Equatable {
  const IstoriaEvent();

  @override
  List<Object?> get props => const [];
}

final class CreateIstoria extends IstoriaEvent {
  const CreateIstoria(this.istoria);

  final IstoriaKlinis istoria;

  @override
  List<Object?> get props => [istoria.id, istoria.pasienId];
}

final class FetchPasienHistory extends IstoriaEvent {
  const FetchPasienHistory(this.pasienId);

  final String pasienId;

  @override
  List<Object?> get props => [pasienId];
}

final class SyncPendingIstoria extends IstoriaEvent {
  const SyncPendingIstoria();
}
