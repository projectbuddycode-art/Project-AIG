import 'package:flutter/foundation.dart';

@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    this.monthlyExportLimit,
    this.isUnlimitedExports = false,
    this.isTrial = false,
    this.isEnterprise = false,
    this.maxDevices = 1,
    this.maxStorageMb = 1024,
    this.maxResolution = SubscriptionResolution.standard,
    this.maxVideoMinutes = 60,
    this.isSuspended = false,
    this.expiresAt,
  });

  final String id;
  final String name;
  final SubscriptionStatus status;
  final SubscriptionType type;
  final int? monthlyExportLimit;
  final bool isUnlimitedExports;
  final bool isTrial;
  final bool isEnterprise;
  final int maxDevices;
  final int maxStorageMb;
  final SubscriptionResolution maxResolution;
  final int maxVideoMinutes;
  final bool isSuspended;
  final DateTime? expiresAt;

  bool get isActive => status == SubscriptionStatus.active;
  bool get hasExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

enum SubscriptionStatus {
  active,
  trial,
  expired,
  suspended,
  cancelled,
}

enum SubscriptionType {
  free,
  monthly,
  annual,
  enterprise,
  trial,
}

enum SubscriptionResolution {
  standard,
  hd,
  ultraHd,
}
