import 'package:aig/features/subscription/models/subscription_permission.dart';
import 'package:aig/features/subscription/models/subscription_plan.dart';
import 'package:aig/features/subscription/models/subscription_usage.dart';

class LicenseValidator {
  LicenseValidator({required this.plan, required this.usage});

  final SubscriptionPlan plan;
  final SubscriptionUsage usage;

  SubscriptionPermission canExport() {
    if (!isPlanActive) {
      return const SubscriptionPermission(name: 'Export', allowed: false, reason: 'subscription inactive');
    }

    if (plan.isUnlimitedExports) {
      return const SubscriptionPermission(name: 'Export', allowed: true, limit: -1);
    }

    final limit = plan.monthlyExportLimit ?? 0;
    final remaining = limit - usage.exportsUsed;
    if (remaining <= 0) {
      return SubscriptionPermission(name: 'Export', allowed: false, reason: 'export quota exhausted', limit: 0);
    }

    return SubscriptionPermission(name: 'Export', allowed: true, limit: remaining);
  }

  SubscriptionPermission canProcess() {
    if (!isPlanActive) {
      return const SubscriptionPermission(name: 'AI Processing', allowed: false, reason: 'subscription inactive');
    }
    return const SubscriptionPermission(name: 'AI Processing', allowed: true, limit: -1);
  }

  SubscriptionPermission canUpload() {
    if (!isPlanActive) {
      return const SubscriptionPermission(name: 'Cloud Storage', allowed: false, reason: 'subscription inactive');
    }
    return const SubscriptionPermission(name: 'Cloud Storage', allowed: true, limit: -1);
  }

  SubscriptionPermission canCapture() {
    if (plan.isSuspended || plan.hasExpired) {
      return const SubscriptionPermission(name: 'Capture', allowed: false, reason: 'subscription not available');
    }
    return const SubscriptionPermission(name: 'Capture', allowed: true, limit: -1);
  }

  SubscriptionPermission canUsePremiumFeatures() {
    if (!isPlanActive || plan.isSuspended || plan.hasExpired) {
      return const SubscriptionPermission(name: 'Premium Features', allowed: false, reason: 'premium access unavailable');
    }

    if (plan.isEnterprise || plan.type == SubscriptionType.enterprise) {
      return const SubscriptionPermission(name: 'Premium Features', allowed: true, limit: -1);
    }

    return const SubscriptionPermission(name: 'Premium Features', allowed: false, reason: 'premium features not included');
  }

  bool get isPlanActive {
    if (plan.isSuspended) {
      return false;
    }
    if (plan.hasExpired) {
      return false;
    }
    return plan.status == SubscriptionStatus.active || plan.status == SubscriptionStatus.trial;
  }
}
