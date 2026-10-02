import 'package:aig/features/subscription/models/subscription_plan.dart';
import 'package:aig/features/subscription/models/subscription_usage.dart';
import 'package:aig/features/subscription/services/license_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LicenseValidator', () {
    test('allows exports on active plans with remaining quota', () {
      final plan = SubscriptionPlan(
        id: 'pro',
        name: 'Pro',
        status: SubscriptionStatus.active,
        type: SubscriptionType.monthly,
        monthlyExportLimit: 100,
        maxDevices: 2,
        maxStorageMb: 4096,
        maxResolution: SubscriptionResolution.hd,
      );
      final validator = LicenseValidator(plan: plan, usage: const SubscriptionUsage(exportsUsed: 10));

      final result = validator.canExport();
      expect(result.allowed, isTrue);
      expect(result.name, 'Export');
    });

    test('blocks exports when quota is exhausted', () {
      final plan = SubscriptionPlan(
        id: 'free',
        name: 'Free',
        status: SubscriptionStatus.active,
        type: SubscriptionType.free,
        monthlyExportLimit: 5,
      );
      final validator = LicenseValidator(plan: plan, usage: const SubscriptionUsage(exportsUsed: 5));

      final result = validator.canExport();
      expect(result.allowed, isFalse);
      expect(result.reason, contains('quota'));
    });

    test('supports unlimited plans and premium features', () {
      final plan = SubscriptionPlan(
        id: 'enterprise',
        name: 'Enterprise',
        status: SubscriptionStatus.active,
        type: SubscriptionType.enterprise,
        isUnlimitedExports: true,
        isEnterprise: true,
        maxDevices: 25,
        maxStorageMb: 20000,
        maxResolution: SubscriptionResolution.ultraHd,
      );
      final validator = LicenseValidator(plan: plan, usage: const SubscriptionUsage());

      final export = validator.canExport();
      final premium = validator.canUsePremiumFeatures();
      expect(export.allowed, isTrue);
      expect(premium.allowed, isTrue);
    });
  });
}
