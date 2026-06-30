import '../repositories/translation_repository.dart';

class TranscribeAudioUseCase {
  TranscribeAudioUseCase(this._repository);

  final TranslationRepository _repository;

  Future<String> call({
    required String audioBase64,
    required String direction,
    required String userType,
  }) {
    return _repository.transcribeAudio(
      audioBase64: audioBase64,
      direction: direction,
      userType: userType,
    );
  }
}
