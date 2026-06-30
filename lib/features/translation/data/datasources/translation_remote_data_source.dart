import 'package:dio/dio.dart';

import '../../../../../core/config/api_config.dart';
import '../../../../../core/models/translation_result.dart';

class TranslationRemoteDataSource {
  TranslationRemoteDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            ),
          );

  final Dio _dio;

  Future<TranslationResult> translateText({
    required String text,
    required String direction,
  }) async {
    final response = await _dio.post(
      '/translate',
      data: <String, dynamic>{'text': text, 'direction': direction},
    );
    return TranslationResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<TranslationResult> translateAudio({
    required String audioBase64,
    required String direction,
  }) async {
    final response = await _dio.post(
      '/pipeline',
      data: <String, dynamic>{'audio_b64': audioBase64, 'direction': direction},
    );
    return TranslationResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<String> transcribeAudio({
    required String audioBase64,
    required String direction,
    required String userType,
  }) async {
    final response = await _dio.post(
      '/asr',
      data: <String, dynamic>{
        'audio_b64': audioBase64,
        'direction': direction,
        'user_type': userType,
      },
      options: Options(
        sendTimeout: ApiConfig.asrReceiveTimeout,
        receiveTimeout: ApiConfig.asrReceiveTimeout,
      ),
    );
    final payload = Map<String, dynamic>.from(response.data as Map);
    return payload['text'] as String? ?? '';
  }

  Future<bool> healthCheck() async {
    final response = await _dio.get('/health');
    return response.statusCode == 200;
  }
}
