import 'package:flutter/foundation.dart';

@immutable
class SubscriptionPermission {
  const SubscriptionPermission({
    required this.name,
    required this.allowed,
    this.reason,
    this.limit,
  });

  final String name;
  final bool allowed;
  final String? reason;
  final int? limit;
}
