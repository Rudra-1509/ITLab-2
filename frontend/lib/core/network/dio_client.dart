import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageProvider);
  final baseUrl = storage.getBaseUrl();

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Ensure options use latest baseUrl from storage
        if (!options.path.startsWith('http')) {
          options.baseUrl = storage.getBaseUrl();
        }
        final token = storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        String errorMessage = 'An unexpected error occurred';
        if (e.response != null && e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map<String, dynamic>) {
            errorMessage = data['error'] ??
                data['message'] ??
                data['msg'] ??
                e.response?.statusMessage ??
                'Error ${e.response?.statusCode}';
          } else if (data is String && data.isNotEmpty) {
            errorMessage = data;
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timed out. Please check server connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Could not connect to backend at ${storage.getBaseUrl()}. Is the server running?';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMessage = e.message!;
        }

        final customException = DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: errorMessage,
          message: errorMessage,
        );
        return handler.next(customException);
      },
    ),
  );

  return dio;
});
