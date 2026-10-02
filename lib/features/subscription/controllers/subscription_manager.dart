import 'package:aig/features/subscription/models/license.dart';
import 'package:aig/features/subscription/models/subscription_plan.dart';
import 'package:aig/features/subscription/models/subscription_state.dart';
import 'package:aig/features/subscription/models/subscription_usage.dart';

class SubscriptionManager {
  const SubscriptionManager();

  SubscriptionStateModel createDefaultState() {
    return const SubscriptionStateModel(
      plan: SubscriptionPlan(
        id: 'free',
        name: 'Free',
        status: SubscriptionStatus.active,
        type: SubscriptionType.free,
        monthlyExportLimit: 5,
        maxDevices: 1,
        maxStorageMb: 1024,
        maxResolution: SubscriptionResolution.standard,
      ),
      usage: SubscriptionUsage(),
      license: License(id: 'default', plan: SubscriptionPlan(
        id: 'free',
        name: 'Free',
        status: SubscriptionStatus.active,
        type: SubscriptionType.free,
        monthlyExportLimit: 5,
        maxDevices: 1,
        maxStorageMb: 1024,
        maxResolution: SubscriptionResolution.standard,
      )),
      isInitialized: true,
    );
  }

  SubscriptionStateModel updateUsage(SubscriptionStateModel state, SubscriptionUsage usage) {
    return SubscriptionStateModel(
      plan: state.plan,
      usage: usage,
      license: state.license,
      isInitialized: state.isInitialized,
    );
  }
}
