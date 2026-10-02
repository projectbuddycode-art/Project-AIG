import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/subscription/controllers/subscription_controller.dart';
import 'package:aig/features/subscription/controllers/subscription_state_notifier.dart';
import 'package:aig/features/subscription/controllers/subscription_manager.dart';

final subscriptionManagerProvider = Provider<SubscriptionManager>((ref) {
  return const SubscriptionManager();
});

final subscriptionControllerProvider = Provider<SubscriptionController>((ref) {
  return SubscriptionController(manager: ref.read(subscriptionManagerProvider));
});

final subscriptionStateNotifierProvider = Provider<SubscriptionStateNotifier>((ref) {
  return SubscriptionStateNotifier(controller: ref.read(subscriptionControllerProvider));
});
