import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheStorage {
  static const _boxName = 'paranette_cache';
  static Box? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Box get _b {
    assert(_box != null, 'CacheStorage.init() must be called first');
    return _box!;
  }

  static Future<void> put(String key, dynamic value) async {
    if (value == null) return;
    if (value is Map || value is List) {
      await _b.put(key, jsonEncode(value));
    } else {
      await _b.put(key, value);
    }
    await _b.put('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  static T? get<T>(String key) {
    final raw = _b.get(key);
    if (raw == null) return null;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded as T?;
      } catch (_) {
        return raw as T?;
      }
    }
    return raw as T?;
  }

  static bool isFresh(String key, {Duration maxAge = const Duration(minutes: 5)}) {
    final ts = _b.get('${key}_ts') as int?;
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < maxAge.inMilliseconds;
  }

  static Future<void> remove(String key) => _b.delete(key);

  static Future<void> clear() => _b.clear();

  // Cache keys
  static const keyDashboard = 'dashboard';
  static const keyTransactions = 'transactions';
  static const keyBankConnections = 'bank_connections';
  static const keyCards = 'cards';
  static const keyLoans = 'loans';
  static const keyBills = 'bills';
  static const keySubscriptions = 'subscriptions';
  static const keyGoals = 'goals';
  static const keyInvestments = 'investments';
  static const keyFxAlerts = 'fx_alerts';
}
