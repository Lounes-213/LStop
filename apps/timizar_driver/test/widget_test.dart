import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timizar_driver/src/features/auth/driver_login_screen.dart';

void main() {
  testWidgets('DriverLoginScreen renders brand and Google button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DriverLoginScreen(),
        ),
      ),
    );

    expect(find.text('Timizar Chauffeur'), findsOneWidget);
    expect(find.text('Espace Chauffeur avec Google'), findsOneWidget);
  });
}
