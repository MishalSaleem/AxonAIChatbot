// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:axon/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Bouw onze app en trigger een frame.
    await tester.pumpWidget(const App());

    // Verifieer dat onze teller op 0 begint.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tik op het '+' pictogram en trigger een frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifieer dat onze teller is opgehoogd.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
