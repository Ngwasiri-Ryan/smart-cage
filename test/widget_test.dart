import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_cage/main.dart';
import 'package:smart_cage/models/app_state.dart';

void main() {
  testWidgets('SmartCage app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const SmartCageApp(),
      ),
    );

    // Verify MaterialApp builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
