import 'package:dio/dio.dart';

String describeDioError(DioException error) {
  final responseData = error.response?.data;
  if (responseData is Map && responseData['detail'] is String) {
    return responseData['detail'] as String;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Request timed out. Please check your connection and try again.';
    case DioExceptionType.connectionError:
      return 'Could not reach the server. Make sure the backend is running and you are on the same network.';
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      return statusCode == null
          ? 'Server error. Please try again.'
          : 'Server error (status code $statusCode).';
    case DioExceptionType.cancel:
      return 'Request was cancelled.';
    default:
      return error.message ?? 'Unknown network error.';
  }
}
