import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bk_mobile_app/main.dart';

void main() {
  testWidgets('App should build without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BKMobileApp(),
      ),
    );

    // Verify that the title BK Mobile is displayed somewhere (like AppBar or Welcome text)
    expect(find.text('BK Mobile'), findsWidgets);
  });
}
