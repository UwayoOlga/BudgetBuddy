import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetbuddy/main.dart';

void main() {
  testWidgets('App starts and shows expected widget', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the app shows the expected text or widget.
    expect(find.byType(MaterialApp), findsOneWidget);
    // You can add more specific tests here, for example:
    // expect(find.text('Expected Text'), findsOneWidget);
  });
}