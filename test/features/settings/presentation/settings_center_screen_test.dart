import 'package:aig/features/settings/presentation/settings_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders settings center sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsCenterScreen()),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
  });
}
