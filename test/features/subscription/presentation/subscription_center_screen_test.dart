import 'package:aig/features/subscription/presentation/subscription_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders subscription center overview', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SubscriptionCenterScreen()),
      ),
    );

    expect(find.text('Subscription Center'), findsOneWidget);
    expect(find.textContaining('Free'), findsWidgets);
    expect(find.text('Usage Snapshot'), findsOneWidget);
  });
}
