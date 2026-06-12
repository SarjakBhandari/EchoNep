import '../repositories/translation_repository.dart';
import '../../../../core/models/translation_result.dart';

class TranslateTextUseCase {
  TranslateTextUseCase(this._repository);

  final TranslationRepository _repository;

  Future<TranslationResult> call({
    required String text,
    required String direction,
  }) {
    return _repository.translateText(text: text, direction: direction);
  }
}
