import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/subscription/providers/subscription_providers.dart';

class DevSubscriptionScreen extends ConsumerWidget {
  const DevSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(subscriptionStateNotifierProvider);
    final state = notifier.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Subscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: ${state.plan.name}'),
            Text('Status: ${state.plan.status.name}'),
            Text('Exports used: ${state.usage.exportsUsed}'),
            Text('Storage used: ${state.usage.storageUsedMb} MB'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: notifier.initialize,
              child: const Text('Initialize'),
            ),
          ],
        ),
      ),
    );
  }
}
