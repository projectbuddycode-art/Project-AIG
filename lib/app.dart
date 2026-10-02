import 'dart:async';

import 'package:aig/core/config/app_config.dart';
import 'package:aig/core/providers/core_providers.dart';
import 'package:aig/core/theme/app_theme.dart';
import 'package:aig/core/services/app_lifecycle_service.dart';
import 'package:aig/features/esp32/providers/diamondcam_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLifecycleService _lifecycleService;

  @override
  void initState() {
    super.initState();
    debugPrint('[AIG_STARTUP] App mounted');
    debugPrint('[AIG_STARTUP] App initialization started');
    _lifecycleService = ref.read(appLifecycleServiceProvider);
    WidgetsBinding.instance.addObserver(_lifecycleService);
    // Register lifecycle callback to attempt reconnect on resume.
    _lifecycleService.registerCallback((state) async {
      if (state == AppLifecycleState.resumed) {
        try {
          await ref.read(diamondCamStateProvider.notifier).refreshStatus();
        } catch (e) {
          debugPrint('Reconnect on resume failed: $e');
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(diamondCamStateProvider.notifier).refreshStatus());
    });
    // Perform initial machine status check at app startup (non-blocking).
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleService);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: AppConfig.name,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) =>
          child ?? const SizedBox.shrink(),
    );
  }
}
