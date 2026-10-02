import 'package:flutter/foundation.dart';

import 'package:aig/features/subscription/models/subscription_plan.dart';
import 'package:aig/features/subscription/models/subscription_usage.dart';

@immutable
class SubscriptionState {
  const SubscriptionState({
    required this.plan,
    required this.usage,
    this.licenseStatus = LicenseStatus.active,
    this.isInitialized = false,
  });

  final SubscriptionPlan plan;
  final SubscriptionUsage usage;
  final LicenseStatus licenseStatus;
  final bool isInitialized;
}

enum LicenseStatus {
  active,
  expired,
  suspended,
  revoked,
}
