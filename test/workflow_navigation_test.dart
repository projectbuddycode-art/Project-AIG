import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aig/features/preset/presentation/preset_studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('dashboard bottom navigation routes to gallery', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutePath.dashboard,
      routes: [
        GoRoute(
          path: AppRoutePath.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutePath.gallery,
          builder: (context, state) => const _TestScreen(title: 'Gallery Route'),
        ),
        GoRoute(
          path: AppRoutePath.cameraStudio,
          builder: (context, state) => const _TestScreen(title: 'Camera Route'),
        ),
        GoRoute(
          path: AppRoutePath.presetStudio,
          builder: (context, state) => const _TestScreen(title: 'Preset Route'),
        ),
        GoRoute(
          path: AppRoutePath.settingsCenter,
          builder: (context, state) => const _TestScreen(title: 'Settings Route'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Gallery').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Gallery Route'), findsOneWidget);
  });

  testWidgets('preset apply action routes to camera studio', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutePath.presetStudio,
      routes: [
        GoRoute(
          path: AppRoutePath.presetStudio,
          builder: (context, state) => const PresetStudioScreen(),
        ),
        GoRoute(
          path: AppRoutePath.cameraStudio,
          builder: (context, state) => const _TestScreen(title: 'Camera Route'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Diamond Brilliance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Camera Route'), findsOneWidget);
  });
}

class _TestScreen extends StatelessWidget {
  const _TestScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}
