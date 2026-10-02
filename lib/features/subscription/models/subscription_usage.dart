import 'package:flutter/foundation.dart';

@immutable
class SubscriptionUsage {
  const SubscriptionUsage({
    this.exportsUsed = 0,
    this.storageUsedMb = 0,
    this.aiCreditsUsed = 0,
    this.videoMinutesUsed = 0,
  });

  final int exportsUsed;
  final int storageUsedMb;
  final int aiCreditsUsed;
  final int videoMinutesUsed;

  SubscriptionUsage copyWith({
    int? exportsUsed,
    int? storageUsedMb,
    int? aiCreditsUsed,
    int? videoMinutesUsed,
  }) {
    return SubscriptionUsage(
      exportsUsed: exportsUsed ?? this.exportsUsed,
      storageUsedMb: storageUsedMb ?? this.storageUsedMb,
      aiCreditsUsed: aiCreditsUsed ?? this.aiCreditsUsed,
      videoMinutesUsed: videoMinutesUsed ?? this.videoMinutesUsed,
    );
  }
}
