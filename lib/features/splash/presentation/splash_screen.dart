import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), _navigateToLogin);
  }

  void _navigateToLogin() {
    GoRouter.of(context).go(AppRoutePath.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Center(
        child: Text(
          'AIG',
          style: AppTheme.lightTheme.textTheme.displayLarge,
        ),
      ),
    );
  }
}
