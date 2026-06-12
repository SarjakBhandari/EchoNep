import '../repositories/translation_repository.dart';

class HealthCheckUseCase {
  HealthCheckUseCase(this._repository);

  final TranslationRepository _repository;

  Future<bool> call() {
    return _repository.healthCheck();
  }
}
