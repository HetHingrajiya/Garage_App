import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autocare_pro/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AutoCareApp()));

    // Verify that our app starts.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
