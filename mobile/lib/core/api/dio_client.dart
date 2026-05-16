import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'interceptors.dart';

class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }

  static void reset() => _instance = null;
}

/// Parses 422 validation errors from API response.
Map<String, String> parseValidationErrors(DioException e) {
  final data = e.response?.data;
  if (data is Map && data.containsKey('errors')) {
    final errors = data['errors'] as Map;
    return errors.map((k, v) {
      final msgs = v is List ? v.join(', ') : v.toString();
      return MapEntry(k.toString(), msgs);
    });
  }
  return {};
}

/// Returns a user-friendly error message for an API exception.
String friendlyError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 401) return 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.';
    if (status == 403) return 'Bu işlem için yetkiniz yok.';
    if (status == 404) return 'Kayıt bulunamadı.';
    if (status == 422) return 'Girilen bilgileri kontrol edin.';
    if (status != null && status >= 500) return 'Sunucu hatası. Lütfen tekrar deneyin.';
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Bağlantı zaman aşımına uğradı (${ApiEndpoints.currentHost}:8000).';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Sunucuya bağlanılamadı (${ApiEndpoints.currentHost}:8000).';
      default:
        break;
    }
  }
  return 'Bir hata oluştu. Lütfen tekrar deneyin.';
}
