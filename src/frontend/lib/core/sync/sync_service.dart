import '../../repositories/istoria_repository.dart';
import '../../repositories/pasien_repository.dart';

class SyncService {
  SyncService({required this.pasienRepository, required this.istoriaRepository});

  final PasienRepository pasienRepository;
  final IstoriaRepository istoriaRepository;

  Future<void> synchronize() async {
    await pasienRepository.syncPending();
    await istoriaRepository.syncPending();
  }
}
