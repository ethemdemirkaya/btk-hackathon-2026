import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';

class DashboardApi {
  final Dio _dio;
  DashboardApi(this._dio);

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get(ApiEndpoints.dashboard);
    return res.data as Map<String, dynamic>;
  }
}
