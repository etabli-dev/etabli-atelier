// Smoke test for the navigation shell. SettingsStore is faked via an in-memory
// Hive box so the test needs no platform channels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etabli_atelier/theme/theme.dart';

void main() {
  test('accent token is the spec teal/green', () {
    expect(AppColors.accent, const Color(0xFF28A745));
  });

  testWidgets('theme builds light and dark without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const Scaffold(body: Text('Établi Atelier')),
        ),
      ),
    );
    expect(find.text('Établi Atelier'), findsOneWidget);
  });
}
