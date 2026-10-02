import 'package:flutter/foundation.dart';

import 'package:aig/features/subscription/models/subscription_plan.dart';

@immutable
class SubscriptionLimits {
  const SubscriptionLimits({
    this.maxExports = 100,
    this.maxStorageMb = 1024,
    this.maxDevices = 1,
    this.maxVideoMinutes = 60,
    this.maxResolution = SubscriptionResolution.standard,
    this.allowsAiProcessing = false,
    this.allowsCloudStorage = false,
    this.allowsPremiumFeatures = false,
    this.isUnlimitedExports = false,
  });

  final int maxExports;
  final int maxStorageMb;
  final int maxDevices;
  final int maxVideoMinutes;
  final SubscriptionResolution maxResolution;
  final bool allowsAiProcessing;
  final bool allowsCloudStorage;
  final bool allowsPremiumFeatures;
  final bool isUnlimitedExports;
}
