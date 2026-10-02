import 'package:flutter/foundation.dart';

import 'package:aig/features/subscription/controllers/subscription_controller.dart';
import 'package:aig/features/subscription/models/subscription_plan.dart';
import 'package:aig/features/subscription/models/subscription_state.dart';
import 'package:aig/features/subscription/models/subscription_usage.dart';

class SubscriptionStateNotifier extends ChangeNotifier {
  SubscriptionStateNotifier({SubscriptionController? controller})
      : _controller = controller ?? SubscriptionController(),
        _state = SubscriptionStateModel(
          plan: const SubscriptionPlan(
            id: 'free',
            name: 'Free',
            status: SubscriptionStatus.active,
            type: SubscriptionType.free,
            monthlyExportLimit: 5,
            maxDevices: 1,
            maxStorageMb: 1024,
            maxResolution: SubscriptionResolution.standard,
          ),
          usage: const SubscriptionUsage(),
        );

  final SubscriptionController _controller;
  SubscriptionStateModel _state;

  SubscriptionStateModel get state => _state;

  void initialize() {
    _state = _controller.getInitialState();
    notifyListeners();
  }

  void updateUsage(SubscriptionUsage usage) {
    _state = _controller.updateUsage(_state, usage);
    notifyListeners();
  }
}
