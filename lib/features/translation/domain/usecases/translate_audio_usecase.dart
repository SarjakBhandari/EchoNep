import '../repositories/translation_repository.dart';
import '../../../../core/models/translation_result.dart';

class TranslateAudioUseCase {
  TranslateAudioUseCase(this._repository);

  final TranslationRepository _repository;

  Future<TranslationResult> call({
    required String audioBase64,
    required String direction,
  }) {
    return _repository.translateAudio(
      audioBase64: audioBase64,
      direction: direction,
    );
  }
}
