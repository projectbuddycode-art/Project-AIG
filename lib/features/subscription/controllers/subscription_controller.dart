import 'package:aig/features/subscription/controllers/subscription_manager.dart';
import 'package:aig/features/subscription/models/subscription_state.dart';
import 'package:aig/features/subscription/models/subscription_usage.dart';

class SubscriptionController {
  SubscriptionController({SubscriptionManager? manager}) : _manager = manager ?? const SubscriptionManager();

  final SubscriptionManager _manager;

  SubscriptionStateModel getInitialState() {
    return _manager.createDefaultState();
  }

  SubscriptionStateModel updateUsage(SubscriptionStateModel state, SubscriptionUsage usage) {
    return _manager.updateUsage(state, usage);
  }
}
