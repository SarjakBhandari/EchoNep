import '../../../../core/models/translation_result.dart';

abstract class TranslationRepository {
  Future<TranslationResult> translateText({
    required String text,
    required String direction,
  });

  Future<TranslationResult> translateAudio({
    required String audioBase64,
    required String direction,
  });

  Future<String> transcribeAudio({
    required String audioBase64,
    required String direction,
    required String userType,
  });

  Future<bool> healthCheck();
}
