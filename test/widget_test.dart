import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murabbi_mobile/main.dart';

void main() {
  testWidgets(
    'MurabbiApp smoke test - verifies welcome screen and login navigation',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MurabbiApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('MURABBI'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);
    },
  );
}
