import 'package:flutter/material.dart';

abstract class AppRoutePath {
  const AppRoutePath._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String deviceConnection = '/device-connection';
  static const String machineCenter = '/machine-center';
  static const String settingsCenter = '/settings-center';
  static const String exportMonitor = '/export-monitor';
  static const String subscriptionMonitor = '/subscription-monitor';
  static const String subscriptionCenter = '/subscription-center';
  static const String cameraStudio = '/studio';
  static const String presetStudio = '/presets';
  static const String gallery = '/gallery';
  static const String export = '/export';
  static const String forgotPassword = '/forgot-password';

  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String dashboardName = 'dashboard';
  static const String deviceConnectionName = 'deviceConnection';
  static const String machineCenterName = 'machineCenter';
  static const String settingsCenterName = 'settingsCenter';
  static const String exportMonitorName = 'exportMonitor';
  static const String subscriptionMonitorName = 'subscriptionMonitor';
  static const String subscriptionCenterName = 'subscriptionCenter';
  static const String cameraStudioName = 'cameraStudio';
  static const String presetStudioName = 'presetStudio';
  static const String galleryName = 'gallery';
  static const String exportName = 'export';
  static const String forgotPasswordName = 'forgotPassword';
}

abstract class AppConstants {
  const AppConstants._();

  static const Duration animationDuration = Duration(milliseconds: 250);
  static const double cornerRadius = 16.0;

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
}
