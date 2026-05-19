import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.authLogin, data: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required double monthlyIncome,
    String? phone,
  }) async {
    try {
      final res = await _dio.post(ApiEndpoints.authRegister, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'monthly_income': monthlyIncome,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final res = await _dio.get(ApiEndpoints.authMe);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(friendlyError(e));
    }
  }

  Future<void> logout() async {
    try {
      await _dio.delete(ApiEndpoints.authLogout);
    } on DioException catch (e) {
      throw Exception(friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch(ApiEndpoints.authPatchMe(), data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(friendlyError(e));
    }
  }
}
