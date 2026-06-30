import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/translation_result.dart';
import '../utils/api_error.dart';
import '../../features/translation/data/datasources/translation_remote_data_source.dart';
import '../../features/translation/data/repositories/translation_repository_impl.dart';
import '../../features/translation/domain/usecases/health_check_usecase.dart';
import '../../features/translation/domain/usecases/translate_audio_usecase.dart';
import '../../features/translation/domain/usecases/translate_text_usecase.dart';
import '../../features/translation/domain/usecases/transcribe_audio_usecase.dart';

final translationRemoteDataSourceProvider =
    Provider<TranslationRemoteDataSource>((ref) {
      return TranslationRemoteDataSource();
    });

final translationRepositoryProvider = Provider<TranslationRepositoryImpl>((
  ref,
) {
  return TranslationRepositoryImpl(
    ref.read(translationRemoteDataSourceProvider),
  );
});

final translateTextUseCaseProvider = Provider<TranslateTextUseCase>((ref) {
  return TranslateTextUseCase(ref.read(translationRepositoryProvider));
});

final translateAudioUseCaseProvider = Provider<TranslateAudioUseCase>((ref) {
  return TranslateAudioUseCase(ref.read(translationRepositoryProvider));
});

final transcribeAudioUseCaseProvider = Provider<TranscribeAudioUseCase>((ref) {
  return TranscribeAudioUseCase(ref.read(translationRepositoryProvider));
});

final healthCheckUseCaseProvider = Provider<HealthCheckUseCase>((ref) {
  return HealthCheckUseCase(ref.read(translationRepositoryProvider));
});

class TranslationState {
  final bool isLoading;
  final String? error;
  final String sourceText;
  final TranslationResult? result;

  const TranslationState({
    this.isLoading = false,
    this.error,
    this.sourceText = '',
    this.result,
  });

  TranslationState copyWith({
    bool? isLoading,
    String? error,
    String? sourceText,
    TranslationResult? result,
  }) {
    return TranslationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sourceText: sourceText ?? this.sourceText,
      result: result ?? this.result,
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  TranslationNotifier({
    required TranslateTextUseCase translateTextUseCase,
    required TranslateAudioUseCase translateAudioUseCase,
    required HealthCheckUseCase healthCheckUseCase,
  }) : _translateTextUseCase = translateTextUseCase,
       _translateAudioUseCase = translateAudioUseCase,
       _healthCheckUseCase = healthCheckUseCase,
       super(const TranslationState());

  final TranslateTextUseCase _translateTextUseCase;
  final TranslateAudioUseCase _translateAudioUseCase;
  final HealthCheckUseCase _healthCheckUseCase;

  void setLoading({String sourceText = ''}) {
    state = state.copyWith(isLoading: true, sourceText: sourceText);
  }

  void setError(String message) {
    state = state.copyWith(isLoading: false, error: message);
  }

  void setResult(TranslationResult result) {
    state = state.copyWith(
      isLoading: false,
      result: result,
      sourceText: result.sourceText,
    );
  }

  void clear() {
    state = const TranslationState();
  }

  Future<void> translateText({
    required String text,
    required String direction,
  }) async {
    setLoading(sourceText: text);
    try {
      final result = await _translateTextUseCase(
        text: text,
        direction: direction,
      );
      setResult(result);
    } on DioException catch (error) {
      setError(describeDioError(error));
    } catch (error) {
      setError(error.toString());
    }
  }

  Future<void> translateAudio({
    required String audioBase64,
    required String direction,
  }) async {
    setLoading();
    try {
      final result = await _translateAudioUseCase(
        audioBase64: audioBase64,
        direction: direction,
      );
      setResult(result);
    } on DioException catch (error) {
      setError(describeDioError(error));
    } catch (error) {
      setError(error.toString());
    }
  }

  Future<bool> healthCheck() {
    return _healthCheckUseCase();
  }
}

final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
      return TranslationNotifier(
        translateTextUseCase: ref.read(translateTextUseCaseProvider),
        translateAudioUseCase: ref.read(translateAudioUseCaseProvider),
        healthCheckUseCase: ref.read(healthCheckUseCaseProvider),
      );
    });
