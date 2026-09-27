import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonia_mvp/presentation/screens/store_mirror_screen.dart';

void main() {
  testWidgets('StoreMirrorScreen renders HUD, store chips, and shutter button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: StoreMirrorScreen(),
      ),
    );

    // Verify header text
    expect(find.text('MIRROR MODE • PROVADOR'), findsOneWidget);
    expect(find.text('Lojas Renner'), findsOneWidget);
    expect(find.text('C&A'), findsOneWidget);

    // Verify shutter button key
    final shutter = find.byKey(const Key('shutter_button'));
    expect(shutter, findsOneWidget);

    // Tap shutter button
    await tester.tap(shutter, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
  });
}
