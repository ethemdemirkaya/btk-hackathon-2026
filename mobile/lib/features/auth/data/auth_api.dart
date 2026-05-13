import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final res = await _dio.post(ApiEndpoints.authLogin, data: {
      'email': email,
      'password': password,
      'device_name': deviceName,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required double monthlyIncome,
    String? phone,
  }) async {
    final res = await _dio.post(ApiEndpoints.authRegister, data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'monthly_income': monthlyIncome,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get(ApiEndpoints.authMe);
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.delete(ApiEndpoints.authLogout);
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final res = await _dio.patch(ApiEndpoints.authPatchMe(), data: data);
    return res.data as Map<String, dynamic>;
  }
}
