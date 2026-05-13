import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_api.dart';

class AuthRepository {
  final AuthApi _api;
  AuthRepository(Dio dio) : _api = AuthApi(dio);

  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final data = await _api.login(
        email: email, password: password, deviceName: deviceName);
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await AuthStorage.saveToken(token);
    await AuthStorage.saveUserId(user.id.toString());
    return (token: token, user: user);
  }

  Future<({String token, UserModel user})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required double monthlyIncome,
    String? phone,
  }) async {
    final data = await _api.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      monthlyIncome: monthlyIncome,
      phone: phone,
    );
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await AuthStorage.saveToken(token);
    await AuthStorage.saveUserId(user.id.toString());
    return (token: token, user: user);
  }

  Future<UserModel?> me() async {
    try {
      final data = await _api.me();
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await AuthStorage.clear();
      }
      // Connection error veya timeout → token varsa oturumu koru, yoksa null
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // best effort
    } finally {
      await AuthStorage.clear();
    }
  }

  static AuthRepository create() =>
      AuthRepository(DioClient.instance);
}
