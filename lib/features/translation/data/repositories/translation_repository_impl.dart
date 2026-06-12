import '../../domain/repositories/translation_repository.dart';
import '../datasources/translation_remote_data_source.dart';
import '../../../../core/models/translation_result.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  TranslationRepositoryImpl(this._remoteDataSource);

  final TranslationRemoteDataSource _remoteDataSource;

  @override
  Future<TranslationResult> translateAudio({
    required String audioBase64,
    required String direction,
  }) {
    return _remoteDataSource.translateAudio(
      audioBase64: audioBase64,
      direction: direction,
    );
  }

  @override
  Future<String> transcribeAudio({
    required String audioBase64,
    required String direction,
    required String userType,
  }) {
    return _remoteDataSource.transcribeAudio(
      audioBase64: audioBase64,
      direction: direction,
      userType: userType,
    );
  }

  @override
  Future<TranslationResult> translateText({
    required String text,
    required String direction,
  }) {
    return _remoteDataSource.translateText(text: text, direction: direction);
  }

  @override
  Future<bool> healthCheck() {
    return _remoteDataSource.healthCheck();
  }
}
