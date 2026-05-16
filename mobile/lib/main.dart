import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/api/api_endpoints.dart';
import 'core/routes/app_router.dart';
import 'core/storage/auth_storage.dart';
import 'core/storage/cache_storage.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);
  await CacheStorage.init();

  // Apply any saved API host override (set from the login debug chip).
  final savedHost = await AuthStorage.getApiHost();
  if (savedHost != null && savedHost.isNotEmpty) {
    ApiEndpoints.setHost(savedHost);
  }

  runApp(const ProviderScope(child: ParanetteApp()));
}

class ParanetteApp extends ConsumerWidget {
  const ParanetteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Paranette',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}
