import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/translation_result.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static Future<TranslationResult> translateText({
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

  static Future<TranslationResult> translateAudio({
    required File file,
    required String direction,
  }) async {
    final audioBytes = await file.readAsBytes();
    final response = await _dio.post(
      '/pipeline',
      data: <String, dynamic>{
        'audio_b64': base64Encode(audioBytes),
        'direction': direction,
      },
    );
    return TranslationResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
