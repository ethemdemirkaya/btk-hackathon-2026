import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/cache_storage.dart';
import '../../../shared/providers/dio_provider.dart';
import '../data/dashboard_api.dart';
import 'dashboard_models.dart';

class DashboardRepository {
  final DashboardApi _api;
  DashboardRepository(this._api);

  Future<DashboardData> getDashboard({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        CacheStorage.isFresh(CacheStorage.keyDashboard,
            maxAge: const Duration(minutes: 3))) {
      final cached =
          CacheStorage.get<Map<String, dynamic>>(CacheStorage.keyDashboard);
      if (cached != null) return DashboardData.fromJson(cached);
    }

    final data = await _api.getDashboard();
    await CacheStorage.put(CacheStorage.keyDashboard, data);
    return DashboardData.fromJson(data);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(DashboardApi(dio));
});

final dashboardProvider =
    FutureProvider.autoDispose<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboard();
});
