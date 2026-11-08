import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timizar_app/src/features/home/home_screen.dart';
import 'package:timizar_app/src/features/splash/lstop_emblem.dart';

void main() {
  testWidgets('HomeScreen renders LStop emblem button, position button, line filters and driver profiles',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Verifies circular emblem logo button exists
    expect(find.byType(LStopEmblem), findsOneWidget);

    // 2. Verifies circular position button with blue navigation arrow exists
    expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);

    // 3. Verifies bottom sheet search input field exists
    expect(find.byType(TextField), findsOneWidget);

    // 4. Verifies line filter chips exist
    expect(find.text('Toutes les lignes'), findsOneWidget);
    expect(find.text('Ligne 01'), findsOneWidget);

    // 5. Verifies driver profile presence
    expect(find.text('Karim Ait O.'), findsOneWidget);
  });
}
