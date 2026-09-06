import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/features/guru/input_setoran_screen.dart';

void main() {
  testWidgets('InputSetoranScreen - validates ayat field and auto clamps to max',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: InputSetoranScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of InputSetoranScreen elements
    expect(find.text('Input Setoran Hafalan'), findsOneWidget);
    expect(find.text('AYAT MULAI'), findsOneWidget);
    expect(find.text('AYAT SELESAI'), findsOneWidget);

    // Find the Ayat Selesai TextFormField (index 4 among all TextFormFields, since 0,1,2 are read-only pickers)
    final textFieldsWithController = find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.controller != null,
    );
    expect(textFieldsWithController, findsAtLeastNWidgets(2));

    // textFieldsWithController at index 0 is Ayat Mulai, index 1 is Ayat Selesai
    final ayatSelesaiField = textFieldsWithController.at(1);

    // Enter an out-of-range value (e.g. 500)
    await tester.enterText(ayatSelesaiField, '500');
    await tester.pump();

    // Verify it automatically clamped to the max limit (286 default fallback or surah's max)
    final textFormField = tester.widget<TextFormField>(ayatSelesaiField);
    expect(int.parse(textFormField.controller!.text) <= 286, isTrue);
  });
}
