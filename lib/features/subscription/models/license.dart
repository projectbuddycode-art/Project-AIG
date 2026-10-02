import 'package:flutter/foundation.dart';

import 'package:aig/features/subscription/models/subscription_plan.dart';

@immutable
class License {
  const License({
    required this.id,
    required this.plan,
    this.status = LicenseStatus.active,
    this.notes = const <String>[],
  });

  final String id;
  final SubscriptionPlan plan;
  final LicenseStatus status;
  final List<String> notes;
}

enum LicenseStatus {
  active,
  expired,
  suspended,
  revoked,
}
