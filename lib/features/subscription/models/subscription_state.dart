import 'package:flutter/foundation.dart';

import 'package:aig/features/subscription/models/license.dart';
import 'package:aig/features/subscription/models/subscription_plan.dart';
import 'package:aig/features/subscription/models/subscription_usage.dart';

@immutable
class SubscriptionStateModel {
  const SubscriptionStateModel({
    required this.plan,
    required this.usage,
    this.license = const License(id: 'default', plan: SubscriptionPlan(
      id: 'free',
      name: 'Free',
      status: SubscriptionStatus.active,
      type: SubscriptionType.free,
    )),
    this.isInitialized = false,
  });

  final SubscriptionPlan plan;
  final SubscriptionUsage usage;
  final License license;
  final bool isInitialized;
}
