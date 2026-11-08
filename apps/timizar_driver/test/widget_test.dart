import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timizar_driver/src/features/shift/driver_home_screen.dart';

void main() {
  testWidgets('DriverHomeScreen renders LStop.c and service toggle button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DriverHomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LStop'), findsOneWidget);
    expect(find.text('.c'), findsOneWidget);
    expect(find.text('PASSER EN SERVICE'), findsOneWidget);
  });
}
